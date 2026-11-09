import 'package:flutter/material.dart';
import '../models/export_field_config.dart';

class DynamicExportDialog extends StatefulWidget {
  final List<ExportFieldDefinition> fields;
  final Function(Map<String, dynamic> responses) onConfirm;

  const DynamicExportDialog({
    super.key,
    required this.fields,
    required this.onConfirm,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required List<ExportFieldDefinition> fields,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DynamicExportDialog(
        fields: fields,
        onConfirm: (data) => Navigator.of(context).pop(data),
      ),
    );
  }

  @override
  State<DynamicExportDialog> createState() => _DynamicExportDialogState();
}

class _DynamicExportDialogState extends State<DynamicExportDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize form defaults
    for (final field in widget.fields) {
      if (field.type == ExportFieldType.checkbox) {
        _formData[field.key] = field.defaultValue is bool ? field.defaultValue : false;
      } else if (field.type == ExportFieldType.dropdown) {
        final defaultOption = field.defaultValue?.toString() ??
            (field.options.isNotEmpty ? field.options.first : '');
        _formData[field.key] = defaultOption;
      } else {
        final textVal = field.defaultValue?.toString() ?? '';
        _formData[field.key] = textVal;
        _controllers[field.key] = TextEditingController(text: textVal);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildFieldWidget(ExportFieldDefinition field) {
    switch (field.type) {
      case ExportFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DropdownButtonFormField<String>(
            value: _formData[field.key] as String?,
            decoration: InputDecoration(
              labelText: '${field.label}${field.required ? ' *' : ''}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: field.options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _formData[field.key] = val;
              });
            },
            validator: (val) {
              if (field.required && (val == null || val.isEmpty)) {
                return 'Please select ${field.label}';
              }
              return null;
            },
          ),
        );

      case ExportFieldType.checkbox:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CheckboxListTile(
            title: Text(field.label, style: const TextStyle(fontSize: 14)),
            value: (_formData[field.key] as bool?) ?? false,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: const Color(0xFF1B53BA),
            onChanged: (val) {
              setState(() {
                _formData[field.key] = val ?? false;
              });
            },
          ),
        );

      case ExportFieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _controllers[field.key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${field.label}${field.required ? ' *' : ''}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              _formData[field.key] = num.tryParse(val) ?? val;
            },
            validator: (val) {
              if (field.required && (val == null || val.trim().isEmpty)) {
                return 'Please enter ${field.label}';
              }
              return null;
            },
          ),
        );

      case ExportFieldType.text:
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _controllers[field.key],
            decoration: InputDecoration(
              labelText: '${field.label}${field.required ? ' *' : ''}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              _formData[field.key] = val;
            },
            validator: (val) {
              if (field.required && (val == null || val.trim().isEmpty)) {
                return 'Please enter ${field.label}';
              }
              return null;
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.table_chart_rounded, color: Color(0xFF1B53BA)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Export Survey & Metadata',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.88,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customize the export parameters below. These values will be appended as dedicated columns in your generated CSV.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 18),
                ...widget.fields.map(_buildFieldWidget),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.file_download, size: 18),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B53BA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              // Sync controllers to form data
              for (final entry in _controllers.entries) {
                if (!_formData.containsKey(entry.key) || _formData[entry.key] is String) {
                  _formData[entry.key] = entry.value.text;
                }
              }
              widget.onConfirm(_formData);
            }
          },
        ),
      ],
    );
  }
}

