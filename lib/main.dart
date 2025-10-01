import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_spy/core/shared/presentation/pages/splash_page.dart';

import 'features/activity/presentation/cubit/activity_cubit.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ActivityCubit>(
          create: (_) => ActivityCubit()..init(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Spy',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
