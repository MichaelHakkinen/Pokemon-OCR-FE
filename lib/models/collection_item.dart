class MatchedCardItem {
  final String id;
  final String name;
  final String collectorNumber;
  final String normalizedNumber;
  final String? rarity;
  final String? cardType;
  final String? supertype;
  final String? hp;
  final String? imageUrl;
  final String setCode;
  final String setName;
  final String language;
  final String matchType;
  final double confidenceScore;

  MatchedCardItem({
    required this.id,
    required this.name,
    required this.collectorNumber,
    required this.normalizedNumber,
    this.rarity,
    this.cardType,
    this.supertype,
    this.hp,
    this.imageUrl,
    required this.setCode,
    required this.setName,
    required this.language,
    required this.matchType,
    required this.confidenceScore,
  });

  factory MatchedCardItem.fromJson(Map<String, dynamic> json) {
    return MatchedCardItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      collectorNumber: json['collectorNumber'] as String? ?? '',
      normalizedNumber: json['normalizedNumber'] as String? ?? '',
      rarity: json['rarity'] as String?,
      cardType: json['cardType'] as String?,
      supertype: json['supertype'] as String?,
      hp: json['hp'] as String?,
      imageUrl: json['imageUrl'] as String?,
      setCode: json['setCode'] as String? ?? '',
      setName: json['setName'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      matchType: json['matchType'] as String? ?? 'EXACT_CODE_AND_NUMBER',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ScanCardResponse {
  final String detectedScript;
  final List<String> nameCandidates;
  final List<String> setNumberCandidates;
  final List<String> setCodeCandidates;
  final List<MatchedCardItem> matchedCards;
  final bool isMatched;
  final double ocrTimeMs;

  ScanCardResponse({
    required this.detectedScript,
    required this.nameCandidates,
    required this.setNumberCandidates,
    required this.setCodeCandidates,
    required this.matchedCards,
    required this.isMatched,
    required this.ocrTimeMs,
  });

  factory ScanCardResponse.fromJson(Map<String, dynamic> json) {
    return ScanCardResponse(
      detectedScript: json['detectedScript'] as String? ?? 'latin',
      nameCandidates: (json['nameCandidates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      setNumberCandidates: (json['setNumberCandidates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      setCodeCandidates: (json['setCodeCandidates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      matchedCards: (json['matchedCards'] as List<dynamic>?)
              ?.map((c) => MatchedCardItem.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      isMatched: json['isMatched'] as bool? ?? false,
      ocrTimeMs: (json['ocrTimeMs'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserCardItem {
  final String id;
  final String cardId;
  final String cardName;
  final String setCode;
  final String setName;
  final String collectorNumber;
  final String? rarity;
  final String condition;
  final String grade;
  final String language;
  final int quantity;
  final String? imageUrl;
  final DateTime acquiredDate;
  final Map<String, dynamic> customFields;

  UserCardItem({
    required this.id,
    required this.cardId,
    required this.cardName,
    required this.setCode,
    required this.setName,
    required this.collectorNumber,
    this.rarity,
    required this.condition,
    required this.grade,
    required this.language,
    required this.quantity,
    this.imageUrl,
    required this.acquiredDate,
    required this.customFields,
  });

  factory UserCardItem.fromJson(Map<String, dynamic> json) {
    final card = json['card'] as Map<String, dynamic>? ?? {};
    final set = card['set'] as Map<String, dynamic>? ?? {};
    final translations = card['translations'] as List<dynamic>? ?? [];
    final firstTranslation = translations.isNotEmpty ? translations[0] : null;

    final name = firstTranslation != null
        ? firstTranslation['name'] as String? ?? 'Card ${card['collectorNumber']}'
        : 'Card ${card['collectorNumber']}';

    return UserCardItem(
      id: json['id'] as String? ?? '',
      cardId: json['cardId'] as String? ?? card['id'] as String? ?? '',
      cardName: name,
      setCode: set['code'] as String? ?? '',
      setName: set['name'] as String? ?? '',
      collectorNumber: card['collectorNumber'] as String? ?? '',
      rarity: card['rarity'] as String?,
      condition: json['condition'] as String? ?? 'NM',
      grade: json['grade'] as String? ?? 'Raw',
      language: json['language'] as String? ?? 'en',
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: card['imageUrl'] as String?,
      acquiredDate: json['acquiredDate'] != null
          ? DateTime.tryParse(json['acquiredDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customFields: (json['customFields'] as Map<String, dynamic>?) ?? {},
    );
  }
}

