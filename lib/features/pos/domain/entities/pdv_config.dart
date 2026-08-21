class PdvConfig {
  final int? pdvId;
  final int? branchId;
  final String? branchNumber;
  final bool? offlineMode;
  final int? creditNoteDaysLimit;

  const PdvConfig({
    this.pdvId,
    this.branchId,
    this.branchNumber,
    this.offlineMode,
    this.creditNoteDaysLimit,
  });

  PdvConfig copyWith({
    int? pdvId,
    int? branchId,
    String? branchNumber,
    bool? offlineMode,
    int? creditNoteDaysLimit,
  }) {
    return PdvConfig(
      pdvId: pdvId ?? this.pdvId,
      branchId: branchId ?? this.branchId,
      branchNumber: branchNumber ?? this.branchNumber,
      offlineMode: offlineMode ?? this.offlineMode,
      creditNoteDaysLimit: creditNoteDaysLimit ?? this.creditNoteDaysLimit,
    );
  }

  Map<String, dynamic> toJson() => {
        'delivery_location_id': pdvId,
        'branch_id': branchId,
        'branch_number': branchNumber,
        'offline_mode': offlineMode,
        'credit_note_days_limit': creditNoteDaysLimit,
      };

  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = {};
    if (pdvId != null) data['delivery_location_id'] = pdvId;
    if (branchId != null) data['branch_id'] = branchId;
    if (creditNoteDaysLimit != null) data['credit_note_days_limit'] = creditNoteDaysLimit;
    return data;
  }

  Map<String, dynamic> toUpdateOfflineModeJson() {
    final Map<String, dynamic> data = {};
    if (offlineMode != null) data['offline_mode'] = offlineMode;
    return data;
  }

  factory PdvConfig.fromJson(Map<String, dynamic> json) => PdvConfig(
        pdvId: json['delivery_location_id'] as int?,
        branchId: json['branch_id'] as int?,
        branchNumber: json['branch_number'] as String?,
        offlineMode: json['offline_mode'] as bool?,
        creditNoteDaysLimit: json['credit_note_days_limit'] as int?,
      );
}

class Branch {
  final int id;
  final String name;
  final bool afipAvailable;
  final bool applyPerIibb;
  final int? perIibbAmount;
  final bool applyPerVat;
  final int? perVatAmount;
  final int? defaultIibbTaxRate;
  final int? provinceId;
  final int? priority;

  const Branch({
    required this.id,
    required this.name,
    required this.afipAvailable,
    required this.applyPerIibb,
    this.perIibbAmount,
    required this.applyPerVat,
    this.perVatAmount,
    this.defaultIibbTaxRate,
    this.provinceId,
    this.priority,
  });

  factory Branch.fromModel(dynamic model) {
    return Branch(
      id: model.branchId ?? 0,
      name: model.name ?? '',
      afipAvailable: model.afipAvailable ?? false,
      applyPerIibb: model.applyPerIibb ?? false,
      perIibbAmount: model.perIibbAmount,
      applyPerVat: model.applyPerVat ?? false,
      perVatAmount: model.perVatAmount,
      defaultIibbTaxRate: model.defaultIibbTaxRate,
      provinceId: model.provinceId,
      priority: model.priority,
    );
  }
}
