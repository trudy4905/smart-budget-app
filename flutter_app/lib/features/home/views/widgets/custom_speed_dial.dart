import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          axisAlignment: 1.0,
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
