import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ciudad o país elegido como destino.
class Destination {
  const Destination({
    required this.name,
    required this.countryCode,
    this.currencyCode,
  });

  /// 'Tokyo, Japan'.
  final String name;

  /// ISO 3166, ej. 'JP'.
  final String countryCode;

  /// Moneda del país según iOS; null si no la conoce.
  final String? currencyCode;
}

/// Buscador de destinos con Apple Maps (MapKit), vía el canal nativo de AppDelegate.swift.
class DestinationRepository {
  static const _channel = MethodChannel('travio/places');

  Future<List<Destination>> search(String query) async {
    final results =
        await _channel.invokeListMethod<Map>('search', {'query': query}) ?? [];
    return [
      for (final r in results)
        Destination(
          name: r['name'] as String,
          countryCode: r['countryCode'] as String,
          currencyCode: r['currencyCode'] as String?,
        ),
    ];
  }
}

final destinationRepositoryProvider = Provider<DestinationRepository>(
  (ref) => DestinationRepository(),
);
