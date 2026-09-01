import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase optional local init: $e");
  }
  runApp(const ApexStreamApp());
}

// ---------------- GLOBAL PRE-LOADED DEMO NETWORK DATA ----------------
final List<Map<String, dynamic>> initialVideos = [
  {
    'id': 'vid_101',
    'title': 'High-Speed Hypercar Drift & Racing In The City | 4K 60FPS',
    'channel': 'Zenith Gaming Hub',
    'avatar': 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150',
    'views': '1.2M views',
    'time': '2 hours ago',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'likes': 14200,
    'subscribers': '450K',
  },
  {
    'id': 'vid_102',
    'title': 'Ultimate Open World Gameplay & Supercar Tuning Showcase',
    'channel': 'Apex Velocity',
    'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'views': '840K views',
    'time': '5 hours ago',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'likes': 9800,
    'subscribers': '210K',
  },
  {
    'id': 'vid_103',
    'title': 'Top 10 Football Legends Attitude & Unstoppable Goals Moments',
    'channel': 'Pro Sports Arena',
    'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
    'views': '3.4M views',
    'time': '1 day ago',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'likes': 85400,
    'subscribers': '1.1M',
  },
];

final List<Map<String, dynamic>> initialShorts = [
  {
    'id': 'short_1',
    'creator': 'VelocityRider',
    'title': 'Wait for the crazy drift! 🔥🏎️ #racing #hypercar',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'likes': '245K',
    'comments': '1,420',
  },
  {
    'id': 'short_2',
    'creator': 'CR7_Zenith',
    'title': 'Unstoppable clutch moment 🔥⚽ #attitude #skills',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'likes': '512K',
    'comments': '3,890',
  },
];

class ApexStreamApp extends StatelessWidget {
  const ApexStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ApexStream',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFFF0033),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0F0F),
          selectedItemColor: Color(0xFFFF0033),
          unselectedItemColor: Colors.white70,
        ),
      ),
      home: const MainAppNavigation(),
    );
  }
}

// ---------------- MAIN NAVIGATION ----------------
class MainAppNavigation extends StatefulWidget {
  const MainAppNavigation({super.key});

  @override
  State<MainAppNavigation> createState() => _MainAppNavigationState();
}

class _MainAppNavigationState extends State<MainAppNavigation> {
  int _tabIndex = 0;

  final List<Widget> _pages = const [
    HomeExploreScreen(),
    FullscreenReelsFeed(),
    SubscriptionsScreen(),
    ChannelProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: 'Shorts'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions_outlined), activeIcon: Icon(Icons.subscriptions), label: 'Subs'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), activeIcon: Icon(Icons.account_circle), label: 'Studio'),
        ],
      ),
    );
  }
}

// ---------------- 1. HOME & EXPLORE FEED ----------------
class HomeExploreScreen extends StatefulWidget {
  const HomeExploreScreen({super.key});

  @override
  State<HomeExploreScreen> createState() => _HomeExploreScreenState();
}

class _HomeExploreScreenState extends State<HomeExploreScreen> {
  String selectedFilter = 'All';
  final List<String> tags = ['All', 'Car Racing', 'Gaming', 'Action', 'Live', '4K 60FPS', 'Anime', 'Football'];

