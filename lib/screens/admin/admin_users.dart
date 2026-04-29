import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  Stream<QuerySnapshot> get _usersStream =>
      FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots();

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'shop_owner': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.shield_outlined;
      case 'shop_owner': return Icons.storefront_outlined;
      default: return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('All Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFC8821A)));
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No users found.',
                  style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic)));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data =
                  doc.data() as Map<String, dynamic>;
              final role = data['role'] ?? 'customer';
              final createdAt =
                  (data['createdAt'] as Timestamp)
                      .toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3D2B1F)
                          .withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    // Avatar
                    CircleAvatar(
                      backgroundColor:
                          _roleColor(role).withOpacity(0.1),
                      child: Icon(
                        _roleIcon(role),
                        color: _roleColor(role),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'No name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF3D2B1F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (data['phone'] != null &&
                              data['phone']
                                  .toString()
                                  .isNotEmpty)
                            Text(
                              data['phone'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          Text(
                            'Joined: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _roleColor(role)
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: _roleColor(role)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        role == 'shop_owner'
                            ? 'Vendor'
                            : role[0].toUpperCase() +
                                role.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _roleColor(role),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}