import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  static Future<void> exportMedicines(List<Medicine> medicines) async {
    final pdf = pw.Document();

    final now = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(DateTime.now());
    
    final total = medicines.length;
    final good = medicines.where((m) => m.expiryDate.difference(DateTime.now()).inDays > 3).length;
    final warning = medicines.where((m) {
      final days = m.expiryDate.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 3;
    }).length;
    final expired = medicines.where((m) => m.expiryDate.isBefore(DateTime.now())).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('🏥 Домашняя аптечка', 
                style: pw.TextStyle(
                  fontSize: 28, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Отчёт сформирован: $now', 
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.Divider(),
            pw.SizedBox(height: 10),

            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green700, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('📊 Статистика аптечки', 
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  _buildStatRow('Всего лекарств', total, PdfColors.blue),
                  _buildStatRow('В норме', good, PdfColors.green700),
                  _buildStatRow('Истекают скоро', warning, PdfColors.orange),
                  _buildStatRow('Просрочено', expired, PdfColors.red),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            pw.Text('💊 Список лекарств', 
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            
            // ✅ ЗАГОЛОВОК ТАБЛИЦЫ
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.green50),
                  children: [
                    _buildTableCell('Название', bold: true, color: PdfColors.green700),
                    _buildTableCell('Описание', bold: true, color: PdfColors.green700),
                    _buildTableCell('Срок', bold: true, color: PdfColors.green700),
                    _buildTableCell('Статус', bold: true, color: PdfColors.green700),
                  ],
                ),
                // ✅ ДАННЫЕ ТАБЛИЦЫ
                ...medicines.map((med) {
                  final daysLeft = med.expiryDate.difference(DateTime.now()).inDays;
                  final status = daysLeft < 0 ? '❌ Просрочено' 
                            : daysLeft <= 3 ? '⚠️ Истекает' 
                            : '✅ В норме';
                  
                  final statusColor = daysLeft < 0 ? PdfColors.red 
                                  : daysLeft <= 3 ? PdfColors.orange 
                                  : PdfColors.green700;
                  
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: daysLeft < 0 ? PdfColors.red50 
                              : daysLeft <= 3 ? PdfColors.orange50 
                              : PdfColors.white,
                    ),
                    children: [
                      _buildTableCell(med.name, bold: true),
                      _buildTableCell(med.description ?? '-'),
                      _buildTableCell(DateFormat('dd.MM.yyyy').format(med.expiryDate)),
                      _buildTableCell(status, color: statusColor),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            pw.Center(
              child: pw.Text(
                'Сформировано приложением "Моя Аптечка"',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'aptečka_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)], 
      subject: 'Моя Аптечка - Отчёт',
      text: 'Отчёт по домашней аптечке от $now',
    );
  }

  // ✅ ИСПРАВЛЕНО: возвращает pw.Widget, а не pw.TableCell
  static pw.Widget _buildStatRow(String label, int value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 14)),
          pw.Text(
            value.toString(), 
            style: pw.TextStyle(
              fontSize: 16, 
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ИСПРАВЛЕНО: возвращает pw.Widget, а не pw.TableCell
  static pw.Widget _buildTableCell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}