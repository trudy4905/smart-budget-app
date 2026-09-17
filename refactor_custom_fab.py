import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    custom_speed_dial = '''
class CustomSpeedDial extends StatefulWidget {
  final Function(String) onSelect;
  const CustomSpeedDial({super.key, required this.onSelect});

  @override
  State<CustomSpeedDial> createState() => _CustomSpeedDialState();
}

class _CustomSpeedDialState extends State<CustomSpeedDial> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _isOpen = !_isOpen);
  }

  Widget _buildItem(String label, IconData icon, String type) {
    return GestureDetector(
      onTap: () {
        _toggle();
        widget.onSelect(type);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EDFA),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1D4ED8))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizeTransition(
          sizeFactor: _anim,
          axisAlignment: -1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildItem('수입', Icons.download_rounded, 'income'),
              _buildItem('지출', Icons.upload_rounded, 'expense'),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: const Color(0xFF2563EB),
          elevation: 4,
          shape: const CircleBorder(),
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}
'''
    
    # We will insert custom_speed_dial right before class HomeScreen extends StatefulWidget
    home_screen_start = content.find('class HomeScreen extends StatefulWidget')
    content = content[:home_screen_start] + custom_speed_dial + '\n' + content[home_screen_start:]
    
    # We will replace floatingActionButton: SpeedDial( ... ) with floatingActionButton: CustomSpeedDial(...)
    fab_start = content.find('      floatingActionButton: SpeedDial(')
    if fab_start != -1:
        # find the end of SpeedDial block
        # SpeedDial has children: [ ... ]
        # let's just find the end by looking for the next top level widget in Scaffold which might be drawer: or ); 
        # Actually in build method:
        #         ],
        #       ),
        #     );
        #   }
        # We can extract the block exactly
        def get_block_end(text, start):
            paren = text.find('(', start)
            count = 1
            idx = paren + 1
            while count > 0 and idx < len(text):
                if text[idx] == '(': count +=1
                elif text[idx] == ')': count -=1
                idx += 1
            return idx
        
        fab_end = get_block_end(content, fab_start)
        
        new_fab = '''      floatingActionButton: CustomSpeedDial(
        onSelect: (type) => _showAddTransactionModal(context, initialType: type),
      )'''
        content = content[:fab_start] + new_fab + content[fab_end:]
        
        with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Replaced FAB successfully")
    else:
        print("Could not find floatingActionButton: SpeedDial(")

if __name__ == '__main__':
    main()
