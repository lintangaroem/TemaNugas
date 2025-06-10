import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TemaNugas/models/user/authenticated_user.dart';
import '../../../providers/auth_provider.dart';
import '../../../constants/constant.dart';
import '../../../constants/theme.dart';
import 'edit_profile.dart';
import '../../widgets/navbar.dart';
import 'home_page.dart';
import 'group_page.dart';
import 'package:TemaNugas/screens/login/pages/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2;
  bool isEditingBio = false;
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    // Initialize controller dengan data dari provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bioController = TextEditingController(text: authProvider.userBio);
  }

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const GroupPage()),
      );
    } else if (index == 2) {
      return;
    }
  }

  // Helper method untuk memisahkan nama
  List<String> _splitName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return [parts[0], ''];
    } else {
      final firstName = parts[0];
      final lastName = parts.sublist(1).join(' ');
      return [firstName, lastName];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final AuthenticatedUser? currentUser = authProvider.user;

        if (authProvider.authStatus == AuthStatus.authenticating && currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Profil")),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Anda belum login.", style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        }

        // Sync bioController dengan data dari provider
        if (bioController.text != authProvider.userBio && !isEditingBio) {
          bioController.text = authProvider.userBio;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${currentUser.name.replaceAll(' ', '+')}&background=random&color=fff&size=128&font-size=0.33'),
                  ),
                  const SizedBox(height: 20),
                  Text(currentUser.name, style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(currentUser.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  // Skills dari provider - sekarang persistent!
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: authProvider.userSkills.map((skill) =>
                        Chip(
                            label: Text(skill),
                            backgroundColor: AppColors.lightGrey
                        )
                    ).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit Profil'),
                    onPressed: () {
                      final nameParts = _splitName(currentUser.name);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            firstName: nameParts[0],
                            lastName: nameParts[1],
                            username: currentUser.name,
                            email: currentUser.email,
                            selectedSkills: authProvider.userSkills, // Dari provider
                            bio: authProvider.userBio, // Dari provider
                            profileImageUrl: 'https://ui-avatars.com/api/?name=${currentUser.name.replaceAll(' ', '+')}&background=random&color=fff&size=128&font-size=0.33',
                          ),
                        ),
                      ).then((result) {
                        if (mounted && result != null) {
                          // Update ke provider - akan persistent!
                          authProvider.updateProfileData(
                            bio: result['bio'],
                            skills: result['skills'],
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Bio Saya', style: AppTextStyles.titleLarge),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditingBio = true;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isEditingBio
                          ? Column(
                        children: [
                          TextField(
                            controller: bioController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Edit your bio...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Simpan ke provider
                              authProvider.updateUserBio(bioController.text);
                              setState(() {
                                isEditingBio = false;
                              });
                            },
                            child: const Text('Save Bio'),
                          ),
                        ],
                      )
                          : Text(
                        authProvider.userBio, // Ambil dari provider
                        style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}