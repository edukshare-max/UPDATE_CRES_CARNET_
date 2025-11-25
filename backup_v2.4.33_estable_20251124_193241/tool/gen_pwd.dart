// tool/gen_pwd.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Uso: dart run tool/gen_pwd.dart "TuContraseñaSegura" [iteraciones]');
    exit(64);
  }
  final password = args[0];
  final iterations = (args.length > 1) ? int.parse(args[1]) : 150000;

  final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  final algo = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
  final key = await algo.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  final bytes = await key.extractBytes();

  final jsonMap = {
    'salt': base64Encode(salt),
    'hash': base64Encode(bytes),
    'iters': iterations,
    'kdf': 'pbkdf2-hmac-sha256-256bit'
  };
  final out = const JsonEncoder.withIndent('  ').convert(jsonMap);
  print(out);
}
