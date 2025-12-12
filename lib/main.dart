import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/time_select.dart';
import 'screens/seat_selection.dart';
import 'screens/history_screen.dart';
import 'screens/seat_availability.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  runApp(const MyApp());
}

// 路由配置
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/time_select',
      builder: (context, state) => const TimeSelectScreen(),
    ),
    GoRoute(
      path: '/available_seats',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return SeatSelectionScreen(
          date: extras['date'],
          beginTime: extras['beginTime'],
          endTime: extras['endTime'],
        );
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/seat_availability',
      builder: (context, state) => const SeatAvailabilityScreen(),
    ),
  ],
);
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp.router(
        title: '学习中心',
        theme: ThemeData(
          // 配置应用的主题颜色
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC8102E),
          ), // 福大红
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black, // 标题颜色
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
