import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/services/user_service.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Tìm người dùng ngoài danh bạ khi nhập đủ 10 số điện thoại
  static final RegExp _phoneRegex = RegExp(r'^0\d{9}$');
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
    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.fromLTRB(10, 10, 0, 10),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
              icon: Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),
        title: Text('Chuyển tiền', style: GoogleFonts.roboto(fontSize: 20)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search),

                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      maxLength: 25,
                      cursorColor: Colors.pink,
                      style: GoogleFonts.roboto(fontSize: 16),

                      decoration: InputDecoration(
                        hintText: 'Tìm tên, SĐT',
                        hintStyle: GoogleFonts.roboto(fontSize: 16),
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(left: 10, right: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 500,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.pink.shade200.withValues(alpha: 0.8),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.pink))
              : _errMsg.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errMsg,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            color: Colors.red,
                            fontSize: 18,
                          ),
                        ),
                        if (_permanentlyDenied) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => openAppSettings(),
                            child: Text("Mở Cài đặt", style: GoogleFonts.roboto()),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : _filteredUsers.isEmpty && _phoneRegex.hasMatch(_query)
              ? _buildFindResult()
              : _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'Không tìm thấy người dùng này',
                    style: GoogleFonts.roboto(fontSize: 16),
                  ),
                )
              : Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(15, 10, 0, 0),
                        child: Text(
                          'Danh bạ',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Material(
                          color: Colors.transparent,
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            separatorBuilder: (context, index) {
                              return Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey.shade300,
                                indent: 70,
                                endIndent: 20,
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
                  ),
                ),
        ),
      ],
    );
  }

  String get _query => _phoneController.text.trim();

  Widget _buildUserTile({
    required String fullName,
    required String phone,
    required dynamic userId,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.pink.shade50.withValues(alpha: 0.6),
        child: Text(
          FormatUtils.formatAvatar(fullName),
          style: GoogleFonts.roboto(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        fullName,
        style: GoogleFonts.roboto(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      subtitle: Text(phone, style: GoogleFonts.roboto(fontSize: 14)),
      onTap: () {
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
    );
  }

  // Kết quả tìm theo số điện thoại (người dùng không có trong danh bạ)
  Widget _buildFindResult() {
    if (_isFinding) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    if (_foundUser != null) {
      return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
              child: Text(
                'Kết quả tìm kiếm',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: _buildUserTile(
                  fullName: _foundUser!['full_name'] ?? 'Không rõ tên',
                  phone: _findPhone,
                  userId: _foundUser!['user_id'],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _findMsg.isNotEmpty ? _findMsg : 'Không tìm thấy người dùng này',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(fontSize: 16),
        ),
      ),
    );
  }

  void _onQueryChanged() {
    _filterUsers();
    final seq = ++_findSeq;
    final query = _query;
    if (!_phoneRegex.hasMatch(query) || _filteredUsers.isNotEmpty) {
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