import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nelna_maintenance/features/auth/presentation/screens/register_screen.dart';

void main() {
  Widget buildTestable(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('RegisterScreen', () => {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(buildTestable(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone (optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('renders Create Account button', (tester) async {
      await tester.pumpWidget(buildTestable(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(buildTestable(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Find and tap the Create Account FilledButton (not the TextButton)
      final button = find.widgetWithText(FilledButton, 'Create Account');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Last name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(buildTestable(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Fill form with mismatched passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last Name'),
        'User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Str0ng!Pass',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'DifferentPass1!',
      );

      final button = find.widgetWithText(FilledButton, 'Create Account');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows Already have an account link', (tester) async {
      await tester.pumpWidget(buildTestable(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders logo section', (tester) async {
      await tester.pumpWidget(buildTestable(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nelna Maintenance'), findsWidgets);
      expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
    });
  });
}
