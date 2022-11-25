import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:logging/logging.dart' as logging;
import 'package:super_editor/super_editor.dart';

void groupWithLogging(String description, Level logLevel, Set<logging.Logger> loggers, VoidCallback body) {
  initLoggers(logLevel, loggers);

  group(description, body);

  deactivateLoggers(loggers);
}

/// A widget test that runs a variant for every desktop platform, e.g.,
/// Mac, Windows, Linux, and for all [DocumentInputSource]s.
void testAllInputsOnDesktop(
  String description,
  InputModeTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnDesktop("$description (keyboard)", (WidgetTester tester) async {
    await test(tester, inputSource: DocumentInputSource.keyboard);
  }, skip: skip);

  testWidgetsOnDesktop("$description (IME)", (WidgetTester tester) async {
    await test(tester, inputSource: DocumentInputSource.ime);
  }, skip: skip);
}

/// A widget test that runs as a Mac, and for all [DocumentInputSource]s.
void testAllInputsOnMac(
  String description,
  InputModeTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnMac("$description (keyboard)", (WidgetTester tester) async {
    await test(tester, inputSource: DocumentInputSource.keyboard);
  }, skip: skip);

  testWidgetsOnMac("$description (IME)", (WidgetTester tester) async {
    await test(tester, inputSource: DocumentInputSource.ime);
  }, skip: skip);
}

/// A widget test that runs a variant for Windows and Linux, and for all [DocumentInputSource]s.
void testAllInputsOnWindowsAndLinux(
  String description,
  InputModeTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnWindowsAndLinux("$description (keyboard)", (WidgetTester tester) async {
    await test(tester, inputSource: DocumentInputSource.keyboard);
  }, skip: skip);

  testWidgetsOnWindowsAndLinux("$description (IME)", (WidgetTester tester) async {
    await test(tester, inputSource: DocumentInputSource.ime);
  }, skip: skip);
}

typedef InputModeTesterCallback = Future<void> Function(
  WidgetTester widgetTester, {
  required DocumentInputSource inputSource,
});

/// A widget test that runs a variant for every desktop platform, e.g.,
/// Mac, Windows, Linux.
void testWidgetsOnDesktop(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnMac("$description (on MAC)", test, skip: skip);
  testWidgetsOnWindows("$description (on Windows)", test, skip: skip);
  testWidgetsOnLinux("$description (on Linux)", test, skip: skip);
}

/// A widget test that runs a variant for every mobile platform, e.g.,
/// Android and iOS
void testWidgetsOnMobile(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnAndroid("$description (on Android)", test, skip: skip);
  testWidgetsOnIos("$description (on iOS)", test, skip: skip);
}

/// A widget test that runs a variant for every platform, e.g.,
/// Mac, Windows, Linux, Android and iOS.
void testWidgetsOnAllPlatforms(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnMac("$description (on MAC)", test, skip: skip);
  testWidgetsOnWindows("$description (on Windows)", test, skip: skip);
  testWidgetsOnLinux("$description (on Linux)", test, skip: skip);
  testWidgetsOnAndroid("$description (on Android)", test, skip: skip);
  testWidgetsOnIos("$description (on iOS)", test, skip: skip);
}

/// A widget test that runs a variant for Windows and Linux.
///
/// This test method exists because many keyboard shortcuts are identical
/// between Windows and Linux. It would be superfluous to replicate so
/// many shortcut tests. Instead, this test method runs the given [test]
/// with a simulated Windows and Linux platform.
void testWidgetsOnWindowsAndLinux(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnWindows("$description (on Windows)", test, skip: skip);
  testWidgetsOnLinux("$description (on Linux)", test, skip: skip);
}

/// A widget test that configures itself for an arbitrary desktop environment.
///
/// There's no guarantee which desktop environment is used. The purpose of this
/// test method is to cause all relevant configurations to setup for desktop,
/// without concern for any features that change between desktop platforms.
void testWidgetsOnArbitraryDesktop(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgetsOnMac(description, test, skip: skip);
}

/// A widget test that configures itself as a Mac platform before executing the
/// given [test], and nullifies the Mac configuration when the test is done.
void testWidgetsOnMac(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    tester.binding.window
      ..devicePixelRatioTestValue = 1.0
      ..platformDispatcher.textScaleFactorTestValue = 1.0;

    try {
      await test(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}

/// A Dart test that configures the [Platform] to think its a [MacPlatform],
/// then runs the [realTest], and then sets the [Platform] back to null.
///
/// [testOnMac] should only be used for unit tests and component tests that
/// care about the platform. In general, platform-specific behavior comes from
/// the widget tree, which should be tested with [testWidgetsOnMac]. In the
/// rare cases where a specific object, handler, or subsystem needs to be tested
/// in isolation, and it cares about the platform, you can use this test method.
void testOnMac(
  String description,
  VoidCallback realTest, {
  bool skip = false,
}) {
  test(description, () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      realTest();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}

/// A widget test that configures itself as a Windows platform before executing the
/// given [test], and nullifies the Windows configuration when the test is done.
void testWidgetsOnWindows(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    tester.binding.window
      ..devicePixelRatioTestValue = 1.0
      ..platformDispatcher.textScaleFactorTestValue = 1.0;

    try {
      await test(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}

/// A Dart test that configures the [Platform] to think its a [WindowsPlatform],
/// then runs the [realTest], and then sets the [Platform] back to null.
///
/// [testOnWindows] should only be used for unit tests and component tests that
/// care about the platform. In general, platform-specific behavior comes from
/// the widget tree, which should be tested with [testWidgetsOnWindows]. In the
/// rare cases where a specific object, handler, or subsystem needs to be tested
/// in isolation, and it cares about the platform, you can use this test method.
void testOnWindows(
  String description,
  VoidCallback realTest, {
  bool skip = false,
}) {
  test(description, () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      realTest();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}

/// A widget test that configures itself as a Linux platform before executing the
/// given [test], and nullifies the Linux configuration when the test is done.
void testWidgetsOnLinux(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    tester.binding.window
      ..devicePixelRatioTestValue = 1.0
      ..platformDispatcher.textScaleFactorTestValue = 1.0;

    try {
      await test(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}

/// A Dart test that configures the [Platform] to think its a [LinuxPlatform],
/// then runs the [realTest], and then sets the [Platform] back to null.
///
/// [testOnLinux] should only be used for unit tests and component tests that
/// care about the platform. In general, platform-specific behavior comes from
/// the widget tree, which should be tested with [testWidgetsOnLinux]. In the
/// rare cases where a specific object, handler, or subsystem needs to be tested
/// in isolation, and it cares about the platform, you can use this test method.
void testOnLinux(
  String description,
  VoidCallback realTest, {
  bool skip = false,
}) {
  test(description, () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      realTest();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}

/// A widget test that configures itself as a Android platform before executing the
/// given [test], and nullifies the Android configuration when the test is done.
void testWidgetsOnAndroid(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await test(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}

/// A widget test that configures itself as a iOS platform before executing the
/// given [test], and nullifies the iOS configuration when the test is done.
void testWidgetsOnIos(
  String description,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await test(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: skip);
}
