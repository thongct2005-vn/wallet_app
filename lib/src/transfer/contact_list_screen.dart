import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/services/user_service.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});
  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = true;
  String _errMsg = '';
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _permanentlyDenied = false;

  // Tìm người dùng ngoài danh bạ khi nhập đủ 10 số điện thoại hợp lệ
  bool _isFinding = false;
  int _findSeq = 0;
  String _findPhone = '';
  String _findMsg = '';
  Map<String, dynamic>? _foundUser;

  @override
  void initState() {
    super.initState();
    _loadContact();
    _phoneController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onQueryChanged);
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kTfBg,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: TransferCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
            },
          ),
          title: const TransferAppBarTitle('Chuyển tiền'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextFieldTapRegion(
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kTfPink.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(
                        Iconsax.search_normal_1,
                        size: 20,
                        color: kTfPink,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          maxLength: 25,
                          cursorColor: kTfPink,
                          textInputAction: TextInputAction.search,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          onSubmitted: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: kTfText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm tên, SĐT',
                            hintStyle: GoogleFonts.roboto(
                              fontSize: 16,
                              color: kTfMuted,
                            ),
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(
                              left: 10,
                              right: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        const RepaintBoundary(child: TransferHeaderGradient()),
        SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kTfPink))
              : _errMsg.isNotEmpty
              ? _buildErrorState()
              : _filteredUsers.isEmpty && FormatUtils.isValidPhone(_query)
              ? _buildFindResult()
              : _filteredUsers.isEmpty
              ? _buildEmptyState('Không tìm thấy người dùng này')
                : _buildListCard(
                    title: 'Danh bạ',
                    child: ListView.separated(
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 8),
                    separatorBuilder: (context, index) {
                      return Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.black.withValues(alpha: 0.07),
                        indent: 74,
                        endIndent: 18,
                      );
                    },
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserTile(
                        fullName: user['full_name'] ?? 'Không rõ tên',
                        phone: user['phone'] ?? '',
                        userId: user['id'],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String get _query => _phoneController.text.trim();

  // Thẻ trắng chứa tiêu đề và danh sách
  Widget _buildListCard({
    required String title,
    required Widget child,
    bool scrollable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          decoration: transferCardDeco(radius: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                    child: Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: kTfText,
                      ),
                    ),
                  ),
                  if (scrollable) Flexible(child: child) else child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kTfPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.user_search, color: kTfPink, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 16, color: kTfMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.info_circle,
                color: Colors.redAccent,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _errMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 16, color: kTfText),
            ),
            if (_permanentlyDenied) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTfPink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => openAppSettings(),
                child: Text(
                  "Mở Cài đặt",
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile({
    required String fullName,
    required String phone,
    required dynamic userId,
  }) {
    return InkWell(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AmountInputScreen(
              receiverPhone: phone,
              receiverFullName: fullName,
              receiverId: userId,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TransferAvatar(name: fullName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: kTfText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: GoogleFonts.roboto(fontSize: 14, color: kTfMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kTfMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // Kết quả tìm theo số điện thoại (người dùng không có trong danh bạ)
  Widget _buildFindResult() {
    if (_isFinding) {
      return const Center(child: CircularProgressIndicator(color: kTfPink));
    }
    if (_foundUser != null) {
      return _buildListCard(
        title: 'Kết quả tìm kiếm',
        scrollable: false,
        child: _buildUserTile(
          fullName: _foundUser!['full_name'] ?? 'Không rõ tên',
          phone: _findPhone,
          userId: _foundUser!['user_id'],
        ),
      );
    }
    return _buildEmptyState(
      _findMsg.isNotEmpty ? _findMsg : 'Không tìm thấy người dùng này',
    );
  }

  void _onQueryChanged() {
    _filterUsers();
    final seq = ++_findSeq;
    final query = _query;
    if (!FormatUtils.isValidPhone(query) || _filteredUsers.isNotEmpty) {
      setState(() {
        _isFinding = false;
        _foundUser = null;
        _findMsg = '';
      });
      return;
    }
    _findUser(query, seq);
  }

  Future<void> _findUser(String phone, int seq) async {
    if (phone == Get.find<UserController>().phone.value) {
      setState(() {
        _isFinding = false;
        _foundUser = null;
        _findMsg = 'Bạn không thể chuyển tiền cho chính mình';
      });
      return;
    }

    setState(() {
      _isFinding = true;
      _foundUser = null;
      _findMsg = '';
      _findPhone = phone;
    });

    final result = await _userService.findUserByPhone(phone);
    if (!mounted || seq != _findSeq) return;

    setState(() {
      _isFinding = false;
      if (result['is_success'] == true) {
        _foundUser = result['user_info'];
      } else {
        _findMsg = result['message']?.toString() ?? 'Không tìm thấy người dùng này';
      }
    });
  }

  void _filterUsers() {
    final query = _phoneController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['full_name'] ?? '').toLowerCase();
        final phone = (user['phone'] ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  Future<void> _loadContact() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final result = await _userService.fetchContactAndCheckAppUser();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['is_success'] == true) {
        _users = result['data'];
        _filteredUsers = _users;
        _errMsg = '';
        _permanentlyDenied = false;
      } else {
        _errMsg = result['message'];
        _permanentlyDenied = result['permanently_denied'] == true;
      }
    });
  }
}