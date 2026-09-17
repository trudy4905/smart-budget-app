import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Change axisAlignment: -1.0 to axisAlignment: 1.0
    content = content.replace('axisAlignment: -1.0,', 'axisAlignment: 1.0,')
    
    # 2. Add Alignment to Column in SizeTransition if needed. It's fine.
    
    # 3. Change FloatingActionButton margin so its center aligns better with the right edge of the pills?
    # Actually, the user's issue "왼쪽 화면에 뜨고 있어" could literally mean it's on the left side of the screen.
    # Let's move it to Stack just to be perfectly safe from Scaffold's FAB placement quirks.
    
    fab_start = content.find('      floatingActionButton: CustomSpeedDial(')
    if fab_start != -1:
        fab_end = content.find(')', fab_start) + 1
        fab_end = content.find(',', fab_end) + 1 # include comma if any
        # remove it from scaffold
        content = content[:fab_start] + content[fab_end:]
        
    body_start = content.find('      body: Consumer<AppState>(')
    if body_start != -1:
        # We wrap body in Stack
        body_end = content.find('      ),', body_start) + 8 # end of Consumer
        # Wait, if we just do string replacement:
        old_body = content[body_start:body_end]
        new_body = '''      body: Stack(
        children: [
          ''' + old_body.replace('      body: ', '') + '''
          Positioned(
            right: 20,
            bottom: 20,
            child: SafeArea(
              child: CustomSpeedDial(
                onSelect: (type) => _showAddTransactionModal(context, initialType: type),
              ),
            ),
          ),
        ],
      ),'''
        content = content[:body_start] + new_body + content[body_end:]

    with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
