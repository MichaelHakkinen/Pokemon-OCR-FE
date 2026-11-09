enum ExportFieldType {
  text,
  dropdown,
  checkbox,
  number,
}

class ExportFieldDefinition {
  final String key;
  final String label;
  final ExportFieldType type;
  final List<String> options;
  final dynamic defaultValue;
  final bool required;

  ExportFieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    this.defaultValue,
    this.required = false,
  });

  factory ExportFieldDefinition.fromJson(Map<String, dynamic> json) {
    ExportFieldType parseType(String? t) {
      switch (t?.toLowerCase()) {
        case 'dropdown':
          return ExportFieldType.dropdown;
        case 'checkbox':
          return ExportFieldType.checkbox;
        case 'number':
          return ExportFieldType.number;
        case 'text':
        default:
          return ExportFieldType.text;
      }
    }

    return ExportFieldDefinition(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: parseType(json['type'] as String?),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      defaultValue: json['defaultValue'],
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type.name,
      'options': options,
      'defaultValue': defaultValue,
      'required': required,
    };
  }
}

class ExportConfig {
  final bool isEnabled;
  final List<ExportFieldDefinition> fields;

  ExportConfig({
    required this.isEnabled,
    required this.fields,
  });

  factory ExportConfig.fromJson(Map<String, dynamic> json) {
    return ExportConfig(
      isEnabled: json['isEnabled'] as bool? ?? true,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((f) => ExportFieldDefinition.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }

  static ExportConfig defaultConfiguration() {
    return ExportConfig(
      isEnabled: true,
      fields: [
        ExportFieldDefinition(
          key: 'condition',
          label: 'Card Condition',
          type: ExportFieldType.dropdown,
          options: ['Mint', 'Near Mint', 'Lightly Played', 'Moderately Played', 'Damaged'],
          defaultValue: 'Near Mint',
          required: true,
        ),
        ExportFieldDefinition(
          key: 'graded',
          label: 'Graded?',
          type: ExportFieldType.dropdown,
          options: ['Raw', 'PSA', 'BGS', 'CGC', 'ARS'],
          defaultValue: 'Raw',
          required: true,
        ),
        ExportFieldDefinition(
          key: 'purchaseCurrency',
          label: 'Purchase Currency',
          type: ExportFieldType.dropdown,
          options: ['IDR', 'USD', 'JPY', 'EUR', 'GBP'],
          defaultValue: 'IDR',
          required: false,
        ),
        ExportFieldDefinition(
          key: 'purchasePrice',
          label: 'Purchase Price',
          type: ExportFieldType.number,
          defaultValue: 0,
          required: false,
        ),
        ExportFieldDefinition(
          key: 'storageBoxId',
          label: 'Storage Box / Binder ID',
          type: ExportFieldType.text,
          defaultValue: 'Binder-01',
          required: false,
        ),
        ExportFieldDefinition(
          key: 'notes',
          label: 'Notes / Location',
          type: ExportFieldType.text,
          defaultValue: '',
          required: false,
        ),
      ],
    );
  }
}

