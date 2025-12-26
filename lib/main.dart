import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/presentation/widget/app.dart';
import 'package:my_app/core/cubit/news_cubit.dart';
import 'package:my_app/core/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // Initialize news cubit
  final newsCubit = NewsCubit();
  await newsCubit.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        BlocProvider.value(value: newsCubit),
      ],
      child: const MyApp(),
    ),
  );
}
