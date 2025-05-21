import 'package:flutter/material.dart';
import 'package:teman_nugas/constants/constant.dart';

class Checkbox extends StatefulWidget {
  const Checkbox({super.key});

  @override
  State<Checkbox> createState() => _CheckboxState();
}

class _CheckboxState extends State<Checkbox> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isChecked ? darkBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isChecked ? null : Border.all(color: darkBlue, width: 1.5),
        ),
        width: 15,
        height: 15,
        child:
            isChecked ? Icon(Icons.check, size: 15, color: background) : null,
      ),
    );
  }
}
