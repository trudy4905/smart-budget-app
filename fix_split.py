import os

def main():
    # Delete state.dart since it's already extracted to models and providers
    if os.path.exists('flutter_app/lib/state.dart'):
        os.remove('flutter_app/lib/state.dart')

    with open('flutter_app/lib/main.dart', 'r', encoding='utf-8') as f:
        main_content = f.read()

    mh_s = main_content.find('class HomeScreen extends StatefulWidget')
    
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
