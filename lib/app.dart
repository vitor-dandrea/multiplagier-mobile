import 'package:flutter/material.dart';

import 'core/theme.dart';

class MultiplagierApp extends StatelessWidget {
  const MultiplagierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplagier',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Text('Multiplagier', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
