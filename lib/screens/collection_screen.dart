import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../models/export_field_config.dart';
import '../services/api_service.dart';
import '../services/csv_export_service.dart';
import '../widgets/dynamic_export_dialog.dart';
import 'settings_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<UserCardItem> _collection = [];

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.getCollection();
      setState(() {
        _collection = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load collection: $e')),
        );
      }
    }
  }

  Future<void> _triggerCsvExportFlow() async {
    if (_collection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection is empty. Scan some cards first!')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // 1. Fetch export configuration (toggle state and dynamic field definitions)
      final exportConfig = await ApiService.getExportConfig();

      Map<String, dynamic> surveyAnswers = {};

      // 2. Check if Pre-Export Survey Popup is globally enabled
      if (exportConfig.isEnabled && exportConfig.fields.isNotEmpty) {
        if (!mounted) return;
        final result = await DynamicExportDialog.show(
          context,
          fields: exportConfig.fields,
        );

        // If user cancelled the dialog, abort export
        if (result == null) {
          setState(() => _isExporting = false);
          return;
        }
        surveyAnswers = result;
      }

      // 3. Generate CSV, save locally, and trigger native share sheet
      await CsvExportService.exportAndShareCollection(
        items: _collection,
        dynamicFields: exportConfig.fields,
        surveyAnswers: surveyAnswers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV successfully generated and shared!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pokémon Collection'),
        backgroundColor: const Color(0xFF1B53BA),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Export & App Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadCollection();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collection.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 14),
                      const Text(
                        'No cards scanned yet.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Scan your first Pokémon card from the camera screen!',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCollection,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: _collection.length,
                    itemBuilder: (context, index) {
                      final item = _collection[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: item.imageUrl != null
                                ? Image.network(item.imageUrl!, width: 44, fit: BoxFit.contain)
                                : Container(
                                    width: 44,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.style),
                                  ),
                          ),
                          title: Text(
                            item.cardName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.setCode} #${item.collectorNumber} • ${item.condition} (${item.grade})',
                          ),
                          trailing: Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B53BA),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B53BA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
            label: Text(
              _isExporting ? 'Generating CSV...' : 'Export Collection to CSV',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isExporting ? null : _triggerCsvExportFlow,
          ),
        ),
      ),
    );
  }
}

