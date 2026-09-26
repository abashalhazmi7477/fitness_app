import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/app_translations.dart';
import '../services/language_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  static const Color green = Color(0xFF19A974);
  static const Color background = Color(0xFF0D1110);
  static const Color cardColor = Color(0xFF151B19);
  static const Color fieldColor = Color(0xFF1D211F);
  static const Color borderColor = Color(0xFF292E2B);

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> receivedRequests = [];
  List<Map<String, dynamic>> sentRequests = [];

  bool isLoading = true;
  bool isSearching = false;
  int selectedTab = 0;

  String? get currentUsername {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['username']?.toString();
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _searchUsers();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadFriends(),
        _loadRequests(),
      ]);
    } catch (_) {}

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFriends() async {
    final username = currentUsername;
    if (username == null || username.isEmpty) return;

    final data = await SupabaseService.get(
      'friends',
      query:
          '?or=(user_username.eq.${Uri.encodeQueryComponent(username)},friend_username.eq.${Uri.encodeQueryComponent(username)})&order=created_at.desc',
    );

    final result = <Map<String, dynamic>>[];

    for (final row in data) {
      final user = row['user_username']?.toString();
      final friend = row['friend_username']?.toString();

      if (user == username && friend != null) {
        result.add({'username': friend});
      } else if (friend == username && user != null) {
        result.add({'username': user});
      }
    }

    if (mounted) {
      setState(() => friends = result);
    }
  }

  Future<void> _loadRequests() async {
    final username = currentUsername;
    if (username == null || username.isEmpty) return;

    final encoded = Uri.encodeQueryComponent(username);

    final received = await SupabaseService.get(
      'friend_requests',
      query:
          '?receiver_username=eq.$encoded&status=eq.pending&order=created_at.desc',
    );

    final sent = await SupabaseService.get(
      'friend_requests',
      query:
          '?sender_username=eq.$encoded&status=eq.pending&order=created_at.desc',
    );

    if (mounted) {
      setState(() {
        receivedRequests = received;
        sentRequests = sent;
      });
    }
  }

  Future<void> _searchUsers() async {
  final query = searchController.text.trim();

  if (query.isEmpty) {
    if (mounted) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
    }
    return;
  }

  if (mounted) setState(() => isSearching = true);

  try {
    final encoded = Uri.encodeQueryComponent(query);

    final data = await SupabaseService.get(
      'profiles',
      query:
          '?username=ilike.*$encoded*&select=id,username,name,full_name,goal,age',
    );

    final myUsername = currentUsername?.trim();

    final filtered = data.where((user) {
      final username = user['username']?.toString().trim() ?? '';
      return username.isNotEmpty &&
          username.toLowerCase() != myUsername?.toLowerCase();
    }).toList();

    if (mounted) {
      setState(() {
        searchResults = filtered;
        isSearching = false;
      });
    }
  } catch (e) {
    debugPrint('SEARCH ERROR: $e');

    if (mounted) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
    }
  }
}
  bool _isFriend(String username) {
    return friends.any(
      (friend) => friend['username']?.toString() == username,
    );
  }

  bool _isSent(String username) {
    return sentRequests.any(
      (request) =>
          request['receiver_username']?.toString() == username,
    );
  }

  bool _isReceived(String username) {
    return receivedRequests.any(
      (request) =>
          request['sender_username']?.toString() == username,
    );
  }

  String _userName(Map<String, dynamic> user) {
    final name = user['name']?.toString().trim() ?? '';
    final fullName = user['full_name']?.toString().trim() ?? '';

    bool valid(String value) {
      return value.isNotEmpty &&
          !value.contains('@') &&
          !value.contains('.');
    }

    if (valid(name)) return name;
    if (valid(fullName)) return fullName;

    return 'مستخدم';
  }

  String _requestName(String username) {
    for (final user in searchResults) {
      if (user['username']?.toString() == username) {
        return _userName(user);
      }
    }

    return 'مستخدم';
  }

  Future<void> _sendFriendRequest(String username) async {
    final sender = currentUsername;

    if (sender == null || sender.isEmpty) {
      _showMessage(AppTranslations.get('login_first'));
      return;
    }

    if (username == sender ||
        _isFriend(username) ||
        _isSent(username)) {
      return;
    }

    if (_isReceived(username)) {
      await _acceptRequest(username);
      return;
    }

    try {
      await SupabaseService.post(
        'friend_requests',
        {
          'sender_username': sender,
          'receiver_username': username,
          'status': 'pending',
        },
      );

      await _loadRequests();
      _showMessage(AppTranslations.get('request_sent'));
    } catch (_) {
      _showMessage(AppTranslations.get('request_send_error'));
    }
  }

  Future<void> _acceptRequest(String username) async {
    final me = currentUsername;

    if (me == null || me.isEmpty) return;

    try {
      final request = receivedRequests.firstWhere(
        (item) =>
            item['sender_username']?.toString() == username,
      );

      final requestId = request['id']?.toString();

      if (requestId != null) {
        await SupabaseService.update(
          'friend_requests',
          'id=eq.$requestId',
          {'status': 'accepted'},
        );
      }

      await SupabaseService.post(
        'friends',
        {
          'user_username': me,
          'friend_username': username,
        },
      );

      await _loadData();

      _showMessage(AppTranslations.get('friend_added'));
    } catch (_) {
      _showMessage(AppTranslations.get('accept_error'));
    }
  }

  Future<void> _rejectRequest(String username) async {
    try {
      final request = receivedRequests.firstWhere(
        (item) =>
            item['sender_username']?.toString() == username,
      );

      final requestId = request['id']?.toString();

      if (requestId != null) {
        await SupabaseService.update(
          'friend_requests',
          'id=eq.$requestId',
          {'status': 'rejected'},
        );
      }

      await _loadRequests();
      _showMessage(AppTranslations.get('request_rejected'));
    } catch (_) {
      _showMessage(AppTranslations.get('reject_error'));
    }
  }

  Future<void> _cancelRequest(String username) async {
    try {
      final request = sentRequests.firstWhere(
        (item) =>
            item['receiver_username']?.toString() == username,
      );

      final requestId = request['id']?.toString();

      if (requestId != null) {
        await SupabaseService.delete(
          'friend_requests',
          'id=eq.$requestId',
        );
      }

      await _loadRequests();
      _showMessage(AppTranslations.get('request_cancelled'));
    } catch (_) {
      _showMessage(AppTranslations.get('cancel_error'));
    }
  }

  Future<void> _removeFriend(String username) async {
    final me = currentUsername;

    if (me == null || me.isEmpty) return;

    try {
      await SupabaseService.delete(
        'friends',
        'user_username=eq.${Uri.encodeQueryComponent(me)}&friend_username=eq.${Uri.encodeQueryComponent(username)}',
      );

      await SupabaseService.delete(
        'friends',
        'user_username=eq.${Uri.encodeQueryComponent(username)}&friend_username=eq.${Uri.encodeQueryComponent(me)}',
      );

      await _loadFriends();
      _showMessage(AppTranslations.get('friend_removed'));
    } catch (_) {
      _showMessage(AppTranslations.get('remove_error'));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor: cardColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showUserProfile(Map<String, dynamic> user) {
    final username = user['username']?.toString() ?? '';
    final name = _userName(user);
    final age = user['age']?.toString() ?? '';
    final goal = user['goal']?.toString() ?? AppTranslations.get('fitness_user');

    showModalBottomSheet(
      context: context,
      backgroundColor: background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Directionality(
          textDirection: LanguageService.direction,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  SizedBox(height: 24),
                  CircleAvatar(
                    radius: 38,
                    backgroundColor:
                        green.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.person,
                      color: green,
                      size: 38,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        if (age.isNotEmpty)
                          _profileRow(
                            Icons.cake_outlined,
                            AppTranslations.get('age'),
                            '$age سنة',
                          ),
                        if (age.isNotEmpty)
                          SizedBox(height: 14),
                        _profileRow(
                          Icons.flag_outlined,
                          AppTranslations.get('goal'),
                          goal,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _buildProfileAction(username),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _profileRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: green,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAction(String username) {
    if (_isFriend(username)) {
      return OutlinedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          await _removeFriend(username);
        },
        icon: Icon(Icons.person_remove_outlined),
        label: Text(AppTranslations.get('remove_friend')),
      );
    }

    if (_isSent(username)) {
      return OutlinedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          await _cancelRequest(username);
        },
        icon: Icon(Icons.close),
        label: Text(AppTranslations.get('cancel_request')),
      );
    }

    if (_isReceived(username)) {
      return ElevatedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          await _acceptRequest(username);
        },
        icon: Icon(Icons.person_add),
        label: Text(AppTranslations.get('accept_friend_request')),
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        Navigator.pop(context);
        await _sendFriendRequest(username);
      },
      icon: Icon(Icons.person_add_outlined),
      label: Text(AppTranslations.get('add_friend')),
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white),
        textDirection: LanguageService.direction,
        decoration: InputDecoration(
          hintText: AppTranslations.get('search_username'),
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.search, color: green),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: searchController.clear,
                  icon: Icon(
                    Icons.close,
                    color: Colors.white54,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      (AppTranslations.get('my_friends'), friends.length),
      (AppTranslations.get('requests'), receivedRequests.length),
      (AppTranslations.get('sent'), sentRequests.length),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) {
            final isSelected = selectedTab == index;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => selectedTab = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? green
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tabs[index].$1,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white60,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '${tabs[index].$2}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isSearching) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: green),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Expanded(
        child: _buildEmptyState(
          icon: Icons.search_off,
          title: AppTranslations.get('user_not_found'),
          subtitle: AppTranslations.get('check_username'),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 14),
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          return _buildUserCard(searchResults[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _showUserProfile(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: green.withValues(alpha: 0.13),
                child: Icon(
                  Icons.person,
                  color: green,
                  size: 28,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName(user),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user['goal']?.toString() ?? AppTranslations.get('fitness_user'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildUserAction(username),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAction(String username) {
    if (_isFriend(username)) {
      return Text(
        AppTranslations.get('friend'),
        style: TextStyle(
          color: green,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (_isSent(username)) {
      return OutlinedButton(
        onPressed: () => _cancelRequest(username),
        child: Text(AppTranslations.get('sent')),
      );
    }

    if (_isReceived(username)) {
      return ElevatedButton(
        onPressed: () => _acceptRequest(username),
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
        child: Text(AppTranslations.get('accept')),
      );
    }

    return ElevatedButton(
      onPressed: () => _sendFriendRequest(username),
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      child: Text(AppTranslations.get('add')),
    );
  }

  Widget _buildFriendsList() {
    if (friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: AppTranslations.get('no_friends'),
        subtitle: AppTranslations.get('add_new_friends'),
      );
    }

    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final username =
            friends[index]['username']?.toString() ?? '';

        return _buildFriendItem(username);
      },
    );
  }

  Widget _buildFriendItem(String username) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.get(
        'profiles',
        query:
            '?username=eq.${Uri.encodeQueryComponent(username)}&select=username,name,full_name,goal,age',
      ),
      builder: (context, snapshot) {
        final user = snapshot.data?.isNotEmpty == true
            ? snapshot.data!.first
            : {
                'username': username,
                'name': 'مستخدم',
                'goal': AppTranslations.get('fitness_user'),
              };

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: green.withValues(alpha: 0.13),
                child: Icon(
                  Icons.person,
                  color: green,
                  size: 28,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName(user),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user['goal']?.toString() ?? AppTranslations.get('fitness_user'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showUserProfile(user),
                icon: Icon(
                  Icons.chevron_left,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceivedRequests() {
    if (receivedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_alt_1_outlined,
        title: AppTranslations.get('no_new_requests'),
        subtitle: AppTranslations.get('incoming_requests'),
      );
    }

    return ListView.builder(
      itemCount: receivedRequests.length,
      itemBuilder: (context, index) {
        return _buildRequestItem(receivedRequests[index]);
      },
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final username =
        request['sender_username']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: green.withValues(alpha: 0.13),
            child: Icon(
              Icons.person,
              color: green,
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _requestName(username),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptRequest(username),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(AppTranslations.get('accept')),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectRequest(username),
                        child: Text('رفض'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequests() {
    if (sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: AppTranslations.get('no_sent_requests'),
        subtitle: AppTranslations.get('sent_requests_here'),
      );
    }

    return ListView.builder(
      itemCount: sentRequests.length,
      itemBuilder: (context, index) {
        final username =
            sentRequests[index]['receiver_username']
                ?.toString() ??
            '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: green.withValues(alpha: 0.13),
                child: Icon(
                  Icons.person,
                  color: green,
                  size: 26,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _requestName(username),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppTranslations.get('waiting_reply'),
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _cancelRequest(username),
                child: Text(AppTranslations.get('cancel')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: green,
                size: 38,
              ),
            ),
            SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (selectedTab) {
      case 1:
        return Expanded(child: _buildReceivedRequests());
      case 2:
        return Expanded(child: _buildSentRequests());
      default:
        return Expanded(child: _buildFriendsList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: LanguageService.direction,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          title: Text(
            AppTranslations.get('friends'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (receivedRequests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => selectedTab = 1);
                      },
                      icon: Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${receivedRequests.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(color: green),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  16,
                ),
                child: Column(
                  children: [
                    _buildSearchCard(),
                    SizedBox(height: 14),
                    if (searchController.text.trim().isNotEmpty)
                      _buildSearchResults()
                    else ...[
                      _buildTabs(),
                      SizedBox(height: 14),
                      _buildCurrentTab(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}


