import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    idx = content.find('Widget _drawerFilterItem')
    if idx != -1:
        print(content[idx:idx+1000])

if __name__ == '__main__':
    main()
