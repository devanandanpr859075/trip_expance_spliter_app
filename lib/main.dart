// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage_service.dart';
import 'trip_provider.dart';
import 'screens/trip_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const TripExpenseApp());
}

class TripExpenseApp extends StatelessWidget {
  const TripExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripProvider(),
      child: MaterialApp(
        title: 'Trip Expense Splitter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
        ),
        home: const TripListScreen(),
      ),
    );
  }
}
