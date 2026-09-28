import 'dart:io';

void main() {
  final libDir = Directory(r"c:\Users\user\.gemini\antigravity-ide\scratch\smart-budget-app\flutter_app\lib");
  
  final colorMap = {
    '0xFF4F46E5': 'AppColors.primary',
    '0xFF2563EB': 'AppColors.secondary',
    '0xFFF1F5F9': 'AppColors.background',
    '0xFFFFFFFF': 'AppColors.surface',
    '0xFF0F172A': 'AppColors.textMain',
    '0xFF64748B': 'AppColors.textSub',
    '0xFF94A3B8': 'AppColors.textHint',
    '0xFF10B981': 'AppColors.income',
    '0xFFECFDF5': 'AppColors.incomeBg',
    '0xFFE11D48': 'AppColors.expense',
    '0xFFFFF1F2': 'AppColors.expenseBg',
    '0xFFE2E8F0': 'AppColors.divider',
  };

  final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in dartFiles) {
    if (file.path.contains('app_colors.dart') || file.path.contains('app_theme.dart') || file.path.contains('app_text_styles.dart')) continue;

    String content = file.readAsStringSync();
    bool modified = false;

    // Replace const Color(0xFF...)
    colorMap.forEach((hex, replacement) {
      final constRegex = RegExp('const\\s+Color\\($hex\\)');
      if (constRegex.hasMatch(content)) {
        content = content.replaceAll(constRegex, replacement);
        modified = true;
      }
      
      final normalRegex = RegExp('Color\\($hex\\)');
      if (normalRegex.hasMatch(content)) {
        content = content.replaceAll(normalRegex, replacement);
        modified = true;
      }
    });

    if (modified) {
      // Add import if not present
      if (!content.contains('core/theme/app_colors.dart')) {
        // Find the last import
        final lastImportIdx = content.lastIndexOf(RegExp(r"import\s+'[^']+';"));
        if (lastImportIdx != -1) {
          final endOfImport = content.indexOf(';', lastImportIdx) + 1;
          content = content.substring(0, endOfImport) + '\nimport \'package:flutter_app/core/theme/app_colors.dart\';' + content.substring(endOfImport);
        } else {
          content = "import 'package:flutter_app/core/theme/app_colors.dart';\n" + content;
        }
      }
      
      file.writeAsStringSync(content);
      print("Updated colors in: ${file.path}");
    }
  }
}
