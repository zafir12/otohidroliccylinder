import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hydraulic_cylinder.dart';
import '../models/mounting_type.dart';

class PdfGeneratorService {
  const PdfGeneratorService._();

  static Future<Uint8List> generateTechnicalSheet({
    required HydraulicCylinder cylinder,
    required MountingType frontMounting,
    required MountingType rearMounting,
    String projectName = 'Hidrolik Silindir Tasarım Föyü',
    String revision = 'A',
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    final pushForce = cylinder.calculatePushForce();
    final pullForce = cylinder.calculatePullForce();
    final totalWeight = cylinder.calculateTotalWeight();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Antet
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 72,
                    height: 42,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey700),
                    ),
                    child: pw.Text('LOGO', style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TEKNİK FÖY - HİDROLİK SİLİNDİR',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(projectName),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey600),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Tarih: ${now.day}.${now.month}.${now.year}'),
                        pw.Text('Revizyon: $revision'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Tablo 1: Teknik Veriler
              pw.Text('1) Teknik Veriler', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600),
                children: [
                  _row(['Parametre', 'Değer']),
                  _row(['Basınç', '${(cylinder.pressure * 10).toStringAsFixed(1)} bar']),
                  _row(['Boru İç Çapı', '${cylinder.boreDiameter.toStringAsFixed(1)} mm']),
                  _row(['Rod Çapı', '${cylinder.rodDiameter.toStringAsFixed(1)} mm']),
                  _row(['Strok', '${cylinder.stroke.toStringAsFixed(1)} mm']),
                  _row(['İtme Kuvveti', '${pushForce.toStringAsFixed(0)} N']),
                  _row(['Çekme Kuvveti', '${pullForce.toStringAsFixed(0)} N']),
                  _row(['Toplam Ağırlık', '${totalWeight.toStringAsFixed(2)} kg']),
                  _row(['Ön Montaj', frontMounting.description]),
                  _row(['Arka Montaj', rearMounting.description]),
                ],
              ),
              pw.SizedBox(height: 14),

              // Tablo 2: BOM
              pw.Text('2) Parça Listesi (BOM)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  _row(['Parça', 'Ölçü/Boyut', 'Malzeme']),
                  _row([
                    'Boru',
                    'Ø${cylinder.boreDiameter.toStringAsFixed(0)} - Boy: ${cylinder.stroke.toStringAsFixed(0)} mm',
                    'St52',
                  ]),
                  _row([
                    'Mil',
                    'Ø${cylinder.rodDiameter.toStringAsFixed(0)} - Boy: ${(cylinder.stroke + cylinder.head.totalLength).toStringAsFixed(0)} mm',
                    'CK45 Kromlu',
                  ]),
                  _row([
                    'Piston',
                    'Kalınlık: ${cylinder.piston.width.toStringAsFixed(1)} mm',
                    cylinder.piston.material,
                  ]),
                  _row([
                    'Kep/Gland',
                    'Boy: ${cylinder.head.totalLength.toStringAsFixed(1)} mm',
                    cylinder.head.material,
                  ]),
                  _row([
                    'Arka Kapak',
                    'Et: ${cylinder.base.thickness.toStringAsFixed(1)} mm',
                    'St52',
                  ]),
                  _row(['Sızdırmazlık', 'Kastaş K21 / Nutring / O-Ring', 'NBR/PU']),
                ],
              ),
              pw.SizedBox(height: 14),

              // Şematik görsel
              pw.Text('3) Şematik Görünüm', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 140,
                width: double.infinity,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600)),
                child: pw.CustomPaint(
                  painter: (pw.Context ctx, pw.Canvas canvas, PdfPoint size) {
                    final y = size.y / 2;
                    final left = 20.0;
                    final right = size.x - 20.0;

                    final bodyStart = left + 28;
                    final bodyEnd = right - 48;
                    final bodyH = 42.0;
                    final rodH = 16.0;

                    canvas
                      ..setStrokeColor(PdfColors.black)
                      ..setLineWidth(1.2)
                      ..drawRect(bodyStart, y - bodyH / 2, bodyEnd - bodyStart, bodyH)
                      ..drawRect(left, y - bodyH / 2, 28, bodyH)
                      ..drawRect(bodyEnd, y - bodyH / 2, 26, bodyH)
                      ..drawRect(bodyEnd, y - rodH / 2, right - bodyEnd, rodH);

                    final pistonX = bodyStart + (bodyEnd - bodyStart) * 0.55;
                    canvas.drawRect(pistonX, y - bodyH * 0.40, 12, bodyH * 0.80);
                  },
                ),
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Bu belge Otonom Hidrolik Tasarımcı ile oluşturulmuştur.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.TableRow _row(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map(
            (e) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(e, style: const pw.TextStyle(fontSize: 10)),
            ),
          )
          .toList(),
    );
  }

  static Future<File> savePdfToDocuments({
    required Uint8List bytes,
    String fileName = 'hydraulic_cylinder_report.pdf',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> sharePdf({
    required Uint8List bytes,
    String fileName = 'hydraulic_cylinder_report.pdf',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Hidrolik Silindir Teknik Föyü',
      text: 'Teknik rapor ektedir.',
    );
  }

  static Future<void> printOrPreview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
