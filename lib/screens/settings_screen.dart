import 'package:flutter/material.dart';
import '../models/export_field_config.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPopupEnabled = true;
  List<ExportFieldDefinition> _fields = [];

  final TextEditingController _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiUrlController.text = ApiService.baseUrl;
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final config = await ApiService.getExportConfig();
      setState(() {
        _isPopupEnabled = config.isEnabled;
        _fields = List.from(config.fields);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    ApiService.baseUrl = _apiUrlController.text.trim();

    try {
      final updatedConfig = ExportConfig(
        isEnabled: _isPopupEnabled,
        fields: _fields,
      );
      await ApiService.updateExportConfig(updatedConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showAddFieldDialog() {
    final keyController = TextEditingController();
    final labelController = TextEditingController();
    final optionsController = TextEditingController();
    ExportFieldType selectedType = ExportFieldType.text;
    bool isRequired = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Dynamic Export Field'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'Field Key (e.g. storageBoxId)',
                        hintText: 'camelCase identifier',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label / Question',
                        hintText: 'Display name in popup and CSV',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ExportFieldType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Input Type'),
                      items: ExportFieldType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    if (selectedType == ExportFieldType.dropdown) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: optionsController,
                        decoration: const InputDecoration(
                          labelText: 'Comma-separated Options',
                          hintText: 'Option1, Option2, Option3',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Required Field'),
                      value: isRequired,
                      onChanged: (val) {
                        setDialogState(() => isRequired = val ?? false);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final key = keyController.text.trim();
                    final label = labelController.text.trim();
                    if (key.isEmpty || label.isEmpty) return;

                    final options = selectedType == ExportFieldType.dropdown
                        ? optionsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : <String>[];

                    setState(() {
                      _fields.add(
                        ExportFieldDefinition(
                          key: key,
                          label: label,
                          type: selectedType,
                          options: options,
                          required: isRequired,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add Field'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & App Settings'),
        backgroundColor: const Color(0xFF1B53BA),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. API Configuration
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backend Gateway Server',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiUrlController,
                          decoration: const InputDecoration(
                            labelText: 'NestJS Backend Base URL',
                            hintText: 'http://10.0.2.2:3003 or http://localhost:3003',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Pre-Export Confirmation Survey Toggle
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: SwitchListTile(
                    title: const Text(
                      'Show Metadata Popup before CSV Export',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Prompts you to specify condition, grade, box location, and prices right before exporting.',
                    ),
                    value: _isPopupEnabled,
                    activeColor: const Color(0xFF1B53BA),
                    onChanged: (val) {
                      setState(() {
                        _isPopupEnabled = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Dynamic Export Custom Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dynamic Export Fields & Columns',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B53BA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Field'),
                      onPressed: _showAddFieldDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'These fields appear in the pre-export popup and will be appended as dedicated columns in the exported CSV.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),

                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _fields.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _fields.removeAt(oldIndex);
                      _fields.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    return Card(
                      key: ValueKey(field.key),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1B53BA).withOpacity(0.12),
                          child: Icon(
                            field.type == ExportFieldType.dropdown
                                ? Icons.arrow_drop_down_circle
                                : field.type == ExportFieldType.number
                                    ? Icons.numbers
                                    : field.type == ExportFieldType.checkbox
                                        ? Icons.check_box
                                        : Icons.text_fields,
                            color: const Color(0xFF1B53BA),
                          ),
                        ),
                        title: Text('${field.label} (${field.key})'),
                        subtitle: Text(
                          'Type: ${field.type.name} • ${field.required ? "Required" : "Optional"}${field.options.isNotEmpty ? " • [${field.options.join(', ')}]" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _fields.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B53BA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Save Configuration', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

