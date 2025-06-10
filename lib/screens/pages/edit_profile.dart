import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final List<String>? selectedSkills; // Ubah dari single skill ke list
  final String? bio;
  final String? profileImageUrl;

  const EditProfilePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.selectedSkills,
    this.bio,
    this.profileImageUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;

  // Ubah ke list untuk multiple selection
  List<String> _selectedSkills = [];
  final List<String> _availableSkills = [
    'UI/UX',
    'Frontend',
    'Backend',
    'Mobile Development',
    'Data Science',
    'DevOps',
    'Machine Learning',
    'Cybersecurity'
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _bioController = TextEditingController(text: widget.bio ?? '');

    // Set skills yang sudah dipilih sebelumnya
    _selectedSkills = widget.selectedSkills ?? [];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: widget.profileImageUrl != null
                          ? NetworkImage(widget.profileImageUrl!)
                          : null,
                      backgroundColor: Colors.orange,
                      child: widget.profileImageUrl == null
                          ? Text(
                        '${widget.firstName[0]}${widget.lastName.isNotEmpty ? widget.lastName[0] : ''}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField('First Name', _firstNameController),
              const SizedBox(height: 16),
              _buildTextField('Last Name', _lastNameController),
              const SizedBox(height: 16),
              _buildTextField('Username', _usernameController),
              const SizedBox(height: 16),
              _buildTextField('Email', _emailController, enabled: false),
              const SizedBox(height: 20),

              // Skills Section dengan multiple selection
              const Text(
                'Skills',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih skills yang kamu kuasai:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return GestureDetector(
                          onTap: () => _toggleSkill(skill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedSkills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Skills terpilih: ${_selectedSkills.length}',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField('Bio', _bioController, maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updatedData = {
                      'firstName': _firstNameController.text,
                      'lastName': _lastNameController.text,
                      'username': _usernameController.text,
                      'email': _emailController.text,
                      'skills': _selectedSkills, // Kirim list skills
                      'bio': _bioController.text,
                    };
                    Navigator.pop(context, updatedData);
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool enabled = true,
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}