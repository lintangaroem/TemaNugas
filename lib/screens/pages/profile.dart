import 'package:flutter/material.dart';
import 'edit_profile.dart'; // import halaman edit profil


class ProfilePage extends StatelessWidget {
 const ProfilePage({super.key});


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       actions: [
         IconButton(
           color: Colors.black,
           icon: const Icon(Icons.logout),
           onPressed: () {
             // TODO: aksi logout jika perlu
           },
         ),
       ],
     ),
     body: Padding(
       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
       child: Column(
         children: [
           CircleAvatar(
             radius: 50,
             backgroundImage: NetworkImage(
               'https://randomuser.me/api/portraits/men/45.jpg',
             ),
           ),
           const SizedBox(height: 16),
           const Text(
             'Zhafran Aryan',
             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 4),
           const Text(
             'zhafransyah@gmail.com',
             style: TextStyle(color: Colors.grey, fontSize: 14),
           ),
           const SizedBox(height: 12),
           Wrap(
             spacing: 8,
             children: const [
               Chip(label: Text('UI/UX')),
               Chip(label: Text('Frontend')),
               Chip(label: Text('Backend')),
             ],
           ),
           const SizedBox(height: 20),
           ElevatedButton(
             onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const EditProfilePage()),
               );
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.teal[300],
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
             ),
             child: const Text(
               'Edit Profile',
               style: TextStyle(color: Colors.black),
             ),
           ),
           const SizedBox(height: 32),
           const Align(
             alignment: Alignment.centerLeft,
             child: Text(
               'Bio',
               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
             ),
           ),
           const SizedBox(height: 12),
           Container(
             width: double.infinity,
             height: 200,
             decoration: BoxDecoration(
               color: Colors.grey[300],
               borderRadius: BorderRadius.circular(12),
             ),
             alignment: Alignment.center,
             child: const Text(
               'Zhafran',
               style: TextStyle(fontSize: 18, color: Colors.black54),
             ),
           ),
         ],
       ),
     ),
   );
 }
}
