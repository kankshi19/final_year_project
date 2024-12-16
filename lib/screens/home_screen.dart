import 'package:flutter/material.dart';
import '../widgets/hero_banner_widget.dart';
import '../widgets/menu_options_widget.dart';
import '../widgets/bottom_navbar_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('We\'ll help you\nIn any way we can'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HeroBannerWidget(),
            MenuOptionsWidget(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
