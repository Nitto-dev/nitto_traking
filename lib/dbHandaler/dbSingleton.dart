import 'dart:convert';
import 'dart:io';
import 'package:nitto_traking/models/land_list_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  static const String LANDNAME = 'landName';
  static const String  ADDRESS= 'address';
  static const String  STARTPOINT= 'startPoint';
  static const String  ENDPOINT= 'endPoint';
  static const String  POINT= 'point';
  static const String TABLE = 'land_info';
  static const String DB_NAME = 'LandInfoTest.db';
  static Database _database;
  static final DBProvider db = DBProvider._();

  DBProvider._();

  Future<Database> get database async {
    // If database exists, return database
    if (_database != null) return _database;

    // If database don't exists, create one
    _database = await initDB();

    return _database;
  }

  // Create the database and the Employee table
  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "drivingTestSql.db");

    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
          await db.execute("CREATE TABLE $TABLE($LANDNAME TEXT,$ADDRESS TEXT,$STARTPOINT TEXT,$ENDPOINT TEXT,$POINT TEXT)");

        });
  }


  // Insert employee on database
  insertNotification(LandListModel landListModel) async {
    //await deleteAllEmployees();
    final db = await database;
    final res = await db.insert("$TABLE", landListModel.toJson());
    print(res.toString());
    return res;
  }
  // Delete all employees
  Future<int> deleteAllNotification() async {
    final db = await database;
    final res = await db.rawDelete('DELETE FROM land_info');

    return res;
  }


  Future<List<LandListModel>> getNotificationList() async {
    final db = await database;
    final res = await db.rawQuery("SELECT * FROM land_info");
    //print("db:"+res.toString());

    List<LandListModel> list =
    res.isNotEmpty ? res.map((c) => LandListModel.fromJson(c)).toList() : [];
    //print("db2:"+list[0].toString());

    return list;
  }
}