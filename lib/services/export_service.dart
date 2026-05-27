import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../models/user_profile.dart';
import '../utils/date_utils.dart';

class ExportService {
  ExportService._();

  static Future<void> exportCsv(
    List<PrayerRecord> records,
    UserProfile? profile, {
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = <List<dynamic>>[
      ['Date', ...Prayer.all.map((p) => p.name), 'Total'],
      for (final r in records)
        [
          DateX.ymd(r.date),
          ...Prayer.all.map((p) => r.isCompleted(p) ? 'Yes' : 'No'),
          '${r.completedCount}/5',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final fname =
        'namaz-${profile?.mobile ?? "report"}-${DateX.ymd(from)}-to-${DateX.ymd(to)}.csv';
    final file = File(p.join(dir.path, fname));
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'My Namaz Report');
  }

  static Future<void> exportPdf(
    List<PrayerRecord> records,
    UserProfile? profile, {
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('My Namaz — Prayer Report',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          if (profile != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                  'For: ${profile.name}  •  ${profile.fullPhone}',
                  style: const pw.TextStyle(fontSize: 12)),
            ),
          pw.Text(
              'Range: ${DateX.pretty(from)} → ${DateX.pretty(to)}',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', ...Prayer.all.map((p) => p.name), 'Total'],
            data: [
              for (final r in records)
                [
                  DateX.ymd(r.date),
                  ...Prayer.all
                      .map((p) => r.isCompleted(p) ? '✓' : '✗'),
                  '${r.completedCount}/5',
                ],
            ],
            cellAlignment: pw.Alignment.center,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final fname =
        'namaz-${profile?.mobile ?? "report"}-${DateX.ymd(from)}-to-${DateX.ymd(to)}.pdf';
    final file = File(p.join(dir.path, fname));
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)],
        subject: 'My Namaz Report');
  }
}
