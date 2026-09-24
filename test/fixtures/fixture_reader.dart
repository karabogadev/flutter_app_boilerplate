import 'dart:io';

/// Reads JSON fixtures from the fixtures folder for testing
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();
