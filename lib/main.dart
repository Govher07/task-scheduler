import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zliszsklpqmwspinrioc.supabase.co',
    anonKey: 'sb_publishable_cGLlMC9xIn3G6ES3qGVgiw_wc4BscVF',
  );

  runApp(const ProviderScope(child: TaskSchedulerApp()));
}
