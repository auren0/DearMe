import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openAppDatabase() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final path = p.join(directory.path, 'dearme.db');
  return databaseFactoryIo.openDatabase(path);
}
