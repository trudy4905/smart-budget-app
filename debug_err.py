import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    for i, line in enumerate(lines[140:155]):
        print(f"{141+i}: {line}")

if __name__ == '__main__':
    main()
