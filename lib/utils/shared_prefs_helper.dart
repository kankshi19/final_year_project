import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static Future<void> saveSelectedChild(String childId, String childName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_child_id', childId);
    await prefs.setString('selected_child_name', childName);
    print("DEBUG: Saved Child ID -> $childId");
    print("DEBUG: Saved Child Name -> $childName");
  }

  static Future<String?> getSelectedChildId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selected_child_id');
    print("DEBUG: Retrieved Child ID from SharedPreferences -> $id");
    return id;
  }

  static Future<String?> getSelectedChildName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('selected_child_name');
    print("DEBUG: Retrieved Child Name from SharedPreferences -> $name");
    return name;
  }
}
