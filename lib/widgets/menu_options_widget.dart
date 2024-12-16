import 'package:flutter/material.dart';

class MenuOptionsWidget extends StatelessWidget {
  const MenuOptionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.warning, color: Colors.orangeAccent),
          title: const Text('Emergency Contacts'),
          onTap: () => Navigator.pushNamed(context, '/emergency'),
        ),
        ListTile(
          leading: const Icon(Icons.book, color: Colors.blueAccent),
          title: const Text('Safety Tips'),
          onTap: () => Navigator.pushNamed(context, '/safety-tips'),
        ),
        ListTile(
          leading: const Icon(Icons.favorite, color: Colors.redAccent),
          title: const Text('Heart Rate Monitor'),
          onTap: () => Navigator.pushNamed(context, '/heart-monitor'),
        ),
      ],
    );
  }
}
