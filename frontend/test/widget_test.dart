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
      client: MockClient((_) async => http.Response(jsonEncode([]), 200)),
    );

    await tester.pumpWidget(InternshipMonitorApp(apiService: service));
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
  });
}
