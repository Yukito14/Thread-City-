import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/post_media_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/reply_sheet.dart';
import '../widgets/video_player_widget.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<PostModel> _replies = [];
  bool _isLoading = true;
  String? _error;

  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReplies());
  }

  Future<void> _loadReplies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final replies = await context.read<PostProvider>().getReplies(widget.post.id);

      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleLike() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (uid == null) return;

    final originalIsLiked = _isLiked;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    final userProvider = context.read<UserProvider>();

    final successIsLiked = await postProvider.toggleLike(widget.post.id, uid);

    homeProvider.updatePostLike(widget.post.id, successIsLiked);
    userProvider.updatePostLike(widget.post.id, successIsLiked);

    if (successIsLiked == originalIsLiked && mounted) {
      setState(() {
        _isLiked = originalIsLiked;
        _likeCount = widget.post.likeCount;
      });
    }
  }

  void _openReplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReplySheet(
        post: widget.post,
        onReplySent: _loadReplies,
      ),
    );
  }

  void _navigateToProfile(BuildContext context, UserModel? author) {
    if (author == null) return;

    final loggedInUser = context.read<AuthProvider>().currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];

    final isMe = author.username == loggedInUser?['username'] ||
        author.id.toString() == loggedInUser?['id']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          currentUsername: author.username,
          currentNickname: author.nickname ?? author.username,
          viewingUserId: isMe ? loggedInUid : author.id.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Thread',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadReplies,
        color: Colors.black,
        child: _buildBody(),
      ),

      bottomNavigationBar: SafeArea(
        child: GestureDetector(
          onTap: _openReplySheet,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Trả lời ${widget.post.author?.username ?? ''}...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _replies.isEmpty) {
      return ListView(
        children: [
          _buildOriginalPost(),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null && _replies.isEmpty) {
      return ListView(
        children: [
          _buildOriginalPost(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _replies.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildOriginalPost();

        final reply = _replies[index - 1];

        return _ReplyCard(
          reply: reply,
          onReplyAdded: _loadReplies,
          originalAuthorId: widget.post.userId,
        );
      },
    );
  }

  Widget _buildOriginalPost() {
    final post = widget.post;
    final author = post.author;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(context, author),
                child: _buildAvatar(author?.avatarUrl, size: 44),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToProfile(context, author),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.username ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      if (author?.nickname != null &&
                          author!.nickname != author.username)
                        Text(
                          author.nickname!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Text(
                _timeAgo(post.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.more_horiz,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildRichContent(post.content),

          if (post.media.isNotEmpty) _buildMedia(post.media),

          const SizedBox(height: 16),

          Row(
            children: [
              GestureDetector(
                onTap: _handleLike,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                      color: _isLiked ? Colors.red : AppColors.icon,
                    ),

                    if (_likeCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$_likeCount',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 24),

              GestureDetector(
                onTap: _openReplySheet,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 24,
                      color: AppColors.icon,
                    ),

                    if (post.commentCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 24),

              _ActionBtn(
                icon: Icons.repeat_outlined,
                onTap: () => showThreadRepostSheet(context, post),
              ),

              const SizedBox(width: 24),

              _ActionBtn(
                icon: Icons.send_outlined,
                onTap: () => showThreadShareSheet(context, post),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';

    return '${diff.inDays}d';
  }
}

// ─────────────────────────────────────────────────────────────
// Global UI Helpers
// ─────────────────────────────────────────────────────────────

Widget _buildRichContent(String content, {bool isSmall = false}) {
  final List<TextSpan> spans = [];

  content.splitMapJoin(
    RegExp(r'#[^\s#.,!?]+'),
    onMatch: (Match match) {
      spans.add(
        TextSpan(
          text: match[0],
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      return '';
    },
    onNonMatch: (String text) {
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.black,
            fontSize: isSmall ? 14 : 16,
          ),
        ),
      );
      return '';
    },
  );

  return RichText(
    text: TextSpan(
      style: TextStyle(
        fontSize: isSmall ? 14 : 16,
        height: 1.4,
        color: Colors.black,
      ),
      children: spans,
    ),
  );
}

Widget _buildMedia(List<PostMediaModel> media) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: media.length == 1
          ? media[0].mediaType == MediaType.video
          ? VideoPlayerWidget(videoUrl: media[0].mediaUrl)
          : Image.network(
        media[0].mediaUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
        const SizedBox(),
      )
          : SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: media.length,
          itemBuilder: (context, index) {
            final item = media[index];

            return Container(
              margin: const EdgeInsets.only(right: 8),
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.mediaType == MediaType.video
                    ? VideoPlayerWidget(videoUrl: item.mediaUrl)
                    : Image.network(
                  item.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Widget _buildAvatar(String? url, {double size = 40}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[200],
    ),
    child: ClipOval(
      child: url != null && url.isNotEmpty
          ? Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person,
          color: Colors.grey,
          size: size * 0.6,
        ),
      )
          : Icon(
        Icons.person,
        color: Colors.grey,
        size: size * 0.6,
      ),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    this.onTap,
    this.color = AppColors.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 24,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reply Card
// ─────────────────────────────────────────────────────────────

class _ReplyCard extends StatefulWidget {
  final PostModel reply;
  final VoidCallback? onReplyAdded;
  final int originalAuthorId;

  const _ReplyCard({
    required this.reply,
    this.onReplyAdded,
    required this.originalAuthorId,
  });

  @override
  State<_ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<_ReplyCard> {
  late bool _isLiked;
  late int _likeCount;
  bool _showAllReplies = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reply.isLiked;
    _likeCount = widget.reply.likeCount;
    _showAllReplies = false;
  }

  void _handleLike() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (uid == null) return;

    final originalIsLiked = _isLiked;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    final userProvider = context.read<UserProvider>();

    final successIsLiked = await postProvider.toggleLike(widget.reply.id, uid);

    homeProvider.updatePostLike(widget.reply.id, successIsLiked);
    userProvider.updatePostLike(widget.reply.id, successIsLiked);

    if (successIsLiked == originalIsLiked && mounted) {
      setState(() {
        _isLiked = originalIsLiked;
        _likeCount = widget.reply.likeCount;
      });
    }
  }

  void _navigateToProfile(BuildContext context, UserModel? author) {
    if (author == null) return;

    final loggedInUser = context.read<AuthProvider>().currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];

    final isMe = author.username == loggedInUser?['username'] ||
        author.id.toString() == loggedInUser?['id']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          currentUsername: author.username,
          currentNickname: author.nickname ?? author.username,
          viewingUserId: isMe ? loggedInUid : author.id.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.reply.author;

    PostModel? authorReply;
    for (final r in widget.reply.replies) {
      if (r.userId == widget.originalAuthorId) {
        authorReply = r;
        break;
      }
    }

    final totalReplies = widget.reply.replies.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: widget.reply),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(context, author),
                        child: _buildAvatar(author?.avatarUrl, size: 36),
                      ),

                      if (totalReplies > 0)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.grey[200],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _navigateToProfile(context, author),
                                child: Text(
                                  author?.username ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            Text(
                              _timeAgo(widget.reply.createdAt),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        _buildRichContent(
                          widget.reply.content,
                          isSmall: true,
                        ),

                        if (widget.reply.media.isNotEmpty)
                          _buildMedia(widget.reply.media),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: _handleLike,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24,
                                    color: _isLiked
                                        ? Colors.red
                                        : AppColors.icon,
                                  ),

                                  if (_likeCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '$_likeCount',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 24),

                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ReplySheet(
                                    post: widget.reply,
                                    onReplySent: widget.onReplyAdded,
                                  ),
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 24,
                                    color: AppColors.icon,
                                  ),

                                  if (widget.reply.commentCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.reply.commentCount}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 24),

                            _ActionBtn(
                              icon: Icons.repeat_outlined,
                              onTap: () =>
                                  showThreadRepostSheet(context, widget.reply),
                            ),

                            const SizedBox(width: 24),

                            _ActionBtn(
                              icon: Icons.send_outlined,
                              onTap: () =>
                                  showThreadShareSheet(context, widget.reply),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showAllReplies && totalReplies >= 1 && totalReplies <= 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < widget.reply.replies.length; i++)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 48,
                            child: CustomPaint(
                              painter: ThreadCurvePainter(
                                color: Colors.grey[200]!,
                                isLast: i == widget.reply.replies.length - 1,
                              ),
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildAuthorReplyBranch(
                                widget.reply.replies[i],
                                isAuthor: widget.reply.replies[i].userId ==
                                    widget.originalAuthorId,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else if (!_showAllReplies && authorReply != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 48,
                      child: CustomPaint(
                        painter: ThreadCurvePainter(
                          color: Colors.grey[200]!,
                          isLast: true,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAuthorReplyBranch(
                          authorReply,
                          isAuthor: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (totalReplies >= 1 &&
              totalReplies <= 3 &&
              !_showAllReplies &&
              (authorReply == null || totalReplies > 1))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 24,
                    child: CustomPaint(
                      painter: ThreadCurvePainter(
                        color: Colors.grey[200]!,
                        isLast: true,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllReplies = true;
                      });
                    },
                    child: Text(
                      'Xem thêm ${totalReplies - (authorReply != null ? 1 : 0)} phản hồi...',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorReplyBranch(
      PostModel authorReply, {
        bool isAuthor = false,
      }) {
    final author = authorReply.author;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(context, author),
          child: _buildAvatar(author?.avatarUrl, size: 24),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(context, author),
                    child: Text(
                      author?.username ?? 'Tác giả',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  if (isAuthor) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Tác giả',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  Text(
                    _timeAgo(authorReply.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              _buildRichContent(
                authorReply.content,
                isSmall: true,
              ),

              if (authorReply.media.isNotEmpty) _buildMedia(authorReply.media),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';

    return '${diff.inDays}d';
  }
}

// ─────────────────────────────────────────────────────────────
// Thread Curve Painter
// ─────────────────────────────────────────────────────────────

class ThreadCurvePainter extends CustomPainter {
  final Color color;
  final bool isLast;

  const ThreadCurvePainter({
    required this.color,
    this.isLast = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    const double startX = 18.0;
    const double cornerY = 12.0;

    path.moveTo(startX, 0);

    if (isLast) {
      path.lineTo(startX, cornerY);

      path.quadraticBezierTo(
        startX,
        18.0,
        size.width,
        18.0,
      );
    } else {
      path.lineTo(startX, size.height);

      final branchPath = Path();
      branchPath.moveTo(startX, cornerY);

      branchPath.quadraticBezierTo(
        startX,
        18.0,
        size.width,
        18.0,
      );

      canvas.drawPath(branchPath, paint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ThreadCurvePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isLast != isLast;
  }
}

// ─────────────────────────────────────────────────────────────
// Share Sheet
// ─────────────────────────────────────────────────────────────

void showThreadShareSheet(BuildContext context, PostModel post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ThreadShareSheet(post: post),
  );
}

class _ThreadShareSheet extends StatelessWidget {
  final PostModel post;

  const _ThreadShareSheet({
    required this.post,
  });

  String get _postLink {
    return 'https://threadcity.app/posts/${post.id}';
  }

  String get _shareText {
    final username = post.author?.username ?? 'user';
    final content = post.content.trim();

    return 'Xem bài viết của @$username trên Thread City:\n\n$content\n\n$_postLink';
  }

  Future<bool> _tryLaunchExternal(List<Uri> uris) async {
    for (final uri in uris) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) return true;
      } catch (_) {
        continue;
      }
    }

    return false;
  }

  Future<void> _openSystemShare(BuildContext context) async {
    HapticFeedback.lightImpact();

    final text = _shareText;

    Navigator.pop(context);

    await Future.delayed(const Duration(milliseconds: 150));

    await SharePlus.instance.share(
      ShareParams(text: text),
    );
  }

  Future<void> _openMessenger(BuildContext context) async {
    HapticFeedback.lightImpact();

    final link = _postLink;
    final text = _shareText;

    Navigator.pop(context);

    await Future.delayed(const Duration(milliseconds: 150));

    final encodedLink = Uri.encodeComponent(link);

    final launched = await _tryLaunchExternal([
      Uri.parse('fb-messenger://share?link=$encodedLink'),
      Uri.parse('fb-messenger://share/?link=$encodedLink'),
      Uri.parse('fb-messenger://compose'),
    ]);

    if (!launched) {
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    }
  }

  Future<void> _openInstagram(BuildContext context) async {
    HapticFeedback.lightImpact();

    final text = _shareText;
    final encodedText = Uri.encodeComponent(text);

    Navigator.pop(context);

    await Future.delayed(const Duration(milliseconds: 150));

    final launched = await _tryLaunchExternal([
      Uri.parse('instagram://sharesheet?text=$encodedText'),
      Uri.parse('instagram://direct-inbox'),
      Uri.parse('instagram://app'),
    ]);

    if (!launched) {
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(
      ClipboardData(text: _postLink),
    );

    Navigator.pop(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final author = post.author;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF101010),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                    size: 24,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Tìm kiếm trong cá nhân Threads',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _ShareUserItem(
                    avatarUrl: author?.avatarUrl,
                    username: author?.username ?? 'author',
                    subtitle: author?.nickname ?? 'Tác giả',
                  ),

                  const _ShareUserItem(
                    username: 'Messenger',
                    subtitle: 'Gửi qua chat',
                    icon: Icons.messenger_outline,
                  ),

                  const _ShareUserItem(
                    username: 'Instagram',
                    subtitle: 'Tin nhắn IG',
                    icon: Icons.camera_alt_outlined,
                  ),

                  const _ShareUserItem(
                    username: 'Bạn bè',
                    subtitle: 'Chia sẻ nhanh',
                    icon: Icons.group_outlined,
                  ),

                  const _ShareUserItem(
                    username: 'Khác',
                    subtitle: 'Ứng dụng khác',
                    icon: Icons.more_horiz,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              height: 0.5,
              color: Colors.white10,
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _ShareActionItem(
                    icon: Icons.messenger_outline,
                    label: 'Messenger',
                    color: const Color(0xFF007AFF),
                    onTap: () => _openMessenger(context),
                  ),

                  _ShareActionItem(
                    icon: Icons.link_rounded,
                    label: 'Liên kết',
                    onTap: () => _copyLink(context),
                  ),

                  _ShareActionItem(
                    icon: Icons.send_outlined,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    onTap: () => _openInstagram(context),
                  ),

                  _ShareActionItem(
                    icon: Icons.ios_share_rounded,
                    label: 'Xem thêm',
                    onTap: () => _openSystemShare(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareUserItem extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final String subtitle;
  final IconData? icon;

  const _ShareUserItem({
    this.avatarUrl,
    required this.username,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF222225),
              border: Border.all(
                color: Colors.white10,
                width: 0.8,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  icon ?? Icons.person,
                  color: Colors.white70,
                  size: 28,
                ),
              )
                  : Icon(
                icon ?? Icons.person,
                color: Colors.white70,
                size: 28,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ShareActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 104,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1C1C1E),
              ),
              child: Icon(
                icon,
                color: color ?? Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Repost Sheet
// ─────────────────────────────────────────────────────────────

void showThreadRepostSheet(BuildContext context, PostModel post) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ThreadRepostSheet(post: post),
  );
}

class _ThreadRepostSheet extends StatelessWidget {
  final PostModel post;

  const _ThreadRepostSheet({
    required this.post,
  });

  void _handleRepost(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    HapticFeedback.mediumImpact();

    Navigator.pop(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã bấm đăng lại. Cần nối API repost ở PostProvider.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    // Sau này nếu backend có API repost thì thay bằng:
    //
    // await context.read<PostProvider>().repost(post.id);
    // context.read<HomeProvider>().refreshFeed();
  }

  void _handleQuote(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    HapticFeedback.lightImpact();

    Navigator.pop(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Tính năng trích dẫn bài viết sẽ làm sau.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final author = post.author;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildAvatar(author?.avatarUrl, size: 36),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      author?.username ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _RepostMenuItem(
              icon: Icons.repeat_rounded,
              title: 'Đăng lại',
              subtitle: 'Đăng lại bài viết này lên trang cá nhân của bạn',
              onTap: () => _handleRepost(context),
            ),

            _RepostMenuItem(
              icon: Icons.edit_note_rounded,
              title: 'Trích dẫn',
              subtitle: 'Thêm suy nghĩ của bạn trước khi đăng lại',
              onTap: () => _handleQuote(context),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RepostMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RepostMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.black87,
                  size: 23,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}