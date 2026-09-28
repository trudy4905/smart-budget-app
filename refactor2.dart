import 'dart:io';

void main() {
  final libDir = r"c:\Users\user\.gemini\antigravity-ide\scratch\smart-budget-app\flutter_app\lib";
  
  final mapping = {
    // Leftover Accounts
    r"widgets\drawer\sections\accounts\add_account_sheet\add_account_sheet.dart": r"features\accounts\views\add_account_sheet\add_account_sheet.dart",
    r"widgets\drawer\sections\accounts\add_account_sheet\constants\account_constants.dart": r"features\accounts\views\add_account_sheet\constants\account_constants.dart",
    r"widgets\drawer\sections\accounts\add_account_sheet\widgets\add_account_sheet_ui.dart": r"features\accounts\views\add_account_sheet\widgets\add_account_sheet_ui.dart",
    r"widgets\drawer\sections\accounts\widgets\accounts_section_ui.dart": r"features\accounts\views\widgets\accounts_section_ui.dart",
    
    // Leftover Dashboard
    r"widgets\drawer\sections\assets\widgets\asset_summary_card_ui.dart": r"features\dashboard\views\widgets\asset_summary_card_ui.dart",
    
    // Leftover Home
    r"widgets\home\calendar_grid.dart": r"features\home\views\widgets\calendar_grid.dart",
    r"widgets\home\custom_speed_dial.dart": r"features\home\views\widgets\custom_speed_dial.dart",
    r"widgets\home\daily_detail.dart": r"features\home\views\widgets\daily_detail.dart",
    r"widgets\home\month_carousel.dart": r"features\home\views\widgets\month_carousel.dart",
    
    // Leftover Transactions
    r"screens\add_transaction\widgets\category_dialogs.dart": r"features\transactions\views\widgets\category_dialogs.dart",
  };

  final basenameToPackagePath = <String, String>{};
  
  mapping.forEach((oldRel, newRel) {
    final oldAbs = "$libDir\\$oldRel";
    final newAbs = "$libDir\\$newRel";
    
    final file = File(oldAbs);
    if (file.existsSync()) {
      final newFile = File(newAbs);
      newFile.parent.createSync(recursive: true);
      file.renameSync(newAbs);
      print("Moved: $oldRel -> $newRel");
    }
    
    final basename = newRel.split('\\').last;
    final posixPath = newRel.replaceAll('\\', '/');
    basenameToPackagePath[basename] = "package:flutter_app/$posixPath";
  });
  
  final dir = Directory(libDir);
  final dartFiles = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in dartFiles) {
    String content = file.readAsStringSync();
    
    final importRegex = RegExp(r"import\s+'([^']+)'");
    
    content = content.replaceAllMapped(importRegex, (match) {
      final path = match.group(1)!;
      if (path.startsWith('package:') || path.startsWith('dart:')) return match.group(0)!;
      
      final basename = path.split('/').last;
      if (basenameToPackagePath.containsKey(basename)) {
        return "import '${basenameToPackagePath[basename]}'";
      }
      return match.group(0)!;
    });

    file.writeAsStringSync(content);
    print("Updated imports in: ${file.path}");
  }
}
