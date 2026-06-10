import 'package:flutter/material.dart';
import '../../service/chatService.dart';
import '../user/chat_room_page.dart';

class ChatListAdminPage extends StatefulWidget {
  final int adminId;

  const ChatListAdminPage({
    super.key,
    required this.adminId,
  });

  @override
  State<ChatListAdminPage> createState() => _ChatListAdminPageState();
}

class _ChatListAdminPageState extends State<ChatListAdminPage> {
  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Colors.white;

  late Future<List<dynamic>> chatRoomsFuture;

  @override
  void initState() {
    super.initState();
    loadChatRooms();
  }

  void loadChatRooms() {
    chatRoomsFuture = ChatService.getChatRoomsByUser(widget.adminId);
  }

  Future<void> refreshChatRooms() async {
    setState(() {
      loadChatRooms();
    });
  }

  String formatJam(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return "";

    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();

      final now = DateTime.now();
      final isToday =
          date.day == now.day && date.month == now.month && date.year == now.year;

      final hour = date.hour.toString().padLeft(2, "0");
      final minute = date.minute.toString().padLeft(2, "0");

      if (isToday) {
        return "$hour:$minute";
      }

      final day = date.day.toString().padLeft(2, "0");
      final month = date.month.toString().padLeft(2, "0");

      return "$day/$month";
    } catch (_) {
      return "";
    }
  }

  // Widget _header(int total) {
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: secondaryColor,
  //       borderRadius: BorderRadius.circular(18),
  //       boxShadow: [
  //         BoxShadow(
  //           color: secondaryColor.withOpacity(0.12),
  //           blurRadius: 12,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: 70,
          color: secondaryColor.withOpacity(0.25),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Belum ada chat",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Pesan dari pengguna akan muncul di sini.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor.withOpacity(0.55),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _errorState(Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.error_outline_rounded,
          size: 80,
          color: Colors.red.shade300,
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Gagal memuat chat",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor.withOpacity(0.65),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _avatar(dynamic foto, String nama) {
    if (foto != null && foto.toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          foto.toString(),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _avatarPlaceholder(nama);
          },
        ),
      );
    }

    return _avatarPlaceholder(nama);
  }

  Widget _avatarPlaceholder(String nama) {
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : "?";

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _chatCard(dynamic room) {
    final int roomUserId = int.parse(room["user_id"].toString());

    final namaUser = room["user_nama"]?.toString() ?? "User";
    final emailUser = room["user_email"]?.toString() ?? "";
    final fotoUser = room["user_foto_profile"];

    final lastMessage = room["last_message"]?.toString() ?? "Belum ada pesan";
    final lastMessageAt = formatJam(room["last_message_at"]);

    final unreadCount = int.tryParse(room["unread_count"].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unreadCount > 0
              ? accentColor.withOpacity(0.85)
              : dominantColor.withOpacity(0.75),
          width: unreadCount > 0 ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(
                currentUserId: widget.adminId,
                userId: roomUserId,
                adminId: widget.adminId,
                referenceLaporanId: null,
              ),
            ),
          );

          refreshChatRooms();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _avatar(fotoUser, namaUser),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaUser,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (emailUser.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        emailUser,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryColor.withOpacity(0.48),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0
                            ? secondaryColor
                            : secondaryColor.withOpacity(0.62),
                        fontSize: 13,
                        fontWeight:
                            unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastMessageAt.isNotEmpty)
                    Text(
                      lastMessageAt,
                      style: TextStyle(
                        color: unreadCount > 0
                            ? accentColor
                            : secondaryColor.withOpacity(0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 99 ? "99+" : unreadCount.toString(),
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: secondaryColor.withOpacity(0.35),
                      size: 24,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: RefreshIndicator(
        color: accentColor,
        onRefresh: refreshChatRooms,
        child: FutureBuilder<List<dynamic>>(
          future: chatRoomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return _errorState(snapshot.error!);
            }

            final rooms = snapshot.data ?? [];

            if (rooms.isEmpty) {
              return _emptyState();
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                return _chatCard(rooms[index]);
              },
            );
          },
        ),
      ),
    );
  }
}