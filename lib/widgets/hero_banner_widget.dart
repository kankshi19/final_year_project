import 'package:flutter/material.dart';

class HeroBannerWidget extends StatelessWidget {
  const HeroBannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image:NetworkImage('https://pics.craiyon.com/2024-09-08/d2XSxmz-T3CR8G8cUj4iMA.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'We have to end Violence',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
