import 'package:flutter/material.dart';


class EditProfilePage extends StatefulWidget {
 const EditProfilePage({super.key});


 @override
 State<EditProfilePage> createState() => _EditProfilePageState();
}


class _EditProfilePageState extends State<EditProfilePage> {
 final _firstNameController = TextEditingController(text: 'Zhafran');
 final _lastNameController = TextEditingController(text: 'Aryan');
 final _usernameController = TextEditingController(text: 'Zhafran');
 final _emailController = TextEditingController(text: 'zhafransyah@gmail.com');


 String? _selectedSkill;
 final List<String> _skills = ['UI/UX', 'Frontend', 'Backend'];


 @override
 void dispose() {
   _firstNameController.dispose();
   _lastNameController.dispose();
   _usernameController.dispose();
   _emailController.dispose();
   super.dispose();
 }


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       centerTitle: true,
       title: const Text(
         'Edit Profile',
         style: TextStyle(
           color: Colors.black,
           fontWeight: FontWeight.w500,
         ),
       ),
       leading: IconButton(
         icon: const Icon(Icons.arrow_back),
         onPressed: () => Navigator.pop(context),
       ),
     ),
     body: SafeArea(
       child: SingleChildScrollView(
         padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
         child: Column(
           children: [
             Stack(
               alignment: Alignment.bottomRight,
               children: [
                 CircleAvatar(
                   radius: 60,
                   backgroundImage: NetworkImage(
                     'https://randomuser.me/api/portraits/men/45.jpg',
                   ),
                 ),
                 Positioned(
                   right: 4,
                   bottom: 4,
                   child: CircleAvatar(
                     radius: 16,
                     backgroundColor: Colors.white,
                     child: IconButton(
                       icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                       onPressed: () {
                         // TODO: aksi ganti foto profil
                       },
                     ),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 32),
             _buildTextField('First Name', _firstNameController),
             const SizedBox(height: 16),
             _buildTextField('Last Name', _lastNameController),
             const SizedBox(height: 16),
             _buildTextField('Username', _usernameController),
             const SizedBox(height: 16),
             _buildTextField('Email', _emailController, enabled: false),
             const SizedBox(height: 16),
             DropdownButtonFormField<String>(
               decoration: InputDecoration(
                 labelText: 'Skill',
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
               ),
               value: _selectedSkill,
               items: _skills
                   .map((skill) => DropdownMenuItem(
                 value: skill,
                 child: Text(skill),
               ))
                   .toList(),
               onChanged: (value) {
                 setState(() {
                   _selectedSkill = value;
                 });
               },
               hint: const Text('Pilih skill'),
             ),
             const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () {
                   // TODO: simpan data profil
                   Navigator.pop(context);
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.blue[900],
                   padding: const EdgeInsets.symmetric(vertical: 14),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(8),
                   ),
                 ),
                 child: const Text(
                   'Save',
                   style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                 ),
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }


 Widget _buildTextField(String label, TextEditingController controller,
     {bool enabled = true}) {
   return TextField(
     controller: controller,
     enabled: enabled,
     decoration: InputDecoration(
       labelText: label,
       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
     ),
   );
 }
}
