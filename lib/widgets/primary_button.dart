import 'package:flutter/material.dart';
import 'package:teman_nugas/constants/constant.dart';

class PrimaryButton extends StatelessWidget {
  final Color buttonColor;
  final String textValue;
  final Color textColor;
  const PrimaryButton({super.key, 
    this.buttonColor = primaryBlue,
    this.textValue='',
    this.textColor = background,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(textValue, style: content.copyWith(color: darkBlue)),
            ),
          ),
        ),
      ),
    );
  }
}
