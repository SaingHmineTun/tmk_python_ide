import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmk_python_ide/features/programs/file_create_dialog.dart';
import 'package:tmk_python_ide/features/programs/program_name_dialog.dart';
import 'package:tmk_python_ide/features/programs/project_name_dialog.dart';
import 'package:tmk_python_ide/features/settings/about_developer_screen.dart';

void main() {
  testWidgets('save-name dialog validates and normalizes .py names', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showProgramNameDialog(
                  context,
                  title: 'Save program',
                  actionLabel: 'Save',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a program name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello.py');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, 'hello');
    expect(tester.takeException(), isNull);
  });

  testWidgets('project-name dialog validates empty names', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showProjectNameDialog(
                  context,
                  title: 'Create project',
                  actionLabel: 'Create',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.text('Enter a name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'My Calculator');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(result, 'My Calculator');
    expect(tester.takeException(), isNull);
  });

  testWidgets('file-create dialog returns the name and an optional folder', (
    tester,
  ) async {
    ({String name, String folder})? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showFileCreateDialog(
                  context,
                  title: 'Create Python file',
                  actionLabel: 'Create',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.text('Enter a file name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'geometry.py');
    await tester.enterText(find.byType(TextField).last, 'math/');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(result, (name: 'geometry', folder: 'math'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('about developer page includes bilingual attribution', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutDeveloperScreen()));
    expect(find.text('Python IDE'), findsOneWidget);
    expect(find.text('Sai Mao'), findsOneWidget);
    expect(find.text('ၸၢႆးမၢဝ်း'), findsOneWidget);
    expect(find.text('TMK Group'), findsOneWidget);
    expect(find.text('O2K School'), findsOneWidget);
    expect(find.text('IN COLLABORATION WITH'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));
  });
}
