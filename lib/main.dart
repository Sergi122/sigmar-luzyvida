import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://uacxdrzuylhcxkpewzug.supabase.co',
    anonKey: 'sb_publishable_qI7702sYFZuEZZbgQqOlSg_L8zbxHYn',
  );
  runApp(const SigmarApp());
}
