import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sembast/sembast_memory.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/database/app_database.dart';
import 'core/models/app_settings.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final settingsRepository = await _createSettingsRepository();
  var settings = const AppSettings.defaults();
  try {
    settings = await settingsRepository.load();
  } on Object catch (error, stackTrace) {
    developer.log(
      'Could not load settings; using defaults.',
      name: 'dearme.bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
  }

  var storageAvailable = true;
  AppDatabase database;
  try {
    database = await AppDatabase.open();
  } on Object catch (error, stackTrace) {
    storageAvailable = false;
    developer.log(
      'Persistent storage could not be opened; using memory storage.',
      name: 'dearme.bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    database = AppDatabase.fromDatabase(
      await databaseFactoryMemory.openDatabase('dearme-memory.db'),
    );
  }

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      initialSettingsProvider.overrideWithValue(settings),
      storageAvailableProvider.overrideWithValue(storageAvailable),
    ],
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const DearMeApp()),
  );
}

Future<SettingsRepository> _createSettingsRepository() async {
  try {
    return await SharedPreferencesSettingsRepository.create();
  } on Object catch (error, stackTrace) {
    developer.log(
      'Could not open preferences; settings will be kept in memory.',
      name: 'dearme.bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    return InMemorySettingsRepository();
  }
}
