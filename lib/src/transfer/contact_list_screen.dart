import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});
  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = true;
  String _errMsg = '';
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchContactAndCheckAppUser();
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
          height: 250,
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
              ? Center(child: CircularProgressIndicator(
                color: Colors.pink,
              ))
              : _errMsg.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      _errMsg,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.red,
                        fontSize: 20,
                      ),
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
                                    _formatAvatar(user['full_name'] ?? ''),
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
                                        phone: user['phone'],
                                        fullName:
                                            user['full_name'] ?? 'Không rõ tên',
                                        avatarName: _formatAvatar(
                                          user['full_name'] ?? '',
                                        ),
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

  String _formatAvatar(String fullName) {
    if (fullName.trim().isEmpty) return '?';
    List<String> words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[words.length - 2][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  Future<void> _fetchContactAndCheckAppUser() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        List<Contact> contacts = await FlutterContacts.getAll(
          properties: {ContactProperty.phone},
        );

        List<String> phoneNumbers = [];
        for (var contact in contacts) {
          if (contact.phones.isNotEmpty) {
            String rawPhone = contact.phones.first.number.replaceAll(
              RegExp(r'\D'),
              '',
            );
            if (rawPhone.startsWith('84')) {
              rawPhone = '0${rawPhone.substring(2)}';
            }
            if (rawPhone.length == 10) {
              phoneNumbers.add(rawPhone);
            }
          }
        }
        _isLoading = true;
        final api = ApiClient().dio;
        final response = await api.post(
          ApiConfig.checkContact,
          data: {'phones': phoneNumbers},
        );

        final responseData = response.data;
        if (responseData != null && responseData['data'] != null) {
          setState(() {
            _users = responseData['data'];
            _filteredUsers = _users;
            _isLoading = false;
            _errMsg = '';
          });
        } else {
          _isLoading = false;
          _errMsg = 'Hệ thống đang bảo trì';
        }
      } else {
        setState(() {
          _errMsg = 'Vui lòng cấp quyền danh bạ để dùng tính năng này';
          _isLoading = false;
        });
      }
    } catch (e) {
      _errMsg = 'Hệ thống đang bảo trì';
      _isLoading = false;
      print(e);
    }
  }
}
