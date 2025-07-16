import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication.dart';

/// A generic paginated result container
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? nextPageToken;
  final bool hasMore;
  final int totalCount;
  
  const PaginatedResult({
    required this.items,
    this.nextPageToken,
    required this.hasMore,
    required this.totalCount,
  });
  
  /// Create an empty result
  factory PaginatedResult.empty() => const PaginatedResult(
    items: [],
    nextPageToken: null,
    hasMore: false,
    totalCount: 0,
  );
  
  /// Create a single page result with no more pages
  factory PaginatedResult.single(List<T> items) => PaginatedResult(
    items: items,
    nextPageToken: null,
    hasMore: false,
    totalCount: items.length,
  );
}

/// Medication statistics container
class MedicationStats {
  final int totalMedications;
  final Map<MedicationType, int> countByType;
  final int lowStockCount;
  final int expiredCount;
  final DateTime lastUpdated;
  
  const MedicationStats({
    required this.totalMedications,
    required this.countByType,
    required this.lowStockCount,
    required this.expiredCount,
    required this.lastUpdated,
  });
  
  /// Create from JSON
  factory MedicationStats.fromJson(Map<String, dynamic> json) {
    final Map<MedicationType, int> typeMap = {};
    final countByTypeData = json['countByType'] as Map<String, dynamic>? ?? {};
    
    countByTypeData.forEach((key, value) {
      try {
        final type = MedicationType.values.firstWhere(
          (e) => e.toString().split('.').last == key,
          orElse: () => MedicationType.tablet,
        );
        typeMap[type] = value as int;
      } catch (e) {
        // Skip invalid entries
      }
    });
    
    return MedicationStats(
      totalMedications: json['totalMedications'] as int? ?? 0,
      countByType: typeMap,
      lowStockCount: json['lowStockCount'] as int? ?? 0,
      expiredCount: json['expiredCount'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, int> typeMap = {};
    countByType.forEach((key, value) {
      typeMap[key.toString().split('.').last] = value;
    });
    
    return {
      'totalMedications': totalMedications,
      'countByType': typeMap,
      'lowStockCount': lowStockCount,
      'expiredCount': expiredCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}