import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class LocalSqliteDatabase {
  static final LocalSqliteDatabase instance = LocalSqliteDatabase._();
  LocalSqliteDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbFolder = await getDatabasesPath();
    final path = p.join(dbFolder, 'ho_kinh_doanh_dynamic_v2.db');
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE store_settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            store_name TEXT NOT NULL,
            store_subtitle TEXT NOT NULL,
            bank_name TEXT,
            bank_account TEXT,
            bank_holder TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            materialized_path TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE suppliers (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            payable_debt INTEGER NOT NULL DEFAULT 0,
            category_ids_json TEXT NOT NULL DEFAULT '[]'
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            sku TEXT NOT NULL,
            name TEXT NOT NULL,
            category_id INTEGER NOT NULL,
            primary_supplier_id INTEGER,
            supplier_ids_json TEXT NOT NULL DEFAULT '[]',
            base_unit TEXT NOT NULL,
            stock_qty REAL NOT NULL DEFAULT 0,
            min_stock REAL NOT NULL DEFAULT 5,
            cost_price INTEGER NOT NULL DEFAULT 0,
            retail_price INTEGER NOT NULL DEFAULT 0,
            pack_unit_name TEXT,
            pack_rate REAL NOT NULL DEFAULT 1,
            pack_price INTEGER NOT NULL DEFAULT 0,
            track_shell INTEGER NOT NULL DEFAULT 0,
            spec_note TEXT,
            image_path TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE households (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            head_name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            credit_limit INTEGER NOT NULL DEFAULT 20000000,
            current_debt INTEGER NOT NULL DEFAULT 0,
            container_owed INTEGER NOT NULL DEFAULT 0,
            members_json TEXT NOT NULL DEFAULT '[]'
          )
        ''');

        await db.execute('''
          CREATE TABLE debt_ledgers (
            id INTEGER PRIMARY KEY,
            household_id INTEGER NOT NULL,
            date_str TEXT NOT NULL,
            actor_name TEXT NOT NULL,
            description TEXT NOT NULL,
            change_amount INTEGER NOT NULL,
            balance_after INTEGER NOT NULL,
            FOREIGN KEY (household_id) REFERENCES households (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY,
            date_str TEXT NOT NULL,
            order_type TEXT NOT NULL,
            category_root_id INTEGER NOT NULL,
            total_amount INTEGER NOT NULL,
            cogs INTEGER NOT NULL,
            paid_amount INTEGER NOT NULL,
            debt_amount INTEGER NOT NULL,
            description TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cash_transactions (
            id INTEGER PRIMARY KEY,
            date_str TEXT NOT NULL,
            flow TEXT NOT NULL,
            category TEXT NOT NULL,
            method TEXT NOT NULL,
            amount INTEGER NOT NULL,
            note TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<StoreConfig> loadStoreConfig() async {
    final db = await database;
    final rows = await db.query('store_settings', where: 'id = 1');
    if (rows.isEmpty) return const StoreConfig();
    return StoreConfig.fromMap(rows.first);
  }

  Future<void> saveStoreConfig(StoreConfig config) async {
    final db = await database;
    await db.insert(
      'store_settings',
      {'id': 1, ...config.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CategoryNode>> loadCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map(CategoryNode.fromMap).toList();
  }

  Future<void> upsertCategory(CategoryNode cat) async {
    final db = await database;
    await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategorySubtree(List<int> subtreeIds) async {
    if (subtreeIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(subtreeIds.length, '?').join(',');
    await db.transaction((txn) async {
      await txn.delete('categories', where: 'id IN ($placeholders)', whereArgs: subtreeIds);
      await txn.delete('products', where: 'category_id IN ($placeholders)', whereArgs: subtreeIds);
    });
  }

  Future<List<SupplierModel>> loadSuppliers() async {
    final db = await database;
    final rows = await db.query('suppliers', orderBy: 'id ASC');
    return rows.map(SupplierModel.fromMap).toList();
  }

  Future<void> upsertSupplier(SupplierModel sup) async {
    final db = await database;
    await db.insert('suppliers', sup.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSupplier(int id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProductModel>> loadProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'id DESC');
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<void> upsertProduct(ProductModel prod) async {
    final db = await database;
    await db.insert('products', prod.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HouseholdModel>> loadHouseholds() async {
    final db = await database;
    final hhRows = await db.query('households', orderBy: 'id DESC');
    final ledgerRows = await db.query('debt_ledgers', orderBy: 'id DESC');
    final allLedgers = ledgerRows.map(DebtLedgerEntry.fromMap).toList();

    return hhRows.map((row) {
      final hhId = row['id'] as int;
      final hhLedgers = allLedgers.where((l) => l.householdId == hhId).toList();
      return HouseholdModel.fromMap(row, ledger: hhLedgers);
    }).toList();
  }

  Future<void> upsertHousehold(HouseholdModel hh) async {
    final db = await database;
    await db.insert('households', hh.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertDebtLedger(DebtLedgerEntry entry) async {
    final db = await database;
    await db.insert('debt_ledgers', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHousehold(int id) async {
    final db = await database;
    await db.delete('households', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<OrderRecordModel>> loadOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'date_str DESC, id DESC');
    return rows.map(OrderRecordModel.fromMap).toList();
  }

  Future<void> insertOrder(OrderRecordModel order) async {
    final db = await database;
    await db.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CashTxModel>> loadCashTransactions() async {
    final db = await database;
    final rows = await db.query('cash_transactions', orderBy: 'date_str DESC, id DESC');
    return rows.map(CashTxModel.fromMap).toList();
  }

  Future<void> insertCashTransaction(CashTxModel tx) async {
    final db = await database;
    await db.insert('cash_transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cash_transactions');
      await txn.delete('orders');
      await txn.delete('debt_ledgers');
      await txn.delete('households');
      await txn.delete('products');
      await txn.delete('suppliers');
      await txn.delete('categories');
    });
  }
}
