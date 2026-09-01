import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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

// ---------------- PERMANENT PRE-LOADED DEMO FEED ----------------
final List<Map<String, dynamic>> defaultSeedVideos = [
  {
    'id': 'seed_1',
    'title': '4K Hypercar City Drift & Ultra Graphics Showcase',
    'creatorName': 'Zenith Gaming Hub',
    'creatorAvatar': 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'views': '1.8M views',
    'time': '2 hours ago',
    'likesCount': 24300,
  },
  {
    'id': 'seed_2',
    'title': 'Open World Next-Gen Gameplay Walkthrough 60FPS',
    'creatorName': 'Apex Velocity',
    'creatorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'views': '920K views',
    'time': '5 hours ago',
    'likesCount': 18500,
  },
  {
    'id': 'seed_3',
    'title': 'Football Legends Top Clutch & Attitude Goals 2026',
    'creatorName': 'Pro Sports Arena',
    'creatorAvatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'views': '3.2M views',
    'time': '1 day ago',
    'likesCount': 94200,
  },
];

final List<Map<String, dynamic>> defaultSeedShorts = [
  {
    'id': 'short_seed_1',
    'creator': 'VelocityRider',
    'title': 'Wait for the crazy drift! 🔥🏎️ #racing #hypercar',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'likes': '320K',
    'comments': '2,100',
  },
  {
    'id': 'short_seed_2',
    'creator': 'ClutchKing',
    'title': 'Unstoppable impossible save 🔥⚽ #football',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'likes': '614K',
    'comments': '4,520',
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
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F0F0F), elevation: 0),
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

// ---------------- 1. HOME & EXPLORE (HYBRID FEED + GALLERY UPLOAD) ----------------
class HomeExploreScreen extends StatefulWidget {
  const HomeExploreScreen({super.key});

  @override
  State<HomeExploreScreen> createState() => _HomeExploreScreenState();
}

class _HomeExploreScreenState extends State<HomeExploreScreen> {
  String selectedFilter = 'All';
  final List<String> tags = ['All', 'Car Racing', 'Gaming', 'Action', 'Trending', 'Football', 'Shorts'];
  final ImagePicker _picker = ImagePicker();

