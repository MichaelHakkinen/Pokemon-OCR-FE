import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent card aspect ratio scanning
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PokemonOcrApp());
}

class PokemonOcrApp extends StatelessWidget {
  const PokemonOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Card Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B53BA), // Pokémon Great Ball Blue
          primary: const Color(0xFF1B53BA),
          secondary: const Color(0xFFFFCB05), // Pokémon Yellow
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const ScannerScreen(),
    );
  }
}

