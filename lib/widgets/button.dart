import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../utils/sizeconst.dart';
import '../utils/textstyles.dart';

class CustomButton {
  static Widget buildButton(
      {required String text,
      required Function() onPressed,
      required Color color,
      required Color textColor,
      double borderRadius = 4.0,
      //side
      Color borderColor = Colors.transparent}) {
    return MaterialButton(
      minWidth: 300,
      height: 50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: color,
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyles.mediumText.copyWith(color: textColor),
      ),
    );
  }

  // Custom button with gradient
  static Widget buildCustomButton({
    required BuildContext context,
    required Function() onPressed,
    required String text,
    required bool isArrowVisible,
  }) {
    return InkWell(
      overlayColor: WidgetStateProperty.all(AppPallete.transparent),
      highlightColor: AppPallete.transparent,
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              AppPallete.buttonGradient1,
              AppPallete.buttonGradient1,
              AppPallete.buttonGradient2,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyles.mediumText.copyWith(
                color: AppPallete.inversePrimaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            buildWidth(deviceWidth(context) * 0.02),
            if (isArrowVisible)
              Image.asset(
                'assets/images/forward_arrow.png',
                height: deviceHeight(context) * 0.03,
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildAuthButton({
    required BuildContext context,
    required String text,
    required Function() onPressed,
    required String iconPath,
  }) {
    return Container(
      width: double.infinity,
      height: deviceHeight(context) * 0.06,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPallete.greyPrimary, width: 1),
        color: AppPallete.background,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Leading icon
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: deviceWidth(context) * 0.02),
            child: Image.asset(
              iconPath,
              height: deviceHeight(context) * 0.03,
              width: deviceWidth(context) * 0.1,
            ),
          ),
          // Text login with Google
          Text(
            text,
            style: TextStyles.mediumText
                .copyWith(color: AppPallete.primaryTextColor),
          ),
        ],
      ),
    );
  }
}
