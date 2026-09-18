import os

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update onLongPress signature to Function(String) in _accountCheckItem
    old_acc_sig = '''    required bool isAll,
    VoidCallback? onLongPress,'''
    new_acc_sig = '''    required bool isAll,
    Function(String)? onAction,'''
    content = content.replace(old_acc_sig, new_acc_sig)
    
    old_more_broken = '''            if (onLongPress != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                color: const Color(0xFFFFFFFF),
                onSelected: (val) {
                   if (val == 'edit') {
                     // We will hijack onLongPress but pass an action string if we change the signature.
                     // It's easier to just pass the action to onLongPress. Wait, onLongPress is VoidCallback.
                   }
                },
                itemBuilder: (ctx) => [
                ],
              ),'''
    
    # If the python script actually did this replace:
    new_more = '''            if (onAction != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                color: const Color(0xFFFFFFFF),
                onSelected: (val) => onAction(val),
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text('수정', style: GoogleFonts.notoSansKr(fontSize: 13, color: Color(0xFF0F172A)))),
                  PopupMenuItem(value: 'delete', child: Text('삭제', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFFE11D48)))),
                ],
              ),'''
    if old_more_broken in content:
        content = content.replace(old_more_broken, new_more)
    else:
        # If it didn't replace, find the original
        old_more_orig = '''            if (onLongPress != null)
              GestureDetector(
                onTap: onLongPress,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),'''
        content = content.replace(old_more_orig, new_more)

    # 2. Update usage of _accountCheckItem
    # old: onLongPress: () => _showAccountActions(context, state, acc),
    old_usage = '''onLongPress: () => _showAccountActions(context, state, acc),'''
    new_usage = '''onAction: (action) {
                          if (action == 'edit') {
                            _showAddAccountDialog(context, state, editAccount: acc);
                          } else if (action == 'delete') {
                            _showAccountActions(context, state, acc);
                          }
                        },'''
    content = content.replace(old_usage, new_usage)

    with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
