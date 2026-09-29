import 'dart:io';

void main() {
  final basePath = r"c:\Users\user\.gemini\antigravity-ide\scratch\smart-budget-app\flutter_app\lib\features";
  
  // Define moves: from -> to
  final moves = {
    'transactions': 'home/add_transaction',
    'dashboard': 'drawer/dashboard',
    'accounts': 'drawer/accounts',
    'recurring': 'drawer/recurring',
  };

  // 1. Move folders
  moves.forEach((oldName, newName) {
    final oldDir = Directory('$basePath\\$oldName');
    final newDir = Directory('$basePath\\$newName');
    
    if (oldDir.existsSync()) {
      if (!newDir.parent.existsSync()) {
        newDir.parent.createSync(recursive: true);
      }
      oldDir.renameSync(newDir.path);
      print("Moved $oldName to $newName");
    }
  });

  // 2. Update imports
  final libDir = Directory(r"c:\Users\user\.gemini\antigravity-ide\scratch\smart-budget-app\flutter_app\lib");
  final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    String content = file.readAsStringSync();
    bool modified = false;

    moves.forEach((oldName, newName) {
      final oldImport = 'package:flutter_app/features/$oldName/';
      final newImport = 'package:flutter_app/features/$newName/';
      
      if (content.contains(oldImport)) {
        content = content.replaceAll(oldImport, newImport);
        modified = true;
      }
    });

    if (modified) {
      file.writeAsStringSync(content);
      print("Updated imports in: ${file.path}");
    }
  }
}
