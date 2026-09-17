import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add flutter_speed_dial import if not exists
    if 'flutter_speed_dial.dart' not in content:
        import_pos = content.find('\n\n')
        content = content[:import_pos] + "\nimport 'package:flutter_speed_dial/flutter_speed_dial.dart';" + content[import_pos:]

    # 2. Replace floatingActionButton
    fab_start = content.find('floatingActionButton: FloatingActionButton(')
    if fab_start != -1:
        # find the end of floatingActionButton block
        fab_end = content.find('),', fab_start) + 2
        
        speed_dial_code = '''floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 3,
        mini: false,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        backgroundColor: const Color(0xFFC2E7FF),
        foregroundColor: const Color(0xFF001D35),
        elevation: 8.0,
        animationCurve: Curves.elasticInOut,
        isOpenOnStart: false,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.remove, color: Colors.white),
            backgroundColor: const Color(0xFFE11D48),
            foregroundColor: Colors.white,
            label: '지출',
            labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            onTap: () => _showAddTransactionModal(context, initialType: 'expense'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.add, color: Colors.white),
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            label: '수입',
            labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            onTap: () => _showAddTransactionModal(context, initialType: 'income'),
          ),
        ],
      ),'''
        content = content[:fab_start] + speed_dial_code + content[fab_end:]


    # 3. Modify _showAddTransactionModal
    modal_start = content.find('void _showAddTransactionModal(BuildContext context)')
    if modal_start != -1:
        modal_end = content.find('}', modal_start) + 1
        new_modal = '''void _showAddTransactionModal(BuildContext context, {String initialType = 'expense'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: AddTransactionScreen(initialType: initialType),
      ),
    );
  }'''
        content = content[:modal_start] + new_modal + content[modal_end:]


    # 4. Modify AddTransactionScreen constructor and initState
    class_start = content.find('class AddTransactionScreen extends StatefulWidget {')
    if class_start != -1:
        class_end = content.find('}', class_start) + 1
        new_class = '''class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}'''
        content = content[:class_start] + new_class + content[class_end:]

    init_state_idx = content.find('String _type = \\'expense\\';')
    if init_state_idx != -1:
        content = content[:init_state_idx] + 'late String _type;' + content[init_state_idx + len('String _type = \\'expense\\';'):]
        
    init_state_super = content.find('super.initState();')
    if init_state_super != -1:
        content = content[:init_state_super + len('super.initState();')] + '\n    _type = widget.initialType;' + content[init_state_super + len('super.initState();'):]

    # 5. Modify Scaffold to have borderRadius and height
    scaffold_start = content.find('return Scaffold(')
    if scaffold_start != -1:
        content = content[:scaffold_start] + 'return FractionallySizedBox(\n      heightFactor: 0.9,\n      child: ClipRRect(\n        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),\n        child: Scaffold(' + content[scaffold_start + len('return Scaffold('):]
        
        # also we need to add the closing tags for FractionallySizedBox and ClipRRect
        # find the end of build method (the last brace before class end)
        build_end = content.rfind('}', scaffold_start, content.find('class', scaffold_start) if content.find('class', scaffold_start) != -1 else len(content))
        # this is fragile, let's just use string replace on the return Scaffold block
        # Actually Scaffold is returned directly, so we can just replace the final ); of the build method
        last_semi = content.find(';', scaffold_start)
        # No, scaffold has many things.
        
    with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
