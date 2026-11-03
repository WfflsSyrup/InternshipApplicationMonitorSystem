import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internship_monitor/main.dart';
import 'package:internship_monitor/screens/workflow/workflow_overview_screen.dart';
import 'package:internship_monitor/services/api_service.dart';

void main() {
  testWidgets('dashboard presents production copy and opens workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = ApiService(
      client: MockClient((request) async {
        if (request.url.path == '/api/login') {
          return http.Response(
            jsonEncode({
              'token': 'one-time-test-token',
              'user': {
                'id': 12,
                'name': 'Test Coordinator',
                'role': 'coordinator',
              },
            }),
            200,
          );
        }
        expect(request.headers['Authorization'], 'Bearer one-time-test-token');
        return http.Response(jsonEncode([]), 200);
      }),
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(InternshipMonitorApp(apiService: service));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'coordinator@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret-password');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Placement operations'), findsOneWidget);
    expect(find.text('This week at a glance'), findsOneWidget);
    expect(find.text('Counter'), findsNothing);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .debugShowCheckedModeBanner,
      isFalse,
    );

    await tester.ensureVisible(find.text('Application workflow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Application workflow'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkflowOverviewScreen), findsOneWidget);
    expect(find.text('No applications yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('student login routes to own applications, not operations', (
    tester,
  ) async {
    final service = ApiService(
      client: MockClient((request) async {
        if (request.url.path == '/api/login') {
          return http.Response(
            jsonEncode({
              'token': 'student-test-token',
              'user': {'id': 42, 'name': 'Student', 'role': 'student'},
            }),
            200,
          );
        }
        return http.Response(jsonEncode([]), 200);
      }),
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(InternshipMonitorApp(apiService: service));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('My applications'), findsOneWidget);
    expect(find.text('Placement operations'), findsNothing);
  });
}
