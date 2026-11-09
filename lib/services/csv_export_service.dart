import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/collection_item.dart';
import '../models/export_field_config.dart';

class CsvExportService {
  /**
   * Generates a CSV string, saves it to the device storage,
   * and opens the native OS Share Sheet via share_plus.
   */
  static Future<File> exportAndShareCollection({
    required List<UserCardItem> items,
    required List<ExportFieldDefinition> dynamicFields,
    required Map<String, dynamic> surveyAnswers,
  }) async {
    // 1. Build Header Row: Standard Columns + Dynamic Popup Survey Columns
    final List<String> standardHeaders = [
      'Collection ID',
      'Card Name',
      'Set Code',
      'Set Name',
      'Collector Number',
      'Rarity',
      'Condition',
      'Grade',
      'Language',
      'Quantity',
      'Acquired Date',
    ];

    final List<String> dynamicHeaders = dynamicFields.map((f) => f.label).toList();
    final List<dynamic> fullHeaders = [...standardHeaders, ...dynamicHeaders];

    final List<List<dynamic>> csvRows = [fullHeaders];
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    // 2. Build Data Rows
    for (final item in items) {
      final List<dynamic> row = [
        item.id,
        item.cardName,
        item.setCode,
        item.setName,
        item.collectorNumber,
        item.rarity ?? 'Unknown',
        item.condition,
        item.grade,
        item.language,
        item.quantity,
        dateFormatter.format(item.acquiredDate),
      ];

      // Append dynamic fields: Checks runtime survey answers first, then item customFields
      for (final field in dynamicFields) {
        dynamic val = '';
        if (surveyAnswers.containsKey(field.key)) {
          val = surveyAnswers[field.key];
        } else if (item.customFields.containsKey(field.key)) {
          val = item.customFields[field.key];
        } else if (field.defaultValue != null) {
          val = field.defaultValue;
        }
        row.add(val?.toString() ?? '');
      }

      csvRows.add(row);
    }

    // 3. Convert to CSV string with standard CRLF line endings
    final csvData = const ListToCsvConverter(
      eol: '\r\n',
      delimit: ',',
    ).convert(csvRows);

    // 4. Save to documents directory
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/pokemon_collection_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);

    // 5. Trigger native device sharing dialog
    final xFile = XFile(filePath, mimeType: 'text/csv', name: 'pokemon_collection_$timestamp.csv');
    await Share.shareXFiles(
      [xFile],
      text: 'Exported Pokémon Card Collection (${items.length} cards)',
      subject: 'Pokémon Card Collection CSV Export',
    );

    return file;
  }
}

