import os
import re

lib_dir = r"c:\Users\user\.gemini\antigravity-ide\scratch\smart-budget-app\flutter_app\lib"

# Mapping from old path to new path (relative to lib_dir)
mapping = {
    # Core
    r"services\storage_service.dart": r"core\services\storage_service.dart",
    r"utils\helpers.dart": r"core\utils\helpers.dart",
    r"providers\app_state.dart": r"core\providers\app_state.dart",
    r"view_models\ui_view_model.dart": r"core\providers\ui_view_model.dart",
    
    # Drawer
    r"widgets\drawer\app_drawer.dart": r"features\drawer\views\app_drawer.dart",
    r"widgets\drawer\header\drawer_header.dart": r"features\drawer\views\header\drawer_header.dart",
    r"widgets\drawer\header\widgets\drawer_header_ui.dart": r"features\drawer\views\header\widgets\drawer_header_ui.dart",
    r"widgets\drawer\footer\drawer_footer.dart": r"features\drawer\views\footer\drawer_footer.dart",
    r"widgets\drawer\footer\widgets\drawer_footer_ui.dart": r"features\drawer\views\footer\widgets\drawer_footer_ui.dart",
    
    # Home
    r"screens\home_screen.dart": r"features\home\views\home_screen.dart",
    
    # Transactions
    r"models\transaction.dart": r"features\transactions\models\transaction.dart",
    r"screens\add_transaction\add_transaction_screen.dart": r"features\transactions\views\add_transaction_screen.dart",
    r"screens\add_transaction\widgets\add_transaction_form_ui.dart": r"features\transactions\views\widgets\add_transaction_form_ui.dart",
    r"screens\add_transaction\widgets\date_picker_field.dart": r"features\transactions\views\widgets\date_picker_field.dart",
    r"screens\add_transaction\widgets\amount_input_field.dart": r"features\transactions\views\widgets\amount_input_field.dart",
    r"screens\add_transaction\widgets\save_button.dart": r"features\transactions\views\widgets\save_button.dart",
    
    # Accounts
    r"models\account.dart": r"features\accounts\models\account.dart",
    r"widgets\drawer\sections\accounts\accounts_section.dart": r"features\accounts\views\accounts_section.dart",
    r"widgets\drawer\sections\accounts\widgets\account_list_item.dart": r"features\accounts\views\widgets\account_list_item.dart",
    
    # Dashboard
    r"models\dashboard_summary.dart": r"features\dashboard\models\dashboard_summary.dart",
    r"view_models\dashboard_view_model.dart": r"features\dashboard\view_models\dashboard_view_model.dart",
    r"widgets\drawer\sections\assets\asset_summary_card.dart": r"features\dashboard\views\asset_summary_card.dart",
    r"widgets\drawer\sections\cash_flow\cash_flow_section.dart": r"features\dashboard\views\cash_flow_section.dart",
    r"widgets\drawer\sections\cash_flow\widgets\cash_flow_section_ui.dart": r"features\dashboard\views\widgets\cash_flow_section_ui.dart",
    r"widgets\drawer\sections\cash_flow\expected_asset\expected_asset_card.dart": r"features\dashboard\views\expected_asset_card.dart",
    r"widgets\drawer\sections\cash_flow\expected_asset\widgets\expected_asset_card_ui.dart": r"features\dashboard\views\widgets\expected_asset_card_ui.dart",
    r"widgets\drawer\sections\cash_flow\summary\drawer_side_panel.dart": r"features\dashboard\views\drawer_side_panel.dart",
    r"widgets\drawer\sections\cash_flow\summary\cash_flow_widgets.dart": r"features\dashboard\views\cash_flow_widgets.dart",
    
    # Recurring
    r"view_models\recurring_view_model.dart": r"features\recurring\view_models\recurring_view_model.dart",
    r"widgets\drawer\sections\cash_flow\recurring\recurring_expense_section.dart": r"features\recurring\views\recurring_expense_section.dart",
    r"widgets\drawer\sections\cash_flow\recurring\recurring_income_section.dart": r"features\recurring\views\recurring_income_section.dart",
    r"widgets\drawer\sections\cash_flow\recurring\widgets\recurring_expense_section_ui.dart": r"features\recurring\views\widgets\recurring_expense_section_ui.dart",
    r"widgets\drawer\sections\cash_flow\recurring\widgets\recurring_income_section_ui.dart": r"features\recurring\views\widgets\recurring_income_section_ui.dart",
    r"widgets\drawer\sections\cash_flow\recurring\widgets\recurring_item_widget.dart": r"features\recurring\views\widgets\recurring_item_widget.dart",
    
    # Categories
    r"models\category_info.dart": r"features\categories\models\category_info.dart",
    r"view_models\category_view_model.dart": r"features\categories\view_models\category_view_model.dart",
}

# 1. Create directories and move files
old_to_new_abs = {}
for old_rel, new_rel in mapping.items():
    old_abs = os.path.join(lib_dir, old_rel)
    new_abs = os.path.join(lib_dir, new_rel)
    old_to_new_abs[old_abs] = new_abs

    if os.path.exists(old_abs):
        os.makedirs(os.path.dirname(new_abs), exist_ok=True)
        os.rename(old_abs, new_abs)
        print(f"Moved: {old_rel} -> {new_rel}")
    else:
        print(f"Warning: {old_abs} not found")

# 2. Update imports in all files in lib/
# We convert all local imports to package:flutter_app/... absolute imports

# Create a mapping of basename to new package path
basename_to_package_path = {}
for old_rel, new_rel in mapping.items():
    basename = os.path.basename(new_rel)
    # Convert windows path to posix path for import
    posix_path = new_rel.replace('\\', '/')
    basename_to_package_path[basename] = f"package:flutter_app/{posix_path}"

# Special case for main.dart which is not moved
basename_to_package_path['main.dart'] = "package:flutter_app/main.dart"

def replace_import(match):
    import_path = match.group(1)
    # If it's already a package import or dart import, leave it
    if import_path.startswith('package:') or import_path.startswith('dart:'):
        return match.group(0)
    
    basename = os.path.basename(import_path)
    if basename in basename_to_package_path:
        new_import = f"import '{basename_to_package_path[basename]}';"
        return new_import
    return match.group(0) # Unchanged

def process_exports(match):
    export_path = match.group(1)
    basename = os.path.basename(export_path)
    if basename in basename_to_package_path:
        return f"export '{basename_to_package_path[basename]}';"
    return match.group(0)

# Walk through all dart files
for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace imports
            new_content = re.sub(r"import\s+'([^']+)'\s*;", replace_import, content)
            # Replace exports (like export '../models/dashboard_summary.dart')
            new_content = re.sub(r"export\s+'([^']+)'\s*;", process_exports, new_content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated imports in: {filepath}")

# Clean up empty directories
for root, dirs, files in os.walk(lib_dir, topdown=False):
    for dir in dirs:
        dir_path = os.path.join(root, dir)
        try:
            os.rmdir(dir_path)
        except OSError:
            pass # Not empty
