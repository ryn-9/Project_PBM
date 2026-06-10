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
  static const Color dominantColor    = Color(0xFFD8C99B);
  static const Color secondaryColor   = Color(0xFF273E47);
  static const Color accentColor      = Color(0xFFD8973C);
  static const Color bgLight          = Color(0xFFF5F0E8);
  static const Color cardBg           = Colors.white;

  // Warna pra-kalkulasi — tidak pakai withOpacity() di build()
  static const Color secondaryColor6  = Color(0x0F273E47); // 0.06
  static const Color secondaryColor25 = Color(0x40273E47); // 0.25
  static const Color secondaryColor35 = Color(0x59273E47); // 0.35
  static const Color secondaryColor45 = Color(0x73273E47); // 0.45
  static const Color secondaryColor48 = Color(0x7A273E47); // 0.48
  static const Color secondaryColor55 = Color(0x8C273E47); // 0.55
  static const Color secondaryColor62 = Color(0x9E273E47); // 0.62
  static const Color secondaryColor65 = Color(0xA6273E47); // 0.65
  static const Color accentColor18    = Color(0x2ED8973C); // 0.18
  static const Color accentColor85    = Color(0xD9D8973C); // 0.85
  static const Color dominantColor75  = Color(0xBFD8C99B); // 0.75

  List<dynamic> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ChatService.getChatRoomsByUser(widget.adminId);
      if (!mounted) return;
      setState(() {
        _rooms = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatJam(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return "";
    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();
      final now  = DateTime.now();
      final isToday = date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;

      if (isToday) {
        return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      }

      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: RefreshIndicator(
        color: accentColor,
        onRefresh: _loadChatRooms,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(error: _errorMessage!);
    }

    if (_rooms.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          key: ValueKey(_rooms[index]["id"]),
          child: _ChatCard(
            room: _rooms[index],
            adminId: widget.adminId,
            formatJam: _formatJam,
            onBack: _loadChatRooms,
          ),
        );
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: 70,
          color: _ChatListAdminPageState.secondaryColor25,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            "Belum ada chat",
            style: TextStyle(
              color: _ChatListAdminPageState.secondaryColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Pesan dari pengguna akan muncul di sini.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ChatListAdminPageState.secondaryColor55,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline_rounded, size: 80, color: Colors.red.shade300),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Gagal memuat chat",
            style: TextStyle(
              color: _ChatListAdminPageState.secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ChatListAdminPageState.secondaryColor65,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─── Chat Card ────────────────────────────────────────────────────────────────

class _ChatCard extends StatelessWidget {
  final dynamic room;
  final int adminId;
  final String Function(dynamic) formatJam;
  final VoidCallback onBack;

  const _ChatCard({
    required this.room,
    required this.adminId,
    required this.formatJam,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final int roomUserId = int.parse(room["user_id"].toString());

    final namaUser    = room["user_nama"]?.toString() ?? "User";
    final emailUser   = room["user_email"]?.toString() ?? "";
    final fotoUser    = room["user_foto_profile"];
    final lastMessage = room["last_message"]?.toString() ?? "Belum ada pesan";
    final lastAt      = formatJam(room["last_message_at"]);
    final unread      = int.tryParse(room["unread_count"].toString()) ?? 0;
    final hasUnread   = unread > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _ChatListAdminPageState.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread
              ? _ChatListAdminPageState.accentColor85
              : _ChatListAdminPageState.dominantColor75,
          width: hasUnread ? 1.5 : 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: _ChatListAdminPageState.secondaryColor6,
            blurRadius: 8,
            offset: Offset(0, 4),
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
                currentUserId: adminId,
                userId: roomUserId,
                adminId: adminId,
                referenceLaporanId: null,
              ),
            ),
          );
          onBack();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _Avatar(foto: fotoUser, nama: namaUser),
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
                        color: _ChatListAdminPageState.secondaryColor,
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
                        style: const TextStyle(
                          color: _ChatListAdminPageState.secondaryColor48,
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
                        color: hasUnread
                            ? _ChatListAdminPageState.secondaryColor
                            : _ChatListAdminPageState.secondaryColor62,
                        fontSize: 13,
                        fontWeight: hasUnread
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ChatCardTrailing(unread: unread, lastAt: lastAt),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final dynamic foto;
  final String nama;

  const _Avatar({required this.foto, required this.nama});

  static const _radius = BorderRadius.all(Radius.circular(26));

  @override
  Widget build(BuildContext context) {
    if (foto != null && foto.toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          foto.toString(),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Placeholder(nama: nama),
        ),
      );
    }
    return _Placeholder(nama: nama);
  }
}

class _Placeholder extends StatelessWidget {
  final String nama;
  const _Placeholder({required this.nama});

  @override
  Widget build(BuildContext context) {
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : "?";
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: _ChatListAdminPageState.accentColor18,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: _ChatListAdminPageState.accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Chat Card Trailing (waktu + badge unread) ────────────────────────────────

class _ChatCardTrailing extends StatelessWidget {
  final int unread;
  final String lastAt;

  const _ChatCardTrailing({required this.unread, required this.lastAt});

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (lastAt.isNotEmpty)
          Text(
            lastAt,
            style: TextStyle(
              color: hasUnread
                  ? _ChatListAdminPageState.accentColor
                  : _ChatListAdminPageState.secondaryColor45,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 8),
        if (hasUnread)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: const BoxDecoration(
              color: _ChatListAdminPageState.accentColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              unread > 99 ? "99+" : unread.toString(),
              style: const TextStyle(
                color: _ChatListAdminPageState.secondaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const Icon(
            Icons.chevron_right_rounded,
            color: _ChatListAdminPageState.secondaryColor35,
            size: 24,
          ),
      ],
    );
  }
}