import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find AddTransactionScreen build method
    # It returns FractionallySizedBox( ... Scaffold( ... ) 
    # We need to find the matching ); for the return statement, which is right before the end of the build method
    
    # We can just look for the end of the AddTransactionScreenState class which is at the end of the file
    # Let's see the last 20 lines of the file.
    lines = content.split('\n')
    for i, line in enumerate(lines[-20:]):
        print(f"{len(lines)-20+i}: {line}")

if __name__ == '__main__':
    main()
