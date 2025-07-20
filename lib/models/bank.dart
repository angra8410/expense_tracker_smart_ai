class Bank {
  final String id;
  final String name;
  final String description;
  final Map<String, String> csvFieldMapping;
  final String? dateFormat;
  final String? amountFormat;
  final String? defaultAccountId;

  Bank({
    required this.id,
    required this.name,
    required this.description,
    required this.csvFieldMapping,
    this.dateFormat,
    this.amountFormat,
    this.defaultAccountId,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      csvFieldMapping: Map<String, String>.from(json['csvFieldMapping']),
      dateFormat: json['dateFormat'] as String?,
      amountFormat: json['amountFormat'] as String?,
      defaultAccountId: json['defaultAccountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'csvFieldMapping': csvFieldMapping,
      'dateFormat': dateFormat,
      'amountFormat': amountFormat,
      'defaultAccountId': defaultAccountId,
    };
  }
}