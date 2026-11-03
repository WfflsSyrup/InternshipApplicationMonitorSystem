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

  test(
    'maps authorization and validation failures to fixed messages',
    () async {
      for (final entry in {
        400: 'Check the information and try again.',
        401: 'Your session has expired. Please sign in again.',
        403: 'You do not have permission to perform this action.',
        422: 'Check the information and try again.',
      }.entries) {
        final service = ApiService(
          client: MockClient(
            (_) async => http.Response(
              '{"message":"database exception: private detail"}',
              entry.key,
            ),
          ),
        );
        addTearDown(service.dispose);

        await expectLater(
          service.getReminders(),
          throwsA(
            isA<ApiException>().having(
              (error) => error.message,
              'safe user message',
              entry.value,
            ),
          ),
        );
      }
    },
  );

  test(
    'clears the token and expires the session on unauthorized response',
    () async {
      var sessionExpired = false;
      final service = ApiService(
        client: MockClient((_) async => http.Response('{}', 401)),
      );
      service
        ..setAccessToken('active-token')
        ..onUnauthorized = () => sessionExpired = true;
      addTearDown(service.dispose);

      await expectLater(service.getReminders(), throwsA(isA<ApiException>()));

      expect(sessionExpired, isTrue);
    },
  );

  test('rejects invalid workflow input before sending a request', () async {
    var requests = 0;
    final service = ApiService(
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.updateWorkflow('not-an-id', stage: 'unrecognized'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'status code',
          400,
        ),
      ),
    );
    expect(requests, 0);
  });
}
