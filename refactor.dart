import 'dart:io';

void main() {
  final libDir = r"c:\Users\user\.gemini\antigravity-ide\scratch\smart-budget-app\flutter_app\lib";
  
  final mapping = {
    r"services\storage_service.dart": r"core\services\storage_service.dart",
    r"utils\helpers.dart": r"core\utils\helpers.dart",
    r"providers\app_state.dart": r"core\providers\app_state.dart",
    r"view_models\ui_view_model.dart": r"core\providers\ui_view_model.dart",
    
    r"widgets\drawer\app_drawer.dart": r"features\drawer\views\app_drawer.dart",
    r"widgets\drawer\header\drawer_header.dart": r"features\drawer\views\header\drawer_header.dart",
    r"widgets\drawer\header\widgets\drawer_header_ui.dart": r"features\drawer\views\header\widgets\drawer_header_ui.dart",
    r"widgets\drawer\footer\drawer_footer.dart": r"features\drawer\views\footer\drawer_footer.dart",
    r"widgets\drawer\footer\widgets\drawer_footer_ui.dart": r"features\drawer\views\footer\widgets\drawer_footer_ui.dart",
    
    r"screens\home_screen.dart": r"features\home\views\home_screen.dart",
    
    r"models\transaction.dart": r"features\transactions\models\transaction.dart",
    r"screens\add_transaction\add_transaction_screen.dart": r"features\transactions\views\add_transaction_screen.dart",
    r"screens\add_transaction\widgets\add_transaction_form_ui.dart": r"features\transactions\views\widgets\add_transaction_form_ui.dart",
    r"screens\add_transaction\widgets\date_picker_field.dart": r"features\transactions\views\widgets\date_picker_field.dart",
    r"screens\add_transaction\widgets\amount_input_field.dart": r"features\transactions\views\widgets\amount_input_field.dart",
    r"screens\add_transaction\widgets\save_button.dart": r"features\transactions\views\widgets\save_button.dart",
    
    r"models\account.dart": r"features\accounts\models\account.dart",
    r"widgets\drawer\sections\accounts\accounts_section.dart": r"features\accounts\views\accounts_section.dart",
    r"widgets\drawer\sections\accounts\widgets\account_list_item.dart": r"features\accounts\views\widgets\account_list_item.dart",
    
    r"models\dashboard_summary.dart": r"features\dashboard\models\dashboard_summary.dart",
    r"view_models\dashboard_view_model.dart": r"features\dashboard\view_models\dashboard_view_model.dart",
    r"widgets\drawer\sections\assets\asset_summary_card.dart": r"features\dashboard\views\asset_summary_card.dart",
    r"widgets\drawer\sections\cash_flow\cash_flow_section.dart": r"features\dashboard\views\cash_flow_section.dart",
    r"widgets\drawer\sections\cash_flow\widgets\cash_flow_section_ui.dart": r"features\dashboard\views\widgets\cash_flow_section_ui.dart",
    r"widgets\drawer\sections\cash_flow\expected_asset\expected_asset_card.dart": r"features\dashboard\views\expected_asset_card.dart",
    r"widgets\drawer\sections\cash_flow\expected_asset\widgets\expected_asset_card_ui.dart": r"features\dashboard\views\widgets\expected_asset_card_ui.dart",
    r"widgets\drawer\sections\cash_flow\summary\drawer_side_panel.dart": r"features\dashboard\views\drawer_side_panel.dart",
    r"widgets\drawer\sections\cash_flow\summary\cash_flow_widgets.dart": r"features\dashboard\views\cash_flow_widgets.dart",
    
    r"view_models\recurring_view_model.dart": r"features\recurring\view_models\recurring_view_model.dart",
    r"widgets\drawer\sections\cash_flow\recurring\recurring_expense_section.dart": r"features\recurring\views\recurring_expense_section.dart",
    r"widgets\drawer\sections\cash_flow\recurring\recurring_income_section.dart": r"features\recurring\views\recurring_income_section.dart",
    r"widgets\drawer\sections\cash_flow\recurring\widgets\recurring_expense_section_ui.dart": r"features\recurring\views\widgets\recurring_expense_section_ui.dart",
    r"widgets\drawer\sections\cash_flow\recurring\widgets\recurring_income_section_ui.dart": r"features\recurring\views\widgets\recurring_income_section_ui.dart",
    r"widgets\drawer\sections\cash_flow\recurring\widgets\recurring_item_widget.dart": r"features\recurring\views\widgets\recurring_item_widget.dart",
    
    r"models\category_info.dart": r"features\categories\models\category_info.dart",
    r"view_models\category_view_model.dart": r"features\categories\view_models\category_view_model.dart",
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
  
  basenameToPackagePath['main.dart'] = "package:flutter_app/main.dart";
  
  final dir = Directory(libDir);
  final dartFiles = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in dartFiles) {
    String content = file.readAsStringSync();
    
    final importRegex = RegExp(r"import\s+'([^']+)'");
    final exportRegex = RegExp(r"export\s+'([^']+)'");
    
    content = content.replaceAllMapped(importRegex, (match) {
      final path = match.group(1)!;
      if (path.startsWith('package:') || path.startsWith('dart:')) return match.group(0)!;
      
      final basename = path.split('/').last;
      if (basenameToPackagePath.containsKey(basename)) {
        return "import '${basenameToPackagePath[basename]}'";
      }
      return match.group(0)!;
    });

    content = content.replaceAllMapped(exportRegex, (match) {
      final path = match.group(1)!;
      if (path.startsWith('package:') || path.startsWith('dart:')) return match.group(0)!;
      final basename = path.split('/').last;
      if (basenameToPackagePath.containsKey(basename)) {
        return "export '${basenameToPackagePath[basename]}'";
      }
      return match.group(0)!;
    });

    file.writeAsStringSync(content);
    print("Updated imports in: ${file.path}");
  }
}
