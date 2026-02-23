import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nelna_maintenance/features/auth/presentation/screens/login_screen.dart';
import 'package:nelna_maintenance/features/auth/presentation/providers/auth_provider.dart';
import 'package:nelna_maintenance/features/auth/presentation/widgets/auth_text_field.dart';

void main() {
  // Helper to wrap a widget in MaterialApp + ProviderScope
  Widget buildTestable(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildTestable(const LoginScreen()));
      await tester.pumpAndSettle();

      // Should show email and password text fields
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders sign-in button', (tester) async {
      await tester.pumpWidget(buildTestable(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(buildTestable(const LoginScreen()));
      await tester.pumpAndSettle();

      // Tap the Sign In button without filling fields
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should show validation messages
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows email validation error for invalid format',
        (tester) async {
      await tester.pumpWidget(buildTestable(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'notanemail',
      );
      // Enter valid password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows password minimum length error', (tester) async {
      await tester.pumpWidget(buildTestable(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '12345',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('renders Create Account link', (tester) async {
      await tester.pumpWidget(buildTestable(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('renders app name', (tester) async {
      await tester.pumpWidget(buildTestable(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nelna Maintenance'), findsWidgets);
    });
  });

  group('AuthTextField', () {
    testWidgets('renders label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: TextEditingController(),
              label: 'Test Label',
              hint: 'Enter value',
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: TextEditingController(),
              label: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      // Initially obscured — visibility icon should be present
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap to toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now should show "hide" icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('shows prefix icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: TextEditingController(),
              label: 'Email',
              prefixIcon: Icons.email_outlined,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });
  });
}
