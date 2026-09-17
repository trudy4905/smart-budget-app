import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    home_build = content.find('Widget build(BuildContext context) {', content.find('class _HomeScreenState extends State<HomeScreen>'))
    if home_build != -1:
        print(content[home_build:home_build+1000])

if __name__ == '__main__':
    main()