  void _openGalleryUploadModal() {
    final titleCtrl = TextEditingController();
    final creatorCtrl = TextEditingController();
    File? selectedVideoFile;
    bool isShort = false;
    bool isUploading = false;
    double progress = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  Icon(Icons.video_library, color: Color(0xFFFF0033)),
                  SizedBox(width: 8),
                  Text('Upload Video from Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 15),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Video Title', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: creatorCtrl, decoration: const InputDecoration(labelText: 'Creator Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: selectedVideoFile != null ? Colors.green : Colors.white24),
                ),
                onPressed: () async {
                  final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
                  if (file != null) {
                    setModalState(() {
                      selectedVideoFile = File(file.path);
                    });
                  }
                },
                icon: Icon(selectedVideoFile != null ? Icons.check_circle : Icons.video_collection,
                    color: selectedVideoFile != null ? Colors.green : Colors.white),
                label: Text(
                  selectedVideoFile != null ? 'Video File Selected from Gallery' : 'Choose Video from Phone Gallery',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isShort,
                    activeColor: const Color(0xFFFF0033),
                    onChanged: (val) => setModalState(() => isShort = val ?? false),
                  ),
                  const Text('Mark as Short / Reel', style: TextStyle(color: Colors.white)),
                ],
              ),
              if (isUploading) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress, color: const Color(0xFFFF0033)),
                const SizedBox(height: 5),
                Text('Publishing to Network: ${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0033), minimumSize: const Size(double.infinity, 48)),
                onPressed: isUploading
                    ? null
                    : () async {
                        if (titleCtrl.text.isNotEmpty && selectedVideoFile != null) {
                          setModalState(() => isUploading = true);

                          String downloadUrl = '';
                          try {
                            String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
                            UploadTask task = FirebaseStorage.instance.ref(fileName).putFile(selectedVideoFile!);
                            task.snapshotEvents.listen((TaskSnapshot snap) {
                              setModalState(() {
                                progress = snap.bytesTransferred / snap.totalBytes;
                              });
                            });
                            TaskSnapshot snapshot = await task;
                            downloadUrl = await snapshot.ref.getDownloadURL();
                          } catch (e) {
                            // Fallback to local path for instant local playback if offline
                            downloadUrl = selectedVideoFile!.path;
                          }

                          try {
                            await FirebaseFirestore.instance.collection('videos').add({
                              'title': titleCtrl.text.trim(),
                              'videoUrl': downloadUrl,
                              'creatorName': creatorCtrl.text.isEmpty ? 'Kaif Creator' : creatorCtrl.text.trim(),
                              'creatorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                              'isShort': isShort,
                              'likesCount': 1,
                              'views': 'Just now',
                              'time': '1 min ago',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          } catch (e) {
                            debugPrint("Firestore write local: $e");
                          }

                          // Also inject into memory feed instantly
                          setState(() {
                            defaultSeedVideos.insert(0, {
                              'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
                              'title': titleCtrl.text.trim(),
                              'creatorName': creatorCtrl.text.isEmpty ? 'Kaif Creator' : creatorCtrl.text.trim(),
                              'creatorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                              'videoUrl': downloadUrl,
                              'views': 'Just now',
                              'time': '1 min ago',
                              'likesCount': 1,
                            });
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                child: const Text('Publish Video to Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
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
          IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFFF0033), size: 30), onPressed: _openGalleryUploadModal),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
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
          // Hybrid Feed: Live Database Cloud Videos + Preloaded Seed Videos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('videos').where('isShort', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> combinedFeed = [];

                // 1. Add Cloud Firestore Real-time uploads first
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    combinedFeed.add({
                      'id': doc.id,
                      'title': data['title'] ?? 'Uploaded Video',
                      'creatorName': data['creatorName'] ?? 'Creator',
                      'creatorAvatar': data['creatorAvatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                      'videoUrl': data['videoUrl'] ?? '',
                      'views': data['views'] ?? '1 view',
                      'time': data['time'] ?? 'Just now',
                      'likesCount': data['likesCount'] ?? 0,
                    });
                  }
                }

                // 2. Always merge Default High-Energy Seed videos so app is NEVER empty
                combinedFeed.addAll(defaultSeedVideos);

                return ListView.builder(
                  itemCount: combinedFeed.length,
                  itemBuilder: (context, index) {
                    return VideoFeedCard(videoData: combinedFeed[index]);
                  },
                );
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
    _initVideo();
  }

  void _initVideo() async {
    String url = widget.videoData['videoUrl'];
    if (url.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      _videoController = VideoPlayerController.file(File(url));
    }
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
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator(color: Color(0xFFFF0033))),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.videoData['creatorAvatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.videoData['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${widget.videoData['creatorName']} • ${widget.videoData['views']} • ${widget.videoData['time']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubscribed ? const Color(0xFF2A2A2A) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                  onPressed: () => setState(() => isSubscribed = !isSubscribed),
                  child: Text(
                    isSubscribed ? 'Subscribed' : 'Subscribe',
                    style: TextStyle(color: isSubscribed ? Colors.white70 : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => isLiked = !isLiked),
                  child: Row(
                    children: [
                      Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? const Color(0xFFFF0033) : Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text('${(widget.videoData['likesCount'] ?? 10) + (isLiked ? 1 : 0)}'),
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

// ---------------- 3. FULLSCREEN SHORTS / REELS ----------------
class FullscreenReelsFeed extends StatelessWidget {
  const FullscreenReelsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: defaultSeedShorts.length,
      itemBuilder: (context, index) {
        return SingleShortViewer(shortData: defaultSeedShorts[index]);
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

// ---------------- 4. SUBSCRIPTIONS SCREEN ----------------
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        children: [
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
          VideoFeedCard(videoData: defaultSeedVideos[0]),
          VideoFeedCard(videoData: defaultSeedVideos[1]),
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

// ---------------- 5. CREATOR STUDIO & PRIVACY POLICY ----------------
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
          const Center(child: Text('Kaif Alam Creator', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const Center(child: Text('@kaifalam09 • Verified Channel', style: TextStyle(color: Colors.grey, fontSize: 13))),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Views', '12.4M'),
              _buildStatBox('Watch Time', '380K hrs'),
              _buildStatBox('Network', 'Cloud IPFS'),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blueAccent),
            title: const Text('Privacy Policy & Data Rules'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const SingleChildScrollView(
                    child: Text(
                      'ApexStream respects creator & user privacy:\n\n'
                      '1. Gallery Permissions: We only access videos you explicitly choose to upload.\n\n'
                      '2. Decentralized & Cloud Streaming: Uploaded media is streamed seamlessly to the global network.\n\n'
                      '3. Data Protection: No user data is sold to third parties.',
                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Agree', style: TextStyle(color: Color(0xFFFF0033)))),
                  ],
                ),
              );
            },
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
