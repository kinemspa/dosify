import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dosify_cursor/services/cache_manager.dart';

@GenerateMocks([SharedPreferences])
import 'cache_manager_test.mocks.dart';

void main() {
  group('CacheManager', () {
    late MockSharedPreferences mockPrefs;
    late CacheManager cacheManager;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      cacheManager = CacheManager(
        prefs: mockPrefs,
        defaultTtl: const Duration(minutes: 5),
        keyPrefix: 'test_cache_',
      );
    });

    group('initialization', () {
      test('should initialize successfully with valid expiry data', () async {
        const expiryData = '{"test_key": "2025-12-31T23:59:59.999Z"}';
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(expiryData);

        await cacheManager.initialize();

        verify(mockPrefs.getString('test_cache_expiry_times')).called(1);
      });

      test('should handle initialization with no expiry data', () async {
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(null);
        when(mockPrefs.getKeys()).thenReturn(<String>{});

        await cacheManager.initialize();

        verify(mockPrefs.getString('test_cache_expiry_times')).called(1);
      });

      test('should handle initialization with invalid expiry data', () async {
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn('invalid json');
        when(mockPrefs.getKeys()).thenReturn(<String>{});

        // Should not throw an exception
        await cacheManager.initialize();

        verify(mockPrefs.getString('test_cache_expiry_times')).called(1);
      });
    });

    group('set and get operations', () {
      test('should set and get string values', () async {
        const key = 'test_string';
        const value = 'test value';
        
        when(mockPrefs.setString('test_cache_$key', value)).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);

        final setResult = await cacheManager.set(key, value);
        expect(setResult, true);

        // Mock getting the value back
        when(mockPrefs.getString('test_cache_$key')).thenReturn(value);
        
        final getValue = cacheManager.get<String>(key);
        expect(getValue, equals(value));
      });

      test('should set and get int values', () async {
        const key = 'test_int';
        const value = 42;
        
        when(mockPrefs.setInt('test_cache_$key', value)).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);

        final setResult = await cacheManager.set(key, value);
        expect(setResult, true);

        when(mockPrefs.getInt('test_cache_$key')).thenReturn(value);
        
        final getValue = cacheManager.get<int>(key);
        expect(getValue, equals(value));
      });

      test('should set and get double values', () async {
        const key = 'test_double';
        const value = 3.14;
        
        when(mockPrefs.setDouble('test_cache_$key', value)).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);

        final setResult = await cacheManager.set(key, value);
        expect(setResult, true);

        when(mockPrefs.getDouble('test_cache_$key')).thenReturn(value);
        
        final getValue = cacheManager.get<double>(key);
        expect(getValue, equals(value));
      });

      test('should set and get bool values', () async {
        const key = 'test_bool';
        const value = true;
        
        when(mockPrefs.setBool('test_cache_$key', value)).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);

        final setResult = await cacheManager.set(key, value);
        expect(setResult, true);

        when(mockPrefs.getBool('test_cache_$key')).thenReturn(value);
        
        final getValue = cacheManager.get<bool>(key);
        expect(getValue, equals(value));
      });

      test('should set and get complex objects as JSON', () async {
        const key = 'test_object';
        final value = {'name': 'Test', 'age': 25, 'active': true};
        const jsonValue = '{"name":"Test","age":25,"active":true}';
        
        when(mockPrefs.setString('test_cache_$key', jsonValue)).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);

        final setResult = await cacheManager.set(key, value);
        expect(setResult, true);

        when(mockPrefs.getString('test_cache_$key')).thenReturn(jsonValue);
        
        final getValue = cacheManager.get<Map<String, dynamic>>(key);
        expect(getValue, equals(value));
      });

      test('should return null for non-existent keys', () {
        const key = 'non_existent';
        
        when(mockPrefs.getString('test_cache_$key')).thenReturn(null);
        when(mockPrefs.getInt('test_cache_$key')).thenReturn(null);
        when(mockPrefs.getDouble('test_cache_$key')).thenReturn(null);
        when(mockPrefs.getBool('test_cache_$key')).thenReturn(null);
        
        final stringValue = cacheManager.get<String>(key);
        final intValue = cacheManager.get<int>(key);
        final doubleValue = cacheManager.get<double>(key);
        final boolValue = cacheManager.get<bool>(key);
        
        expect(stringValue, null);
        expect(intValue, null);
        expect(doubleValue, null);
        expect(boolValue, null);
      });
    });

    group('expiry handling', () {
      test('should return null for expired values', () async {
        const key = 'expired_key';
        const value = 'expired value';
        
        // Set up an expired entry
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final expiryData = '{"$key": "${pastTime.toIso8601String()}"}';
        
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(expiryData);
        when(mockPrefs.getString('test_cache_$key')).thenReturn(value);
        
        await cacheManager.initialize();
        
        final getValue = cacheManager.get<String>(key);
        expect(getValue, null);
      });

      test('should return expired values when ignoreExpiry is true', () async {
        const key = 'expired_key';
        const value = 'expired value';
        
        // Set up an expired entry
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final expiryData = '{"$key": "${pastTime.toIso8601String()}"}';
        
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(expiryData);
        when(mockPrefs.getString('test_cache_$key')).thenReturn(value);
        
        await cacheManager.initialize();
        
        final getValue = cacheManager.get<String>(key, ignoreExpiry: true);
        expect(getValue, equals(value));
      });

      test('should respect custom TTL when setting values', () async {
        const key = 'custom_ttl_key';
        const value = 'test value';
        const customTtl = Duration(hours: 2);
        
        when(mockPrefs.setString('test_cache_$key', value)).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);

        final setResult = await cacheManager.set(key, value, ttl: customTtl);
        expect(setResult, true);

        // Verify that the expiry time is set correctly (approximately)
        verify(mockPrefs.setString('test_cache_expiry_times', any)).called(1);
      });
    });

    group('remove operations', () {
      test('should remove values correctly', () async {
        const key = 'test_remove';
        
        when(mockPrefs.remove('test_cache_$key')).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);

        final removeResult = await cacheManager.remove(key);
        expect(removeResult, true);

        verify(mockPrefs.remove('test_cache_$key')).called(1);
        verify(mockPrefs.setString('test_cache_expiry_times', any)).called(1);
      });

      test('should handle remove failures gracefully', () async {
        const key = 'test_remove_fail';
        
        when(mockPrefs.remove('test_cache_$key')).thenThrow(Exception('Remove failed'));

        final removeResult = await cacheManager.remove(key);
        expect(removeResult, false);
      });
    });

    group('clear operations', () {
      test('should clear all cache entries', () async {
        final keys = {'test_cache_key1', 'test_cache_key2', 'other_key'};
        
        when(mockPrefs.getKeys()).thenReturn(keys);
        when(mockPrefs.remove('test_cache_key1')).thenAnswer((_) async => true);
        when(mockPrefs.remove('test_cache_key2')).thenAnswer((_) async => true);

        final clearResult = await cacheManager.clear();
        expect(clearResult, true);

        verify(mockPrefs.remove('test_cache_key1')).called(1);
        verify(mockPrefs.remove('test_cache_key2')).called(1);
        verify(mockPrefs.remove('other_key')).never(); // Should not remove non-cache keys
      });

      test('should handle clear failures gracefully', () async {
        when(mockPrefs.getKeys()).thenThrow(Exception('GetKeys failed'));

        final clearResult = await cacheManager.clear();
        expect(clearResult, false);
      });
    });

    group('cleanExpiredEntries', () {
      test('should clean expired entries successfully', () async {
        const expiredKey = 'expired_key';
        const validKey = 'valid_key';
        
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final futureTime = DateTime.now().add(const Duration(hours: 1));
        
        final expiryData = '{"$expiredKey": "${pastTime.toIso8601String()}", "$validKey": "${futureTime.toIso8601String()}"}';
        
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(expiryData);
        when(mockPrefs.remove('test_cache_$expiredKey')).thenAnswer((_) async => true);
        when(mockPrefs.setString('test_cache_expiry_times', any)).thenAnswer((_) async => true);
        
        await cacheManager.initialize();
        final cleanedCount = await cacheManager.cleanExpiredEntries();
        
        expect(cleanedCount, equals(1));
        verify(mockPrefs.remove('test_cache_$expiredKey')).called(1);
      });

      test('should handle clean failures gracefully', () async {
        when(mockPrefs.getString('test_cache_expiry_times')).thenThrow(Exception('Failed'));
        
        final cleanedCount = await cacheManager.cleanExpiredEntries();
        expect(cleanedCount, equals(0));
      });
    });

    group('containsKey', () {
      test('should return true for existing non-expired keys', () async {
        const key = 'existing_key';
        
        final futureTime = DateTime.now().add(const Duration(hours: 1));
        final expiryData = '{"$key": "${futureTime.toIso8601String()}"}';
        
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(expiryData);
        when(mockPrefs.containsKey('test_cache_$key')).thenReturn(true);
        
        await cacheManager.initialize();
        
        final contains = cacheManager.containsKey(key);
        expect(contains, true);
      });

      test('should return false for expired keys when checkExpiry is true', () async {
        const key = 'expired_key';
        
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final expiryData = '{"$key": "${pastTime.toIso8601String()}"}';
        
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(expiryData);
        when(mockPrefs.containsKey('test_cache_$key')).thenReturn(true);
        
        await cacheManager.initialize();
        
        final contains = cacheManager.containsKey(key, checkExpiry: true);
        expect(contains, false);
      });

      test('should return true for expired keys when checkExpiry is false', () async {
        const key = 'expired_key';
        
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final expiryData = '{"$key": "${pastTime.toIso8601String()}"}';
        
        when(mockPrefs.getString('test_cache_expiry_times')).thenReturn(expiryData);
        when(mockPrefs.containsKey('test_cache_$key')).thenReturn(true);
        
        await cacheManager.initialize();
        
        final contains = cacheManager.containsKey(key, checkExpiry: false);
        expect(contains, true);
      });

      test('should return false for non-existent keys', () {
        const key = 'non_existent';
        
        when(mockPrefs.containsKey('test_cache_$key')).thenReturn(false);
        
        final contains = cacheManager.containsKey(key);
        expect(contains, false);
      });
    });

    group('error handling', () {
      test('should handle JSON encoding errors gracefully', () async {
        const key = 'test_json_error';
        
        // Create an object that can't be JSON encoded
        final circularObject = <String, dynamic>{};
        circularObject['self'] = circularObject;
        
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final setResult = await cacheManager.set(key, circularObject);
        expect(setResult, false);
      });

      test('should handle SharedPreferences failures gracefully', () async {
        const key = 'test_prefs_error';
        const value = 'test value';
        
        when(mockPrefs.setString('test_cache_$key', value)).thenThrow(Exception('SharedPreferences error'));
        
        final setResult = await cacheManager.set(key, value);
        expect(setResult, false);
      });

      test('should handle JSON decoding errors gracefully', () {
        const key = 'test_decode_error';
        
        when(mockPrefs.getString('test_cache_$key')).thenReturn('invalid json {');
        
        final getValue = cacheManager.get<Map<String, dynamic>>(key);
        expect(getValue, null);
      });
    });
  });
}