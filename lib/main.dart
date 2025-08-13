import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thesis_sys_app/router/router.dart';
import 'package:thesis_sys_app/services/dio_client.dart';

// Global key for accessing ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  if (kDebugMode) print('[MAIN] Starting application...');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('[MAIN] MyApp initState called');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) print('[MAIN] Attaching DioClient context...');
      DioClient().attachContext(context);
      if (kDebugMode) print('[MAIN] DioClient context attached');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print('[MAIN] Building MaterialApp...');
    final appRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
    );
  }

  @override
  void dispose() {
    if (kDebugMode) print('[MAIN] MyApp disposing...');
    super.dispose();
  }
}