  void _openUploadSheet() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final channelCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud_upload_outlined, color: Color(0xFFFF0033)),
                SizedBox(width: 8),
                Text('Publish to Decentralized Network', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Video Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: channelCtrl, decoration: const InputDecoration(labelText: 'Channel / Creator Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Direct MP4 URL / IPFS Gateway', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0033),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                  setState(() {
                    initialVideos.insert(0, {
                      'id': 'vid_${DateTime.now().millisecondsSinceEpoch}',
                      'title': titleCtrl.text.trim(),
                      'channel': channelCtrl.text.isEmpty ? 'K09 Creator' : channelCtrl.text.trim(),
                      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                      'views': 'Just now',
                      'time': '1 min ago',
                      'videoUrl': urlCtrl.text.trim(),
                      'likes': 1,
                      'subscribers': '1',
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Publish Video Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0033), size: 30),
            SizedBox(width: 8),
            Text('ApexStream', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.8)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFFF0033), size: 28), onPressed: _openUploadSheet),
        ],
      ),
      body: Column(
        children: [
          // Filter Tags
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: tags.length,
              itemBuilder: (context, i) {
                bool isSelected = selectedFilter == tags[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(tags[i]),
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    backgroundColor: const Color(0xFF222222),
                    selectedColor: Colors.white,
                    onSelected: (val) => setState(() => selectedFilter = tags[i]),
                  ),
                );
              },
            ),
          ),
          // Videos Feed
          Expanded(
            child: ListView.builder(
              itemCount: initialVideos.length,
              itemBuilder: (context, index) {
                return VideoFeedCard(videoData: initialVideos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 2. VIDEO PLAYER CARD COMPONENT ----------------
class VideoFeedCard extends StatefulWidget {
  final Map<String, dynamic> videoData;
  const VideoFeedCard({super.key, required this.videoData});

  @override
  State<VideoFeedCard> createState() => _VideoFeedCardState();
}

class _VideoFeedCardState extends State<VideoFeedCard> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isLiked = false;
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  void _initVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoData['videoUrl']));
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFFF0033),
        handleColor: const Color(0xFFFF0033),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator(color: Color(0xFFFF0033))),
          ),
          // Meta details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.videoData['avatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.videoData['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.videoData['channel']} • ${widget.videoData['views']} • ${widget.videoData['time']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Subscribe Toggle
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubscribed ? const Color(0xFF2A2A2A) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                  onPressed: () => setState(() => isSubscribed = !isSubscribed),
                  child: Text(
                    isSubscribed ? 'Subscribed' : 'Subscribe',
                    style: TextStyle(
                      color: isSubscribed ? Colors.white70 : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => isLiked = !isLiked),
                  child: Row(
                    children: [
                      Icon(isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, color: isLiked ? const Color(0xFFFF0033) : Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text('${widget.videoData['likes'] + (isLiked ? 1 : 0)}'),
                    ],
                  ),
                ),
                const SizedBox(width: 25),
                const Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 20),
                    SizedBox(width: 6),
                    Text('Comments'),
                  ],
                ),
                const SizedBox(width: 25),
                const Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 6),
                    Text('Share'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. FULLSCREEN VERTICAL REELS / SHORTS ----------------
class FullscreenReelsFeed extends StatelessWidget {
  const FullscreenReelsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: initialShorts.length,
      itemBuilder: (context, index) {
        return SingleShortViewer(shortData: initialShorts[index]);
      },
    );
  }
}

class SingleShortViewer extends StatefulWidget {
  final Map<String, dynamic> shortData;
  const SingleShortViewer({super.key, required this.shortData});

  @override
  State<SingleShortViewer> createState() => _SingleShortViewerState();
}

class _SingleShortViewerState extends State<SingleShortViewer> {
  late VideoPlayerController _controller;
  bool liked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.shortData['videoUrl']))
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Color(0xFFFF0033))),
        // Creator Overlay Info
        Positioned(
          bottom: 30,
          left: 15,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${widget.shortData['creator']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.shortData['title'], style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        // Floating Action Buttons
        Positioned(
          bottom: 40,
          right: 15,
          child: Column(
            children: [
              IconButton(
                iconSize: 34,
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? const Color(0xFFFF0033) : Colors.white),
                onPressed: () => setState(() => liked = !liked),
              ),
              Text(widget.shortData['likes'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              const Icon(Icons.insert_comment_rounded, size: 30),
              Text(widget.shortData['comments'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              const Icon(Icons.share, size: 30),
              const Text('Share', style: TextStyle(fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }
}

// ---------------- 4. SUBSCRIPTIONS TAB ----------------
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        children: [
          // Subscribed Creator Circles
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                _buildAvatarStory('Zenith Gaming', 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150'),
                _buildAvatarStory('Apex Velocity', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                _buildAvatarStory('Pro Sports', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150'),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          // Videos from Subscribed Channels
          VideoFeedCard(videoData: initialVideos[0]),
          VideoFeedCard(videoData: initialVideos[1]),
        ],
      ),
    );
  }

  Widget _buildAvatarStory(String name, String imgUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFFF0033),
            child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(imgUrl)),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------- 5. CHANNEL PROFILE & STUDIO ----------------
class ChannelProfileScreen extends StatelessWidget {
  const ChannelProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 46,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: Text('Kaif Alam Studio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const Center(child: Text('@kaifalam09 • 1.25M Subscribers', style: TextStyle(color: Colors.grey, fontSize: 13))),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Views', '12.4M'),
              _buildStatBox('Watch Time', '380K hrs'),
              _buildStatBox('Earning', 'Web3 Token'),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.video_library_rounded, color: Color(0xFFFF0033)),
            title: const Text('Your Videos & Uploads'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
            title: const Text('Channel Analytics'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
