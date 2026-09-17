import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    for i, line in enumerate(lines[1480:1505]):
        print(f"{1480+i}: {line}")

if __name__ == '__main__':
    main()
