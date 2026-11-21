/// La forma canónica del JSON (RFC 8785, JCS): un solo texto posible para cada valor.
///
/// Es la misma que escribe el backend (`interp.events.canonical`). La huella de un evento es el SHA-256 de este texto,
/// así que el cliente y el servidor tienen que producir exactamente los mismos bytes:
///
/// - objetos con las claves ordenadas por unidades de código UTF-16, sin espacios;
/// - textos escapados solo donde JSON obliga, sin escapar los acentos;
/// - números como los escribe JavaScript: la representación más corta que se lee igual, en decimal entre 1e-6 y 1e21 y
///   en notación exponencial fuera de ese rango;
/// - NaN e infinito no tienen forma canónica y se rechazan.
String canonico(Object? valor) {
  final salida = StringBuffer();
  _escribir(valor, salida);
  return salida.toString();
}

void _escribir(Object? valor, StringBuffer salida) {
  if (valor == null) {
    salida.write('null');
  } else if (valor is bool) {
    salida.write(valor ? 'true' : 'false');
  } else if (valor is int) {
    salida.write(valor.toString());
  } else if (valor is double) {
    salida.write(_numero(valor));
  } else if (valor is String) {
    _texto(valor, salida);
  } else if (valor is Map) {
    final claves = <String>[];
    for (final clave in valor.keys) {
      if (clave is! String) {
        throw ArgumentError.value(clave, 'clave', 'las claves de un objeto JSON deben ser textos');
      }
      claves.add(clave);
    }
    claves.sort(_compararUtf16);
    salida.write('{');
    for (var i = 0; i < claves.length; i++) {
      if (i > 0) salida.write(',');
      _texto(claves[i], salida);
      salida.write(':');
      _escribir(valor[claves[i]], salida);
    }
    salida.write('}');
  } else if (valor is List) {
    salida.write('[');
    for (var i = 0; i < valor.length; i++) {
      if (i > 0) salida.write(',');
      _escribir(valor[i], salida);
    }
    salida.write(']');
  } else {
    throw ArgumentError.value(valor, 'valor', 'no es un valor JSON');
  }
}

/// Compara por unidades de código UTF-16, como el orden de RFC 8785.
int _compararUtf16(String a, String b) {
  final comun = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < comun; i++) {
    final diferencia = a.codeUnitAt(i) - b.codeUnitAt(i);
    if (diferencia != 0) return diferencia;
  }
  return a.length - b.length;
}

const Map<int, String> _escapes = {
  0x22: r'\"',
  0x5c: r'\\',
  0x08: r'\b',
  0x0c: r'\f',
  0x0a: r'\n',
  0x0d: r'\r',
  0x09: r'\t',
};

void _texto(String texto, StringBuffer salida) {
  salida.write('"');
  for (final unidad in texto.codeUnits) {
    final escape = _escapes[unidad];
    if (escape != null) {
      salida.write(escape);
    } else if (unidad < 0x20) {
      salida.write('\\u${unidad.toRadixString(16).padLeft(4, '0')}');
    } else {
      salida.writeCharCode(unidad);
    }
  }
  salida.write('"');
}

/// Un número como lo escribe JavaScript (`Number.prototype.toString`).
///
/// `toString` de Dart da la representación más corta que se lee igual, con o sin notación exponencial. De ella se
/// toman los dígitos significativos y la posición del punto decimal, y de ahí se escribe la forma de JavaScript.
String _numero(double valor) {
  if (valor.isNaN || valor.isInfinite) {
    throw ArgumentError.value(valor, 'valor', 'no tiene forma canónica en JSON');
  }
  if (valor == 0) return '0';

  final signo = valor < 0 ? '-' : '';
  var texto = valor.abs().toString();
  var exponente = 0;
  final e = texto.indexOf('e');
  if (e >= 0) {
    var textoExponente = texto.substring(e + 1);
    if (textoExponente.startsWith('+')) textoExponente = textoExponente.substring(1);
    exponente = int.parse(textoExponente);
    texto = texto.substring(0, e);
  }
  final punto = texto.indexOf('.');
  final enteros = punto < 0 ? texto : texto.substring(0, punto);
  final decimales = punto < 0 ? '' : texto.substring(punto + 1);

  // El valor es 0.<digitos> × 10^n.
  var digitos = enteros + decimales;
  var n = enteros.length + exponente;
  var inicio = 0;
  while (inicio < digitos.length - 1 && digitos[inicio] == '0') {
    inicio++;
    n--;
  }
  digitos = digitos.substring(inicio).replaceFirst(RegExp(r'0+$'), '');
  final k = digitos.length;

  if (k <= n && n <= 21) return signo + digitos + '0' * (n - k);
  if (0 < n && n <= 21) return '$signo${digitos.substring(0, n)}.${digitos.substring(n)}';
  if (-6 < n && n <= 0) return '${signo}0.${'0' * -n}$digitos';

  final exp = n - 1;
  final mantisa = k == 1 ? digitos : '${digitos[0]}.${digitos.substring(1)}';
  return '$signo${mantisa}e${exp < 0 ? '-' : '+'}${exp.abs()}';
}
