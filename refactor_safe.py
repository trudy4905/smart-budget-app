import os
import subprocess

def main():
    os.makedirs('flutter_app/lib/models', exist_ok=True)
    os.makedirs('flutter_app/lib/providers', exist_ok=True)
    os.makedirs('flutter_app/lib/screens', exist_ok=True)
    os.makedirs('flutter_app/lib/utils', exist_ok=True)
    os.makedirs('flutter_app/lib/widgets', exist_ok=True)
    
    with open('flutter_app/lib/state.dart', 'r', encoding='utf-8') as f:
        state_content = f.read()

    # CategoryInfo
    c_s = state_content.find('class CategoryInfo')
    c_e = state_content.find('// DATA MODELS')
    with open('flutter_app/lib/models/category_info.dart', 'w', encoding='utf-8') as f:
        f.write("import 'package:flutter/material.dart';\n\n" + state_content[c_s:c_e].strip() + "\n")

    # Account
    a_s = state_content.find('class Account')
    a_e = state_content.find('class Transaction')
    with open('flutter_app/lib/models/account.dart', 'w', encoding='utf-8') as f:
        f.write(state_content[a_s:a_e].strip() + "\n")

    # Transaction
    t_s = state_content.find('class Transaction')
    t_e = state_content.find('// STATE MANAGEMENT', t_s)
    if t_e == -1: t_e = state_content.find('class AppState', t_s)
    with open('flutter_app/lib/models/transaction.dart', 'w', encoding='utf-8') as f:
        f.write(state_content[t_s:t_e].strip() + "\n")

    # AppState
    as_s = state_content.find('class AppState')
    as_e = state_content.find('// Extension helper', as_s)
    imports = '''import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category_info.dart';
import '../utils/helpers.dart';

const kStorageKeyTx = 'smart_budget_transactions_v5.0';
const kStorageKeyAcc = 'smart_budget_accounts_v5.0';
const kStorageKeyRec = 'smart_budget_recurring_v5.0';
'''
    with open('flutter_app/lib/providers/app_state.dart', 'w', encoding='utf-8') as f:
        f.write(imports + "\n" + state_content[as_s:as_e].strip() + "\n")

    # Helpers
    h_s = state_content.find('// Extension helper')
    with open('flutter_app/lib/utils/helpers.dart', 'w', encoding='utf-8') as f:
        f.write("import 'package:flutter/material.dart';\n\n" + state_content[h_s:].strip() + "\n")

    # Delete state.dart
    os.remove('flutter_app/lib/state.dart')

    # Main.dart split
    with open('flutter_app/lib/main.dart', 'r', encoding='utf-8') as f:
        main_content = f.read()

    mh_s = main_content.find('class MyHomePage extends StatefulWidget')
    
    # fix state.dart import in main.dart
    main_head = main_content[:mh_s].replace("import 'state.dart';", "import 'providers/app_state.dart';\nimport 'screens/home_screen.dart';")
    
    with open('flutter_app/lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(main_head)
        
    home_imports = '''import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category_info.dart';
import '../utils/helpers.dart';
'''
    with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(home_imports + "\n" + main_content[mh_s:])

if __name__ == '__main__':
    main()
