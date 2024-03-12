import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AppStartupErrorWidget extends HookWidget {
  const AppStartupErrorWidget({
    required this.message,
    required this.onRetry,
    required this.stackTrace,
    super.key,
  });
  final String message;
  final StackTrace stackTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final moreInfo = useState(false);

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (moreInfo.value)
                SizedBox(
                  height: 300,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Text(
                          moreInfo.value
                              ? stackTrace.toString()
                              : 'No more info',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => moreInfo.value = !moreInfo.value,
                child: const Text('More Info'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
