import 'package:flutter/material.dart';


class BottomNavBar extends StatelessWidget {
 final int currentIndex;
 final ValueChanged<int> onTap;


 const BottomNavBar({
   super.key,
   required this.currentIndex,
   required this.onTap,
 });


 @override
 Widget build(BuildContext context) {
   return BottomNavigationBar(
     backgroundColor: Colors.white,
     currentIndex: currentIndex,
     onTap: onTap,
     selectedItemColor: Color(0xFF4BA7CE),
     unselectedItemColor: Colors.grey,
     showUnselectedLabels: true,
     items: const [
       BottomNavigationBarItem(
         icon: Icon(Icons.home),
         label: 'Home',
       ),
       BottomNavigationBarItem(
         icon: Icon(Icons.group),
         label: 'Group',
       ),
       BottomNavigationBarItem(
         icon: Icon(Icons.person),
         label: 'Profile',
       ),
     ],
   );
 }
}
