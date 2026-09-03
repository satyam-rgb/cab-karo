import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class TextStyles {
  static final largeText = GoogleFonts.inter(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: AppPallete.secondaryColor);

  static final mediumText =
      GoogleFonts.inter(fontSize: 16.0, color: AppPallete.secondaryColor);

  static final smallText = GoogleFonts.inter(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: AppPallete.secondaryColor);
  static final extrasmallText = GoogleFonts.inter(
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      color: AppPallete.secondaryColor);
}
