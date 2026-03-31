import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiak_passenger/core/services/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

