import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get bodyMain => GoogleFonts.notoSansKr(
        color: AppColors.textMain,
        fontSize: 14,
      );

  static TextStyle get bodySub => GoogleFonts.notoSansKr(
        color: AppColors.textSub,
        fontSize: 12,
      );

  static TextStyle get title => GoogleFonts.notoSansKr(
        color: AppColors.textMain,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get header => GoogleFonts.notoSansKr(
        color: AppColors.textMain,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );
}
