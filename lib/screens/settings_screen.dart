import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/message_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

class _LocalSettings {
  static bool privateAccount = false;
  static bool allowMentions = true;
  static bool allowMessages = true;
  static bool showActivityStatus = true;

  static bool notifyLikes = true;
  static bool notifyComments = true;
  static bool notifyFollows = true;
  static bool notifyMessages = true;

  static String appearanceMode = 'system';
  static String language = 'vi';
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    context.read<UserProvider>().clearData();
    context.read<HomeProvider>().clearData();
    context.read<MessageProvider>().clearData();

    await context.read<AuthProvider>().signOut();

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.currentUserData;

    final username = _firstNonEmpty([
      userData?['username'],
      'user',
    ]);

    final nickname = _firstNonEmpty([
      userData?['nickname'],
      userData?['username'],
      'Người dùng',
    ]);

    final email = _firstNonEmpty([
      userData?['email'],
      authProvider.user?.email,
      'Chưa có email',
    ]);

    final avatarUrl = _firstNonEmpty([
      userData?['avatar_url'],
    ]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Cài đặt',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          GestureDetector(
            onTap: () => _openPage(context, const AccountInfoScreen()),
            child: _AccountHeader(
              nickname: nickname,
              username: username,
              email: email,
              avatarUrl: avatarUrl,
              showArrow: true,
            ),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Tài khoản',
            children: [

              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Mật khẩu và bảo mật',
                subtitle: 'Quản lý đăng nhập và bảo mật',
                onTap: () => _openPage(context, const SecurityScreen()),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Quyền riêng tư',
                subtitle: 'Quản lý ai có thể xem và tương tác với bạn',
                onTap: () => _openPage(context, const PrivacySettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Ứng dụng',
            children: [
              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Thông báo',
                subtitle: 'Tùy chỉnh thông báo bài viết, tim và tin nhắn',
                onTap: () =>
                    _openPage(context, const NotificationSettingsScreen()),
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Giao diện',
                subtitle: 'Chế độ sáng, tối và màu hiển thị',
                onTap: () => _openPage(
                  context,
                  const AppearanceSettingsScreen(),
                ),
              ),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Ngôn ngữ',
                subtitle: 'Tiếng Việt',
                onTap: () => _openPage(context, const LanguageSettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Khác',
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Trợ giúp',
                subtitle: 'Câu hỏi thường gặp và hỗ trợ',
                onTap: () => _openPage(context, const HelpScreen()),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Giới thiệu ứng dụng',
                subtitle: 'Phiên bản 1.0.0',
                onTap: () => _openPage(context, const AboutAppScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _LogoutButton(
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _nicknameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isEditingNickname = false;
  bool _isEditingUsername = false;
  bool _isEditingBio = false;
  bool _isSaving = false;

  String? _loadedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.currentUserData;

    final uid = _firstNonEmpty([
      userData?['firebase_uid'],
      authProvider.user?.uid,
    ]);

    if (uid != _loadedUid) {
      _loadedUid = uid;

      final nickname = _firstNonEmpty([
        userData?['nickname'],
        userData?['username'],
        'Người dùng',
      ]);

      final username = _firstNonEmpty([
        userData?['username'],
        'user',
      ]);

      final bio = _firstNonEmpty([
        userData?['bio'],
      ]);

      _nicknameController.text = nickname;
      _usernameController.text = username.replaceAll('@', '');
      _bioController.text = bio;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveField(String field) async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUserData?['firebase_uid'];

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy người dùng hiện tại'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String value = '';

    if (field == 'nickname') {
      value = _nicknameController.text.trim();
    } else if (field == 'username') {
      value = _usernameController.text.replaceAll('@', '').trim();
    } else if (field == 'bio') {
      value = _bioController.text.trim();
    }

    if ((field == 'nickname' || field == 'username') && value.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên phải có ít nhất 2 ký tự'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    bool ok = false;

    if (field == 'nickname') {
      ok = await context.read<UserProvider>().updateProfile(
        firebaseUid: uid,
        nickname: value,
      );
    } else if (field == 'username') {
      ok = await context.read<UserProvider>().updateProfile(
        firebaseUid: uid,
        username: value,
      );
    } else if (field == 'bio') {
      ok = await context.read<UserProvider>().updateProfile(
        firebaseUid: uid,
        bio: value,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (ok) {
      authProvider.updateCurrentUserData({
        field: value,
      });

      setState(() {
        if (field == 'nickname') _isEditingNickname = false;
        if (field == 'username') _isEditingUsername = false;
        if (field == 'bio') _isEditingBio = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<UserProvider>().errorMessage ??
                'Cập nhật thông tin thất bại',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _cancelEdit(String field) {
    final authProvider = context.read<AuthProvider>();
    final userData = authProvider.currentUserData;

    setState(() {
      if (field == 'nickname') {
        _nicknameController.text = _firstNonEmpty([
          userData?['nickname'],
          userData?['username'],
          'Người dùng',
        ]);
        _isEditingNickname = false;
      }

      if (field == 'username') {
        _usernameController.text = _firstNonEmpty([
          userData?['username'],
          'user',
        ]).replaceAll('@', '');
        _isEditingUsername = false;
      }

      if (field == 'bio') {
        _bioController.text = _firstNonEmpty([
          userData?['bio'],
        ]);
        _isEditingBio = false;
      }
    });
  }

  void _startEdit(String field) {
    setState(() {
      _isEditingNickname = field == 'nickname';
      _isEditingUsername = field == 'username';
      _isEditingBio = field == 'bio';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.currentUserData;

    final nickname = _firstNonEmpty([
      userData?['nickname'],
      userData?['username'],
      'Người dùng',
    ]);

    final username = _firstNonEmpty([
      userData?['username'],
      'user',
    ]);

    final email = _firstNonEmpty([
      userData?['email'],
      authProvider.user?.email,
      'Chưa có email',
    ]);

    final bio = _firstNonEmpty([
      userData?['bio'],
      'Chưa có tiểu sử',
    ]);

    final firebaseUid = _firstNonEmpty([
      userData?['firebase_uid'],
      authProvider.user?.uid,
      'Không có',
    ]);

    final avatarUrl = _firstNonEmpty([
      userData?['avatar_url'],
    ]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Thông tin tài khoản',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccountHeader(
            nickname: nickname,
            username: username,
            email: email,
            avatarUrl: avatarUrl,
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Hồ sơ',
            children: [
              _InlineEditableInfoTile(
                title: 'Tên hiển thị',
                displayValue: nickname,
                icon: Icons.badge_outlined,
                controller: _nicknameController,
                isEditing: _isEditingNickname,
                isSaving: _isSaving,
                onEdit: () => _startEdit('nickname'),
                onCancel: () => _cancelEdit('nickname'),
                onSave: () => _saveField('nickname'),
              ),
              _InlineEditableInfoTile(
                title: 'Tên đăng nhập',
                displayValue: username.startsWith('@') ? username : '@$username',
                icon: Icons.alternate_email_rounded,
                controller: _usernameController,
                prefixText: '@',
                isEditing: _isEditingUsername,
                isSaving: _isSaving,
                onEdit: () => _startEdit('username'),
                onCancel: () => _cancelEdit('username'),
                onSave: () => _saveField('username'),
              ),
              _InfoTile(
                title: 'Email',
                value: email,
                icon: Icons.email_outlined,
              ),
              _InlineEditableInfoTile(
                title: 'Tiểu sử',
                displayValue: bio,
                icon: Icons.notes_rounded,
                controller: _bioController,
                isEditing: _isEditingBio,
                isSaving: _isSaving,
                maxLines: 3,
                onEdit: () => _startEdit('bio'),
                onCancel: () => _cancelEdit('bio'),
                onSave: () => _saveField('bio'),
              ),
            ],
          ),

        ],
      ),
    );
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isSending = false;

  Future<void> _sendResetEmail() async {
    final authProvider = context.read<AuthProvider>();
    final userData = authProvider.currentUserData;

    final email = _firstNonEmpty([
      userData?['email'],
      authProvider.user?.email,
    ]);

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy email tài khoản'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Text(
          'Hệ thống sẽ gửi email đặt lại mật khẩu đến:\n\n$email\n\nBạn có muốn tiếp tục không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi email'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isSending = true;
    });

    final ok = await authProvider.forgotPassword(email);

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã gửi email đặt lại mật khẩu. Vui lòng kiểm tra hộp thư hoặc mục Spam.'
              : authProvider.errorMessage ?? 'Gửi email đặt lại mật khẩu thất bại',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.currentUserData;

    final email = _firstNonEmpty([
      userData?['email'],
      authProvider.user?.email,
      'Chưa có email',
    ]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Mật khẩu và bảo mật',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Đăng nhập',
            children: [
              _InfoTile(
                title: 'Email đăng nhập',
                value: email,
                icon: Icons.email_outlined,
              ),
              _ActionTile(
                icon: Icons.lock_reset_rounded,
                title: 'Đặt lại mật khẩu',
                subtitle: 'Gửi email đặt lại mật khẩu qua Firebase',
                trailing: _isSending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
                    : const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: _isSending ? null : _sendResetEmail,
              ),
            ],
          ),

          const SizedBox(height: 16),


          const _NoticeBox(
            text:
            'Sau khi gửi yêu cầu, Firebase sẽ gửi một đường dẫn đặt lại mật khẩu đến email đăng nhập của bạn. Nếu không thấy email, hãy kiểm tra mục Spam hoặc Thư rác.',
          ),
        ],
      ),
    );
  }
}
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Quyền riêng tư',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Tài khoản',
            children: [
              _SwitchTile(
                icon: Icons.lock_outline_rounded,
                title: 'Tài khoản riêng tư',
                subtitle: 'Chỉ người được duyệt mới xem được hồ sơ của bạn',
                value: _LocalSettings.privateAccount,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.privateAccount = value;
                  });
                },
              ),
              _SwitchTile(
                icon: Icons.alternate_email_rounded,
                title: 'Cho phép nhắc đến',
                subtitle: 'Người khác có thể nhắc đến bạn trong bài viết',
                value: _LocalSettings.allowMentions,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.allowMentions = value;
                  });
                },
              ),
              _SwitchTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Cho phép nhắn tin',
                subtitle: 'Người khác có thể gửi tin nhắn cho bạn',
                value: _LocalSettings.allowMessages,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.allowMessages = value;
                  });
                },
              ),
              _SwitchTile(
                icon: Icons.circle_outlined,
                title: 'Hiển thị trạng thái hoạt động',
                subtitle: 'Cho phép người khác biết khi bạn đang hoạt động',
                value: _LocalSettings.showActivityStatus,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.showActivityStatus = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Thông báo',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Tương tác',
            children: [
              _SwitchTile(
                icon: Icons.favorite_border_rounded,
                title: 'Lượt thích',
                subtitle: 'Thông báo khi có người thả tim bài viết của bạn',
                value: _LocalSettings.notifyLikes,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.notifyLikes = value;
                  });
                },
              ),
              _SwitchTile(
                icon: Icons.mode_comment_outlined,
                title: 'Bình luận',
                subtitle: 'Thông báo khi có người bình luận bài viết',
                value: _LocalSettings.notifyComments,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.notifyComments = value;
                  });
                },
              ),
              _SwitchTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Người theo dõi mới',
                subtitle: 'Thông báo khi có người theo dõi bạn',
                value: _LocalSettings.notifyFollows,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.notifyFollows = value;
                  });
                },
              ),
              _SwitchTile(
                icon: Icons.mail_outline_rounded,
                title: 'Tin nhắn',
                subtitle: 'Thông báo khi có tin nhắn mới',
                value: _LocalSettings.notifyMessages,
                onChanged: (value) {
                  setState(() {
                    _LocalSettings.notifyMessages = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  void _selectMode(String value) {
    setState(() {
      _LocalSettings.appearanceMode = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật lựa chọn giao diện'),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Giao diện',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Chế độ hiển thị',
            children: [
              _RadioTile(
                icon: Icons.phone_android_rounded,
                title: 'Theo hệ thống',
                subtitle: 'Sử dụng cài đặt giao diện của thiết bị',
                value: 'system',
                groupValue: _LocalSettings.appearanceMode,
                onChanged: _selectMode,
              ),
              _RadioTile(
                icon: Icons.light_mode_outlined,
                title: 'Sáng',
                subtitle: 'Giao diện nền sáng',
                value: 'light',
                groupValue: _LocalSettings.appearanceMode,
                onChanged: _selectMode,
              ),
              _RadioTile(
                icon: Icons.dark_mode_outlined,
                title: 'Tối',
                subtitle: 'Giao diện nền tối',
                value: 'dark',
                groupValue: _LocalSettings.appearanceMode,
                onChanged: _selectMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _NoticeBox(
            text:
            'Mục này mới lưu lựa chọn trong phiên app. Muốn đổi theme toàn app thật sự cần thêm ThemeProvider.',
          ),
        ],
      ),
    );
  }
}

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  void _selectLanguage(String value) {
    setState(() {
      _LocalSettings.language = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value == 'vi'
              ? 'Đã chọn Tiếng Việt'
              : 'English has been selected',
        ),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Ngôn ngữ',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Ngôn ngữ ứng dụng',
            children: [
              _RadioTile(
                icon: Icons.language_rounded,
                title: 'Tiếng Việt',
                subtitle: 'Ngôn ngữ hiện tại',
                value: 'vi',
                groupValue: _LocalSettings.language,
                onChanged: _selectLanguage,
              ),
              _RadioTile(
                icon: Icons.translate_rounded,
                title: 'English',
                subtitle: 'English interface',
                value: 'en',
                groupValue: _LocalSettings.language,
                onChanged: _selectLanguage,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _NoticeBox(
            text:
            'Mục này mới lưu lựa chọn trong phiên app. Muốn đổi toàn bộ text cần thêm localization.',
          ),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Trợ giúp',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpCard(
            question: 'Làm sao để đăng bài mới?',
            answer:
            'Nhấn nút dấu cộng ở thanh điều hướng dưới cùng, nhập nội dung rồi đăng bài.',
          ),
          SizedBox(height: 10),
          _HelpCard(
            question: 'Làm sao để chỉnh sửa hồ sơ?',
            answer:
            'Vào trang cá nhân, nhấn nút Chỉnh sửa để thay đổi tên hiển thị, tiểu sử hoặc ảnh đại diện.',
          ),
          SizedBox(height: 10),
          _HelpCard(
            question: 'Làm sao để đổi mật khẩu?',
            answer:
            'Vào Cài đặt > Mật khẩu và bảo mật > Đặt lại mật khẩu. Hệ thống sẽ gửi email đặt lại mật khẩu.',
          ),
          SizedBox(height: 10),
          _HelpCard(
            question: 'Vì sao tôi không thấy bài viết?',
            answer:
            'Hãy kiểm tra kết nối mạng hoặc kéo xuống để làm mới trang chủ.',
          ),
        ],
      ),
    );
  }
}

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SettingsAppBar(
        title: 'Giới thiệu ứng dụng',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text(
                      'T',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Threads Clone',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ứng dụng mạng xã hội mini được xây dựng bằng Flutter, Firebase và backend riêng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Thông tin',
            children: const [
              _InfoTile(
                title: 'Phiên bản',
                value: '1.0.0',
                icon: Icons.info_outline_rounded,
              ),
              _InfoTile(
                title: 'Nền tảng',
                value: 'Flutter',
                icon: Icons.flutter_dash_rounded,
              ),
              _InfoTile(
                title: 'Xác thực',
                value: 'Firebase Authentication',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const _SettingsAppBar({
    required this.title,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: AppColors.border,
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String nickname;
  final String username;
  final String email;
  final String? avatarUrl;
  final bool showArrow;

  const _AccountHeader({
    required this.nickname,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final usernameLabel = username.startsWith('@') ? username : '@$username';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inputFill,
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: AppColors.textSecondary,
                ),
              )
                  : const Icon(
                Icons.person_rounded,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  usernameLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            children: List.generate(children.length, (index) {
              final isLast = index == children.length - 1;

              return Column(
                children: [
                  children[index],
                  if (!isLast)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(left: 56),
                      color: AppColors.border,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 22,
      ),
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: _TileText(
              title: title,
              subtitle: subtitle,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _InlineEditableInfoTile extends StatelessWidget {
  final String title;
  final String displayValue;
  final IconData icon;
  final TextEditingController controller;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String? prefixText;
  final int maxLines;

  const _InlineEditableInfoTile({
    required this.title,
    required this.displayValue,
    required this.icon,
    required this.controller,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    this.prefixText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Row(
        crossAxisAlignment:
        isEditing ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                if (isEditing)
                  TextField(
                    controller: controller,
                    maxLines: maxLines,
                    enabled: !isSaving,
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      prefixText: prefixText,
                      prefixStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.textPrimary,
                          width: 1,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    displayValue,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isEditing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: isSaving ? null : onCancel,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 21,
                  ),
                ),
                IconButton(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  )
                      : const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 23,
                  ),
                ),
              ],
            )
          else
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: _TileText(
              title: title,
              subtitle: subtitle,
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.textPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _RadioTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      activeColor: AppColors.textPrimary,
      contentPadding: const EdgeInsets.only(left: 14, right: 6),
      secondary: _TileIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
        subtitle!,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: _TileText(
              title: title,
              subtitle: value,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;

  const _TileIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 19,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _TileText extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _TileText({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpCard({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.textPrimary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          question,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final String text;

  const _NoticeBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: const Center(
            child: Text(
              'Đăng xuất',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}