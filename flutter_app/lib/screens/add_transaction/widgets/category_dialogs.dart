import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/category_info.dart';

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)),
      filled: true, fillColor: const Color(0xFFFFFFFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

Future<void> showCategoryOptionsDialog({
  required BuildContext context,
  required CategoryInfo cat,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${cat.emoji} ${cat.name}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF4F46E5)),
            title: Text('수정', style: GoogleFonts.notoSansKr()),
            onTap: () {
              Navigator.pop(ctx);
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Color(0xFFE11D48)),
            title: Text('삭제', style: GoogleFonts.notoSansKr()),
            onTap: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showCategoryEditDialog({
  required BuildContext context,
  required CategoryInfo? cat,
  required void Function(String emoji, String name) onSave,
}) async {
  final emojiCtrl = TextEditingController(text: cat?.emoji ?? '📌');
  final nameCtrl = TextEditingController(text: cat?.name ?? '');

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(cat == null ? '새 카테고리 추가' : '카테고리 수정', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emojiCtrl,
            decoration: _inputDecoration('아이콘 (이모지 1글자)').copyWith(labelText: '아이콘'),
            maxLength: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: _inputDecoration('카테고리 이름').copyWith(labelText: '이름'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
        TextButton(
          onPressed: () {
            final emoji = emojiCtrl.text.trim();
            final name = nameCtrl.text.trim();
            if (emoji.isEmpty || name.isEmpty) return;
            onSave(emoji, name);
            Navigator.pop(ctx);
          },
          child: Text('저장', style: GoogleFonts.notoSansKr(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

Future<void> showCategoryDeleteDialog({
  required BuildContext context,
  required List<CategoryInfo> others,
  required void Function(String? transferToName) onDeleteAndTransfer,
}) async {
  String? selectedTransfer = others.isNotEmpty ? others.first.name : null;

  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('카테고리 삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이 카테고리로 작성된 내역들을 다른 카테고리로 이관하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A))),
            const SizedBox(height: 16),
            if (others.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedTransfer,
                dropdownColor: const Color(0xFFFFFFFF),
                decoration: _inputDecoration('이관할 카테고리'),
                items: others.map((c) => DropdownMenuItem(value: c.name, child: Text('${c.emoji} ${c.name}'))).toList(),
                onChanged: (v) => setDialogState(() => selectedTransfer = v),
              )
            else
              Text('이관할 다른 카테고리가 없습니다.', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
          TextButton(
            onPressed: () {
              onDeleteAndTransfer(selectedTransfer);
              Navigator.pop(ctx);
            },
            child: Text('삭제 및 이관', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
