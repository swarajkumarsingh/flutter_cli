// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;

class InstallCommand extends Command {
  @override
  final name = "install";

  @override
  final description = "Adds a package to the project";

  @override
  Future<void> run() async {
    // print(argResults!.arguments);
    // print(argParser.usage);
    try {
      await _installPackage(argResults!.arguments.first);
    } catch (e) {
      throw Exception("Package name not specified");
    }
  }

  Future<void> _installPackage(String name) async {
    // Get package version
    final http.Response response = await _getPackageVersion(name);

    // parse response body and retrieve latest version
    final data = json.decode(response.body);
    final String version = data["latest"]["version"];

    // Load current pubspec file
    final pubspec = File("pubspec.yaml").readAsStringSync();

    // insert package and write out new file
    final updatedPubspec = pubspec.replaceFirst(
        "dependencies:", "dependencies:\n  $name: ^$version\n");
    File("pubspec.yaml").writeAsStringSync(updatedPubspec);

    // Update dependencies run pub get
    Process.runSync("dart", ["pub", "get"]);

    print("Installed $name@$version");
  }

  Future<http.Response> _getPackageVersion(String name) async {
    final http.Response response =
        await http.get(Uri.tryParse("https://pub.dev/api/packages/$name")!);
    if (response.statusCode == 404) {
      final data = json.decode(response.body);
      print("""
        Error: ${data["error"]["code"]}
        Message: ${data["error"]["message"]}
        Package name: $name
        """);
      exit(1);
    }
    return response;
  }
}
