import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WaroengKu - Main Page")),
      body: const Center(
        child: Text(
          "Selamat datang di WaroengKu!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
