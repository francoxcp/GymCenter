import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/shared/services/data_export_service.dart';

String hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('Cifrado de la exportación de datos', () {
    test('PBKDF2-HMAC-SHA256 coincide con el vector de prueba conocido', () {
      final dk = DataExportService.pbkdf2(
          utf8.encode('password'), utf8.encode('salt'), 1, 32);
      expect(hex(dk),
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    });

    test('cifra y descifra (ida y vuelta)', () {
      const json = '{"hola":"mundo","n":42}';
      final data =
          DataExportService.encryptJson(json, 'Secreta123!', iterations: 10);
      expect(String.fromCharCodes(data.sublist(0, 4)), 'GCX2');
      expect(
          DataExportService.decryptJson(data, 'Secreta123!', iterations: 10),
          json);
    });

    test('contraseña incorrecta o archivo alterado → error', () {
      final data =
          DataExportService.encryptJson('{"a":1}', 'Secreta123!', iterations: 10);
      expect(
          () => DataExportService.decryptJson(data, 'otra', iterations: 10),
          throwsFormatException);
      final tampered = Uint8List.fromList(data)..[40] ^= 0x01;
      expect(
          () => DataExportService.decryptJson(tampered, 'Secreta123!',
              iterations: 10),
          throwsFormatException);
    });
  });
}
