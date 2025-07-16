import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dosify_cursor/models/paginated_result.dart';
import 'package:dosify_cursor/models/medication.dart';

@GenerateMocks([DocumentSnapshot])
import 'paginated_result_test.mocks.dart';

void main() {
  group('PaginatedResult', () {
    test('should create paginated result with all parameters', () {
      final mockDoc = MockDocumentSnapshot();
      final items = ['item1', 'item2', 'item3'];
      
      final result = PaginatedResult<String>(
        items: items,
        nextPageToken: mockDoc,
        hasMore: true,
        totalCount: 100,
      );

      expect(result.items, equals(items));
      expect(result.nextPageToken, equals(mockDoc));
      expect(result.hasMore, true);
      expect(result.totalCount, equals(100));
    });

    test('should create paginated result with minimal parameters', () {
      final items = ['item1', 'item2'];
      
      final result = PaginatedResult<String>(
        items: items,
        hasMore: false,
        totalCount: 2,
      );

      expect(result.items, equals(items));
      expect(result.nextPageToken, null);
      expect(result.hasMore, false);
      expect(result.totalCount, equals(2));
    });

    test('should create empty paginated result', () {
      final result = PaginatedResult<String>.empty();

      expect(result.items, isEmpty);
      expect(result.nextPageToken, null);
      expect(result.hasMore, false);
      expect(result.totalCount, equals(0));
    });

    test('should create single page result', () {
      final items = ['single1', 'single2', 'single3'];
      final result = PaginatedResult<String>.single(items);

      expect(result.items, equals(items));
      expect(result.nextPageToken, null);
      expect(result.hasMore, false);
      expect(result.totalCount, equals(3));
    });

    test('should handle empty list in single page result', () {
      final result = PaginatedResult<String>.single([]);

      expect(result.items, isEmpty);
      expect(result.nextPageToken, null);
      expect(result.hasMore, false);
      expect(result.totalCount, equals(0));
    });

    test('should work with different data types', () {
      // Test with integers
      final intResult = PaginatedResult<int>(
        items: [1, 2, 3],
        hasMore: true,
        totalCount: 10,
      );
      expect(intResult.items, equals([1, 2, 3]));

      // Test with maps
      final mapItems = [
        {'id': 1, 'name': 'Item 1'},
        {'id': 2, 'name': 'Item 2'},
      ];
      final mapResult = PaginatedResult<Map<String, dynamic>>(
        items: mapItems,
        hasMore: false,
        totalCount: 2,
      );
      expect(mapResult.items, equals(mapItems));
    });

    test('should handle large total counts', () {
      final result = PaginatedResult<String>(
        items: ['item1'],
        hasMore: true,
        totalCount: 999999,
      );

      expect(result.totalCount, equals(999999));
      expect(result.hasMore, true);
    });
  });

  group('MedicationStats', () {
    test('should create medication stats with all parameters', () {
      final countByType = {
        MedicationType.tablet: 10,
        MedicationType.injection: 5,
        MedicationType.capsule: 3,
      };
      final lastUpdated = DateTime(2025, 1, 15);

      final stats = MedicationStats(
        totalMedications: 18,
        countByType: countByType,
        lowStockCount: 2,
        expiredCount: 1,
        lastUpdated: lastUpdated,
      );

      expect(stats.totalMedications, equals(18));
      expect(stats.countByType, equals(countByType));
      expect(stats.lowStockCount, equals(2));
      expect(stats.expiredCount, equals(1));
      expect(stats.lastUpdated, equals(lastUpdated));
    });

    test('should create empty medication stats', () {
      final stats = MedicationStats(
        totalMedications: 0,
        countByType: const {},
        lowStockCount: 0,
        expiredCount: 0,
        lastUpdated: DateTime(2025, 1, 15),
      );

      expect(stats.totalMedications, equals(0));
      expect(stats.countByType, isEmpty);
      expect(stats.lowStockCount, equals(0));
      expect(stats.expiredCount, equals(0));
    });

    group('JSON serialization', () {
      test('should convert to JSON correctly', () {
        final countByType = {
          MedicationType.tablet: 10,
          MedicationType.injection: 5,
        };
        final lastUpdated = DateTime(2025, 1, 15, 10, 30, 45);

        final stats = MedicationStats(
          totalMedications: 15,
          countByType: countByType,
          lowStockCount: 2,
          expiredCount: 1,
          lastUpdated: lastUpdated,
        );

        final json = stats.toJson();

        expect(json['totalMedications'], equals(15));
        expect(json['countByType'], equals({
          'tablet': 10,
          'injection': 5,
        }));
        expect(json['lowStockCount'], equals(2));
        expect(json['expiredCount'], equals(1));
        expect(json['lastUpdated'], equals('2025-01-15T10:30:45.000'));
      });

      test('should create from JSON correctly', () {
        final json = {
          'totalMedications': 20,
          'countByType': {
            'tablet': 12,
            'capsule': 5,
            'injection': 3,
          },
          'lowStockCount': 4,
          'expiredCount': 2,
          'lastUpdated': '2025-01-15T14:30:00.000Z',
        };

        final stats = MedicationStats.fromJson(json);

        expect(stats.totalMedications, equals(20));
        expect(stats.countByType[MedicationType.tablet], equals(12));
        expect(stats.countByType[MedicationType.capsule], equals(5));
        expect(stats.countByType[MedicationType.injection], equals(3));
        expect(stats.lowStockCount, equals(4));
        expect(stats.expiredCount, equals(2));
        expect(stats.lastUpdated, equals(DateTime.parse('2025-01-15T14:30:00.000Z')));
      });

      test('should handle JSON with missing fields gracefully', () {
        final json = {
          'totalMedications': 10,
          // Missing countByType, lowStockCount, expiredCount
          'lastUpdated': '2025-01-15T12:00:00.000Z',
        };

        final stats = MedicationStats.fromJson(json);

        expect(stats.totalMedications, equals(10));
        expect(stats.countByType, isEmpty);
        expect(stats.lowStockCount, equals(0));
        expect(stats.expiredCount, equals(0));
        expect(stats.lastUpdated, equals(DateTime.parse('2025-01-15T12:00:00.000Z')));
      });

      test('should handle JSON with null values gracefully', () {
        final json = {
          'totalMedications': null,
          'countByType': null,
          'lowStockCount': null,
          'expiredCount': null,
          'lastUpdated': '2025-01-15T12:00:00.000Z',
        };

        final stats = MedicationStats.fromJson(json);

        expect(stats.totalMedications, equals(0));
        expect(stats.countByType, isEmpty);
        expect(stats.lowStockCount, equals(0));
        expect(stats.expiredCount, equals(0));
      });

      test('should handle invalid medication types in JSON', () {
        final json = {
          'totalMedications': 5,
          'countByType': {
            'tablet': 3,
            'invalid_type': 2,
            'capsule': 1,
          },
          'lowStockCount': 0,
          'expiredCount': 0,
          'lastUpdated': '2025-01-15T12:00:00.000Z',
        };

        final stats = MedicationStats.fromJson(json);

        expect(stats.totalMedications, equals(5));
        expect(stats.countByType[MedicationType.tablet], equals(3));
        expect(stats.countByType[MedicationType.capsule], equals(1));
        // invalid_type should be skipped
        expect(stats.countByType.length, equals(2));
      });

      test('should roundtrip JSON serialization correctly', () {
        final original = MedicationStats(
          totalMedications: 25,
          countByType: {
            MedicationType.tablet: 15,
            MedicationType.injection: 7,
            MedicationType.capsule: 3,
          },
          lowStockCount: 5,
          expiredCount: 2,
          lastUpdated: DateTime(2025, 1, 15, 16, 45, 30),
        );

        final json = original.toJson();
        final restored = MedicationStats.fromJson(json);

        expect(restored.totalMedications, equals(original.totalMedications));
        expect(restored.countByType, equals(original.countByType));
        expect(restored.lowStockCount, equals(original.lowStockCount));
        expect(restored.expiredCount, equals(original.expiredCount));
        expect(restored.lastUpdated.millisecondsSinceEpoch, 
               equals(original.lastUpdated.millisecondsSinceEpoch));
      });
    });

    group('edge cases', () {
      test('should handle very large medication counts', () {
        final stats = MedicationStats(
          totalMedications: 999999,
          countByType: {
            MedicationType.tablet: 500000,
            MedicationType.injection: 499999,
          },
          lowStockCount: 100000,
          expiredCount: 50000,
          lastUpdated: DateTime.now(),
        );

        expect(stats.totalMedications, equals(999999));
        expect(stats.countByType[MedicationType.tablet], equals(500000));
      });

      test('should handle all medication types', () {
        final allTypes = MedicationType.values;
        final countByType = <MedicationType, int>{};
        
        for (int i = 0; i < allTypes.length; i++) {
          countByType[allTypes[i]] = i + 1;
        }

        final stats = MedicationStats(
          totalMedications: allTypes.length,
          countByType: countByType,
          lowStockCount: 0,
          expiredCount: 0,
          lastUpdated: DateTime.now(),
        );

        expect(stats.countByType.length, equals(allTypes.length));
        for (final type in allTypes) {
          expect(stats.countByType.containsKey(type), true);
        }
      });

      test('should handle date boundaries correctly', () {
        final extremeDates = [
          DateTime(1970, 1, 1), // Unix epoch
          DateTime(2038, 1, 19, 3, 14, 7), // 32-bit timestamp limit
          DateTime(9999, 12, 31, 23, 59, 59), // Far future
        ];

        for (final date in extremeDates) {
          final stats = MedicationStats(
            totalMedications: 1,
            countByType: const {},
            lowStockCount: 0,
            expiredCount: 0,
            lastUpdated: date,
          );

          final json = stats.toJson();
          final restored = MedicationStats.fromJson(json);

          expect(restored.lastUpdated.millisecondsSinceEpoch, 
                 equals(date.millisecondsSinceEpoch));
        }
      });
    });
  });
}