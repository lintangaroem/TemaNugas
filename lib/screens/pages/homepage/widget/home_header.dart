// lib/screens/home/widgets/home_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TemaNugas/constants/constant.dart';
import 'package:TemaNugas/models/user/authenticated_user.dart';
import 'package:TemaNugas/providers/auth_provider.dart';

class HomeHeader extends StatefulWidget {
  final AuthenticatedUser? currentUser;
  const HomeHeader({super.key, required this.currentUser});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  Future<void> _handleLogout() async {
    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await Provider.of<AuthProvider>(context, listen: false).logout();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat logout: $e'),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.currentUser?.name ?? "Pengguna";

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.lightGrey,
          backgroundImage: widget.currentUser?.name != null
              ? NetworkImage(
                  'https://ui-avatars.com/api/?name=${widget.currentUser!.name.replaceAll(' ', '+')}&background=random&color=fff&size=128')
              : null,
          child: widget.currentUser?.name == null
              ? const Icon(
                  Icons.person,
                  size: 28,
                  color: AppColors.textLight,
                )
              : null,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Halo, $username!",
                style: AppTextStyles.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "Siap nugas bareng hari ini?",
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: AppColors.primaryBlue),
          tooltip: "Logout",
          onPressed: _handleLogout,
        ),
      ],
    );
  }
}