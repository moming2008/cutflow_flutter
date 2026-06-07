import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'core/database/app_database.dart';
import 'core/init/app_initializer.dart';
import 'core/util/logger.dart';
import 'navigation/app_router.dart';
import 'ui/theme/theme.dart';

/// 应用版本号，与 pubspec.yaml 保持同步
const String kAppVersion = '1.6.0';

late AppDatabase database;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 media_kit 视频播放引擎 (Windows 桌面支持)
  MediaKit.ensureInitialized();
  log('Main').i('media_kit engine initialized');

  // 初始化数据库
  database = AppDatabase();
  log('Main').i('database initialized');

  // 初始化应用(内置预设等)
  await AppInitializer.initialize(database);
  log('Main').i('app initializer completed');

  runApp(
    ProviderScope(
      child: CutFlowApp(),
    ),
  );
}

class CutFlowApp extends StatelessWidget {
  const CutFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CutFlow',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      routerConfig: appRouter,
    );
  }
}
