import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the end of AddTransactionScreen build
    search_str = "            const SizedBox(height: 80),\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _typeTab"
    
    replace_str = "            const SizedBox(height: 80),\n          ],\n        ),\n      ),\n    )));\n  }\n\n  Widget _typeTab"
    
    if search_str in content:
        content = content.replace(search_str, replace_str)
        with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Replaced successfully")
    else:
        print("Could not find string")
        # debug:
        idx = content.find("const SizedBox(height: 80),")
        if idx != -1:
            print("Found nearby text:")
            print(content[idx:idx+150])

if __name__ == '__main__':
    main()
