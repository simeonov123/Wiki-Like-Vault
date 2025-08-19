import 'package:flutter/material.dart';

class HomeMessageBody extends StatelessWidget {
  const HomeMessageBody({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          '',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      );
}
