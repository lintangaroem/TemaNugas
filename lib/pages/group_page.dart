import 'package:flutter/material.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        elevation: 0,
        centerTitle: true, // ini untuk center title
        automaticallyImplyLeading: false, // supaya gak otomatis kasih leading default
        title: const Text(
          'Group Page',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4, // Sesuai dengan screenshot yang menunjukkan 4 cards
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.25),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sistem Informasi Geografis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Membuat aplikasi task management untuk mengelola dan memantau tugas dengan memanfaatkan data lokasi geografis.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(10),
                      value: 0.6, // Progress 60%
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF003782),
                      ),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Updated: 1 hour ago',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        // Avatar members
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              backgroundImage: const NetworkImage(
                                'https://randomuser.me/api/portraits/women/68.jpg',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white,
                                backgroundImage: const NetworkImage(
                                  'https://randomuser.me/api/portraits/men/31.jpg',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}