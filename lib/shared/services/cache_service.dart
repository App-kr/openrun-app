import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/performances/models/performance.dart';

part 'cache_service.g.dart';

@riverpod
CacheService cacheService(CacheServiceRef ref) => CacheService();

/// Cache validity: 2 hours
const _cacheMaxAgeMs = 2 * 60 * 60 * 1000;

class CacheService {
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'openrun_cache.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE performances (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'all',
            region TEXT NOT NULL DEFAULT 'all',
            cached_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add category/region columns if missing
          try {
            await db.execute("ALTER TABLE performances ADD COLUMN category TEXT NOT NULL DEFAULT 'all'");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE performances ADD COLUMN region TEXT NOT NULL DEFAULT 'all'");
          } catch (_) {}
        }
      },
    );
  }

  Future<void> savePerformances(
    List<Performance> perfs, {
    String category = 'all',
    String region = 'all',
  }) async {
    final d = await db;
    final batch = d.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in perfs) {
      batch.insert(
        'performances',
        {
          'id': p.id,
          'data': jsonEncode(p.toJson()),
          'category': category,
          'region': region,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Performance>> loadPerformances({
    String category = 'all',
    String region = 'all',
  }) async {
    final d = await db;
    final cutoff = DateTime.now().millisecondsSinceEpoch - _cacheMaxAgeMs;

    String where = 'cached_at > ?';
    final List<dynamic> args = [cutoff];

    if (category != 'all') {
      where += ' AND category = ?';
      args.add(category);
    }
    if (region != 'all') {
      where += ' AND region = ?';
      args.add(region);
    }

    final rows = await d.query('performances', where: where, whereArgs: args);
    return rows.map((r) => Performance.fromJson(jsonDecode(r['data'] as String))).toList();
  }

  Future<bool> hasFreshCache({String category = 'all', String region = 'all'}) async {
    final cached = await loadPerformances(category: category, region: region);
    return cached.isNotEmpty;
  }

  Future<void> clearCache() async {
    final d = await db;
    await d.delete('performances');
  }
}
