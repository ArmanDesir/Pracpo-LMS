import 'package:flutter/material.dart';
import 'package:pracpro/modules/basic_operators/basic_operations_dashboard.dart';
import 'package:pracpro/providers/basic_operator_lesson_provider.dart';
import 'package:pracpro/providers/basic_operator_quiz_provider.dart';
import 'package:pracpro/providers/basic_operator_exercise_provider.dart';
import 'package:pracpro/providers/lesson_provider.dart';
import 'package:pracpro/providers/quiz_provider.dart';
import 'package:pracpro/screens/basic_operator_module_page.dart';
import 'package:pracpro/screens/create_content_screen.dart';
import 'package:pracpro/screens/student_dashboard.dart';
import 'package:pracpro/widgets/loading_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/classroom_provider.dart';
import 'providers/activity_provider.dart';
import 'models/user.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/teacher_dashboard.dart';

const String supabaseUrl = 'https://iblysqwclgpkijsxfgif.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlibHlzcXdjbGdwa2lqc3hmZ2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4ODkzMzUsImV4cCI6MjA3MjQ2NTMzNX0.QjrhspglPRecKsXQ0XHswqHyvvQuOymsuh1xUGrT5xE';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ClassroomProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => BasicOperatorLessonProvider()),
        ChangeNotifierProvider(create: (_) => BasicOperatorQuizProvider()),
        ChangeNotifierProvider(create: (_) => BasicOperatorExerciseProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PracPro',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          if (settings.name == '/basic_operator/create') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CreateContentScreen(
                operator: args['operator'],
                contentType: args['contentType'],
                classroomId: args['classroomId'],
              ),
            );
          }

          final validOperators = ['addition', 'subtraction', 'multiplication', 'division'];
          if (validOperators.contains(settings.name?.replaceFirst('/', ''))) {
            final operatorName = settings.name!.replaceFirst('/', '');
            return MaterialPageRoute(
              builder: (_) => BasicOperatorModulePage(operatorName: operatorName),
            );
          }
          return null;
        },
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/basic_operations': (context) => const BasicOperationsDashboard(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingWrapper(
          isLoading: authProvider.isLoading,
          child: !authProvider.isAuthenticated || authProvider.currentUser == null
              ? const WelcomeScreen()
              : authProvider.currentUser!.userType == UserType.teacher
                  ? const TeacherDashboard()
                  : const StudentDashboard(),
        );
      },
    );
  }
}
