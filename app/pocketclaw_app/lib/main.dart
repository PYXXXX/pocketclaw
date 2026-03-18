import 'package:flutter/material.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

void main() {
  runApp(const PocketClawApp());
}

class PocketClawApp extends StatelessWidget {
  const PocketClawApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionKey = SessionKey.forClient(agentId: 'main', clientKey: 'pc-home');

    return MaterialApp(
      title: 'PocketClaw',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: PocketClawHome(sessionKey: sessionKey.value),
    );
  }
}

class PocketClawHome extends StatelessWidget {
  const PocketClawHome({super.key, required this.sessionKey});

  final String sessionKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketClaw'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone-first OpenClaw client scaffold',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Current session key: $sessionKey'),
            const SizedBox(height: 24),
            const Text(
              'Next implementation targets:'
              '\n- Gateway transport'
              '\n- Pairing/auth flow'
              '\n- Session switching'
              '\n- Chat timeline and tool stream rendering',
            ),
          ],
        ),
      ),
    );
  }
}
