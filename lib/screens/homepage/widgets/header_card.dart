import 'package:flutter/material.dart';
import 'package:teman_nugas/constants/constant.dart';

class ProfileCard extends StatelessWidget {
  final String username;
  final int projectsRemaining;

  const ProfileCard({
    super.key,
    required this.username,
    required this.projectsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            backgroundImage: const NetworkImage(
              'https://via.placeholder.com/60',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, $username!', style: AppTextStyles.heading),
                const SizedBox(height: 4),
                Text(
                  "Siap nugas bareng hari ini?",
                  style: AppTextStyles.regular,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_late,
                      color: AppColors.redAlert,
                      size: 16,
                    ),
                    Text(
                      "$projectsRemaining projects remain",
                      style: AppTextStyles.regular,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
