import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/services/user_service.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadContact();
    _phoneController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_filterUsers);
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
                      maxLength: 50,
                      cursorColor: Colors.pink,

                      decoration: InputDecoration(
                        hintText: 'Tìm tên, SĐT',
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
                            child: const Text("Mở Cài đặt"),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : _filteredUsers.isEmpty
              ? Center(child: Text('Không tìm thấy người dùng này'))
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
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.pink.shade50
                                      .withValues(alpha: 0.6),
                                  child: Text(
                                    FormatUtils.formatAvatar(
                                      user['full_name'] ?? '',
                                    ),
                                    style: GoogleFonts.roboto(
                                      color: Colors.pink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user['full_name'] ?? 'Không rõ tên',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                                subtitle: Text(user['phone']),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AmountInputScreen(
                                        receiverPhone: user['phone'],
                                        receiverFullName:
                                            user['full_name'] ?? 'Không rõ tên',
                                        receiverId: user['id'],
                                      ),
                                    ),
                                  );
                                },
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
      if (result['is_success']) {
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
