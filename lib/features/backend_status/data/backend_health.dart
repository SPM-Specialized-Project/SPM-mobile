class BackendHealth {
  const BackendHealth({required this.ok, required this.service});

  final bool ok;
  final String service;

  factory BackendHealth.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'];
    final service = json['service'];

    if (ok is! bool || service is! String) {
      throw const FormatException(
        'Backend health response has an unexpected shape.',
      );
    }

    return BackendHealth(ok: ok, service: service);
  }
}
