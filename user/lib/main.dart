import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import các màn hình của bạn
import 'feature/auth/login_screen.dart'; 
import 'feature/survey/collect_information_screen.dart';
import 'feature/home/homepage_screen.dart';
// Import màn hình giới thiệu mới (Xem code mẫu bên dưới nếu chưa có)
import 'feature/home/introduce_screen.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  // --- LẤY CÁC TRẠNG THÁI ---
  // 1. Kiểm tra đã xem màn hình giới thiệu lần đầu chưa?
  final bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
  
  // 2. Kiểm tra UserId (để biết đã login chưa)
  final String? userId = prefs.getString('userId');
  
  // 3. Kiểm tra đã làm khảo sát chưa
  final bool isSurveyDone = prefs.getBool('isSurveyDone') ?? false;

  // --- XÁC ĐỊNH MÀN HÌNH ---
  Widget initialScreen;
  
  if (!hasSeenIntro) {
    // TH1: Mới tải app, chưa xem giới thiệu -> Vào IntroScreen
    initialScreen = const OnboardingScreen(); 
  } else if (userId == null) {
    // TH2: Đã xem intro nhưng chưa đăng nhập -> Vào LoginScreen
    initialScreen = const LoginScreen(); 
  } else if (!isSurveyDone) {
    // TH3: Đã login nhưng chưa làm khảo sát -> Vào Survey
    initialScreen = OnboardingFlowScreen(userId: userId); 
  } else {
    // TH4: Xong hết -> Vào Trang Chủ
    initialScreen = const HomePage();
  }
  await dotenv.load(fileName: ".env"); // Load file cấu hình
  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cooking Recipes',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: initialScreen, 
    );
  }
}