import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'post_page.dart';
import 'group_type_results_screen.dart';

class SearchPostsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const SearchPostsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<SearchPostsScreen> createState() => _SearchPostsScreenState();
}

class _SearchPostsScreenState extends State<SearchPostsScreen> {
  List<GroupPostModel> posts = [];
  bool isLoading = true;
  String selectedType = "";
  String searchText = "";
  int selectedTab = 0; // 0 = Posts, 1 = People
  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    final data = await ApiService.fetchPosts();
    if (!mounted) return;

    setState(() {
      posts = data;
      isLoading = false;
    });
  }

  List<GroupPostModel> get filteredPosts {
    return posts.where((p) {
      final matchesType = selectedType.isEmpty ||
          p.postType.toLowerCase() == selectedType.toLowerCase();

      final text = searchText.toLowerCase();

      final matchesSearch = text.isEmpty ||
          p.content.toLowerCase().contains(text) ||
          p.productName.toLowerCase().contains(text) ||
          p.userName.toLowerCase().contains(text) ||
          p.groupTitle.toLowerCase().contains(text) ||
          p.postType.toLowerCase().contains(text);

      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _searchBar(),
            _tabs(),
            Expanded(
              child: selectedTab == 1
                  ? _peopleCategories()
                  : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : searchText.isNotEmpty
                          ? _postsList()
                          : selectedType.isEmpty
                              ? _categories()
                              : _postsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _peopleCategories() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        _categoryCard(
          title: "Skin types",
          image: "assets/images/skint.jpg",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupTypeResultsScreen(
                  title: "Search by skin type",
                  groupType: "skin_type",
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _categoryCard(
          title: "Skin concerns",
          image: "assets/images/skinc.jpeg",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupTypeResultsScreen(
                  title: "Search by skin concern",
                  groupType: "skin_types",
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _categoryCard(
          title: "Skin tones",
          image: "assets/images/skintones.jpg",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupTypeResultsScreen(
                  title: "Search by skin tone",
                  groupType: "skin_tones",
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const Spacer(),
          Text(
            "Skinova.",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5B2333),
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none_rounded, size: 27),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              searchText = value.trim();
            });
          },
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: const Color(0xFF2A2A2A),
          ),
          decoration: InputDecoration(
            hintText: "Search posts or people",
            hintStyle: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFFB2B2B2),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFB2B2B2),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEDEDED)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = 0;
                selectedType = "";
                searchText = "";
              });
            },
            child: _tab("Posts", selectedTab == 0),
          ),
          const SizedBox(width: 44),
          GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = 1;
                selectedType = "";
                searchText = "";
              });
            },
            child: _tab("People", selectedTab == 1),
          ),
        ],
      ),
    );
  }

  Widget _tab(String title, bool active) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: active ? Colors.black : Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 72,
          height: 3,
          color: active ? Colors.black : Colors.transparent,
        ),
      ],
    );
  }

  Widget _categories() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        _categoryCard(
          title: "Questions",
          image: "assets/images/q.jpg",
          onTap: () => setState(() => selectedType = "question"),
        ),
        const SizedBox(height: 16),
        _categoryCard(
          title: "Reviews",
          image: "assets/images/r.jpg",
          onTap: () => setState(() => selectedType = "review"),
        ),
        const SizedBox(height: 16),
        _categoryCard(
          title: "Updates",
          image: "assets/images/u.jpg",
          onTap: () => setState(() => selectedType = "update"),
        ),
      ],
    );
  }

  Widget _categoryCard({
    required String title,
    required String image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 115,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
              opacity: 0.45,
            ),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _postsList() {
    final list = filteredPosts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => selectedType = ""),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                searchText.isNotEmpty
                    ? "Search Results"
                    : selectedType[0].toUpperCase() + selectedType.substring(1),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("No posts found"))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return PostCard(
                      post: list[index],
                      currentUserId: widget.userId,
                      currentUserName: widget.userName,
                      onDelete: loadPosts,
                      onRefresh: loadPosts,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
