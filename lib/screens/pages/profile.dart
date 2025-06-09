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
  TextEditingController bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    bioController.text = 'hi';
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: const [
                      Chip(label: Text('UI/UX'), backgroundColor: AppColors.lightGrey),
                      Chip(label: Text('Frontend'), backgroundColor: AppColors.lightGrey),
                      Chip(label: Text('Backend'), backgroundColor: AppColors.lightGrey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit Profil'),
                    onPressed: () {
                      // Pisahkan nama untuk firstName dan lastName
                      final nameParts = _splitName(currentUser.name);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            firstName: nameParts[0],
                            lastName: nameParts[1],
                            username: currentUser.name, // atau gunakan username terpisah jika ada
                            email: currentUser.email,
                            skill: 'UI/UX', // default skill, bisa disesuaikan dengan data user
                            bio: bioController.text,
                            profileImageUrl: 'https://ui-avatars.com/api/?name=${currentUser.name.replaceAll(' ', '+')}&background=random&color=fff&size=128&font-size=0.33',
                          ),
                        ),
                      ).then((result) {
                        if (mounted && result != null) {
                          // Update data jika ada perubahan dari EditProfile
                          setState(() {
                            if (result['bio'] != null) {
                              bioController.text = result['bio'];
                            }
                          });
                          Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
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
                              setState(() {
                                isEditingBio = false;
                              });
                            },
                            child: const Text('Save Bio'),
                          ),
                        ],
                      )
                          : Text(
                        bioController.text,
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