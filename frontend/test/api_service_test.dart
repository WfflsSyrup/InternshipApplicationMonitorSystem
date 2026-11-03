import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internship_monitor/services/api_service.dart';

void main() {
  test(
    'retries a transient server failure and returns the recovered response',
    () async {
      var requests = 0;
      final service = ApiService(
        client: MockClient((request) async {
          requests++;
          expect(request.url.path, '/api/automation/reminders');
          if (requests == 1) {
            return http.Response('{"message":"Try again"}', 503);
          }
          return http.Response(jsonEncode([]), 200);
        }),
      );
      addTearDown(service.dispose);

      final reminders = await service.getReminders();

      expect(reminders, isEmpty);
      expect(requests, 2);
    },
  );

  test('does not retry a permanent business-rule response', () async {
    var requests = 0;
    final service = ApiService(
      client: MockClient((_) async {
        requests++;
        return http.Response(
          '{"message":"Resolve outstanding requirements."}',
          422,
        );
      }),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.getReminders(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status code', 422)
            .having(
              (error) => error.isBusinessRuleFailure,
              'business rule failure',
              isTrue,
            ),
      ),
    );
    expect(requests, 1);
  });
}
