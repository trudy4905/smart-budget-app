import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find this exact block
    search_str = '''              ],
            ),
          Positioned('''
    
    replace_str = '''              ],
            ),
          );
        },
      ),
      Positioned('''
      
    if search_str in content:
        content = content.replace(search_str, replace_str)
        with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Fixed successfully")
    else:
        print("Not found")

if __name__ == '__main__':
    main()
