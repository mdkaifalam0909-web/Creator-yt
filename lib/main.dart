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
    debugPrint("Firebase init log: $e");
  }
  runApp(const ApexStreamApp());
}

// ---------------- GLOBAL MOCK / SEED DATABASE ----------------
final List<Map<String, dynamic>> masterVideoList = [
  {
    'id': 'vid_1',
    'title': '4K Hypercar City Drift & Ultra Graphics Ray-Tracing Gameplay',
    'creatorName': 'Apex Racing Pro',
    'creatorAvatar': 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'views': '2.4M views',
    'time': '1 hour ago',
    'likesCount': 45200,
  },
  {
    'id': 'vid_2',
    'title': 'Next-Gen Open World Exploration 60FPS Ultimate RTX On',
    'creatorName': 'Cyber Gaming Hub',
    'creatorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'views': '890K views',
    'time': '3 hours ago',
    'likesCount': 29400,
  },
  {
    'id': 'vid_3',
    'title': 'Football Championship Clutch Goals & Best Highlights 2026',
    'creatorName': 'World Sports Arena',
    'creatorAvatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'views': '4.1M views',
    'time': '1 day ago',
    'likesCount': 108000,
  },
];

final List<Map<String, dynamic>> masterShortsList = [
  {
    'id': 'sh_1',
    'creator': 'VelocityRider',
    'title': 'Craziest drift save ever recorded! 🔥🏎️ #drift #speed',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'likes': '420K',
    'comments': '3,410',
  },
  {
    'id': 'sh_2',
    'creator': 'ClutchGod',
    'title': 'Impossible last second goal 😱⚽ #football',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'likes': '780K',
    'comments': '5,890',
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
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFFFF0033),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F0F0F), elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0F0F),
          selectedItemColor: Color(0xFFFF0033),
          unselectedItemColor: Colors.white70,
        ),
      ),
      home: const MainNavigationHolder(),
    );
  }
}

// ---------------- BOTTOM NAVIGATION ----------------
class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeFeedScreen(),
    ReelsShortsScreen(),
    SubscriptionsFeedScreen(),
    UserProfileStudioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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

// ---------------- 1. HOME SCREEN & GALLERY UPLOAD ----------------
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  String selectedFilter = 'All';
  final List<String> categories = ['All', 'Gaming', 'Racing', 'Live', 'Shorts', 'Trending', 'Sports'];
  final ImagePicker _picker = ImagePicker();

  void _showAuthModal() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isSignUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 25,
            left: 25,
            right: 25,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, color: Color(0xFFFF0033), size: 32),
                  const SizedBox(width: 10),
                  Text(isSignUp ? 'Create Apex Account' : 'Sign In to ApexStream', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  labelText: 'Gmail / Email Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0033),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  try {
                    if (isSignUp) {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    } else {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth: $e')));
                  }
                },
                child: Text(isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setModalState(() => isSignUp = !isSignUp),
                child: Text(
                  isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up with Gmail",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUploadDialog() {
    final titleCtrl = TextEditingController();
    final creatorCtrl = TextEditingController();
    File? pickedVideoFile;
    bool isUploading = false;
    double uploadProgress = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
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
                  Icon(Icons.cloud_upload_rounded, color: Color(0xFFFF0033), size: 28),
                  SizedBox(width: 10),
                  Text('Upload Video from Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Video Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: creatorCtrl,
                decoration: const InputDecoration(labelText: 'Creator / Channel Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: pickedVideoFile != null ? Colors.green : Colors.white30),
                ),
                onPressed: () async {
                  final XFile? vid = await _picker.pickVideo(source: ImageSource.gallery);
                  if (vid != null) {
                    setModalState(() => pickedVideoFile = File(vid.path));
                  }
                },
                icon: Icon(pickedVideoFile != null ? Icons.check_circle : Icons.video_library_rounded,
                    color: pickedVideoFile != null ? Colors.green : Colors.white),
                label: Text(
                  pickedVideoFile != null ? 'Video Selected from Phone Gallery' : 'Select Video from Phone Gallery',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (isUploading) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: uploadProgress, color: const Color(0xFFFF0033)),
                const SizedBox(height: 6),
                Text('Publishing: ${(uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0033),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: isUploading
                    ? null
                    : () async {
                        if (titleCtrl.text.isNotEmpty && pickedVideoFile != null) {
                          setModalState(() => isUploading = true);
                          String directUrl = '';

                          try {
                            String fName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
                            UploadTask task = FirebaseStorage.instance.ref(fName).putFile(pickedVideoFile!);
                            task.snapshotEvents.listen((snap) {
                              setModalState(() => uploadProgress = snap.bytesTransferred / snap.totalBytes);
                            });
                            TaskSnapshot snap = await task;
                            directUrl = await snap.ref.getDownloadURL();
                          } catch (e) {
                            directUrl = pickedVideoFile!.path;
                          }

                          var newEntry = {
                            'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
                            'title': titleCtrl.text.trim(),
                            'creatorName': creatorCtrl.text.isEmpty ? (FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Apex Creator') : creatorCtrl.text.trim(),
                            'creatorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                            'videoUrl': directUrl,
                            'views': '1 view',
                            'time': 'Just now',
                            'likesCount': 1,
                          };

                          try {
                            await FirebaseFirestore.instance.collection('videos').add(newEntry);
                          } catch (_) {}

                          setState(() {
                            masterVideoList.insert(0, newEntry);
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                child: const Text('Publish Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0033), size: 30),
            SizedBox(width: 8),
            Text('ApexStream', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21, letterSpacing: -0.8)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFFF0033), size: 28),
            onPressed: _openUploadDialog,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4),
            child: InkWell(
              onTap: _showAuthModal,
              child: currentUser != null
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFFF0033),
                      child: Text(currentUser.email?[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                  : const Chip(
                      label: Text('Sign In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      backgroundColor: Color(0xFF262626),
                      padding: EdgeInsets.zero,
                    ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                bool isSelected = selectedFilter == categories[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(categories[i]),
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    backgroundColor: const Color(0xFF222222),
                    selectedColor: Colors.white,
                    onSelected: (val) => setState(() => selectedFilter = categories[i]),
                  ),
                );
              },
            ),
          ),
          // Instant Main Video Feed
          Expanded(
            child: ListView.builder(
              itemCount: masterVideoList.length,
              itemBuilder: (context, index) {
                return VideoPlayerFeedCard(videoData: masterVideoList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 2. VIDEO PLAYER CARD ----------------
class VideoPlayerFeedCard extends StatefulWidget {
  final Map<String, dynamic> videoData;
  const VideoPlayerFeedCard({super.key, required this.videoData});

  @override
  State<VideoPlayerFeedCard> createState() => _VideoPlayerFeedCardState();
}

class _VideoPlayerFeedCardState extends State<VideoPlayerFeedCard> {
  late VideoPlayerController _vidController;
  ChewieController? _chewieController;
  bool isLiked = false;
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  void _setupVideo() async {
    String url = widget.videoData['videoUrl'];
    if (url.startsWith('http')) {
      _vidController = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      _vidController = VideoPlayerController.file(File(url));
    }
    await _vidController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _vidController,
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
    _vidController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF0033))),
                  ),
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
                      Text(widget.videoData['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                const SizedBox(width: 28),
                const Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 20),
                    SizedBox(width: 6),
                    Text('Comments'),
                  ],
                ),
                const SizedBox(width: 28),
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

// ---------------- 3. FULLSCREEN REELS / SHORTS ----------------
class ReelsShortsScreen extends StatelessWidget {
  const ReelsShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: masterShortsList.length,
      itemBuilder: (context, index) {
        return SingleReelViewer(reelData: masterShortsList[index]);
      },
    );
  }
}

class SingleReelViewer extends StatefulWidget {
  final Map<String, dynamic> reelData;
  const SingleReelViewer({super.key, required this.reelData});

  @override
  State<SingleReelViewer> createState() => _SingleReelViewerState();
}

class _SingleReelViewerState extends State<SingleReelViewer> {
  late VideoPlayerController _controller;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reelData['videoUrl']))
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
              Text('@${widget.reelData['creator']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.reelData['title'], style: const TextStyle(fontSize: 14)),
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
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFFFF0033) : Colors.white),
                onPressed: () => setState(() => isLiked = !isLiked),
              ),
              Text(widget.reelData['likes'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              const Icon(Icons.insert_comment_rounded, size: 30),
              Text(widget.reelData['comments'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
class SubscriptionsFeedScreen extends StatelessWidget {
  const SubscriptionsFeedScreen({super.key});

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
                _buildChannelAvatar('Apex Racing', 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150'),
                _buildChannelAvatar('Cyber Gaming', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                _buildChannelAvatar('World Sports', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150'),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          VideoPlayerFeedCard(videoData: masterVideoList[0]),
          VideoPlayerFeedCard(videoData: masterVideoList[1]),
        ],
      ),
    );
  }

  Widget _buildChannelAvatar(String name, String img) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFFF0033),
            child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(img)),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------- 5. CREATOR STUDIO & GMAIL AUTH ----------------
class UserProfileStudioScreen extends StatefulWidget {
  const UserProfileStudioScreen({super.key});

  @override
  State<UserProfileStudioScreen> createState() => _UserProfileStudioScreenState();
}

class _UserProfileStudioScreenState extends State<UserProfileStudioScreen> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFFFF0033),
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? Text(
                      user != null ? (user.email?[0].toUpperCase() ?? 'U') : 'G',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              user != null ? (user.displayName ?? user.email?.split('@')[0] ?? 'Apex Creator') : 'Guest User',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              user != null ? user.email! : 'Sign in to sync channel & videos',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 25),
          if (user == null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0033),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Trigger quick email login dialog
                _showAuthSheet(context);
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign In / Register with Gmail', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Colors.white24),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {});
              },
              icon: const Icon(Icons.logout, color: Colors.white70),
              label: const Text('Sign Out', style: TextStyle(color: Colors.white70)),
            ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Views', '14.8M'),
              _buildStatBox('Watch Time', '420K hrs'),
              _buildStatBox('Storage', 'Cloud IPFS'),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blueAccent),
            title: const Text('Privacy Policy & User Rights'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'ApexStream Privacy Policy:\n\n'
                      '1. Account Info: Your Gmail address is strictly used for authentication.\n\n'
                      '2. Video Rights: Uploaded video content remains under your ownership.\n\n'
                      '3. Data Safety: No third-party data tracking or selling.',
                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('I Agree', style: TextStyle(color: Color(0xFFFF0033)))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAuthSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isSignUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 25,
            left: 25,
            right: 25,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isSignUp ? 'Create Gmail Account' : 'Sign In with Gmail', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email / Gmail', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0033), minimumSize: const Size(double.infinity, 48)),
                onPressed: () async {
                  try {
                    if (isSignUp) {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    } else {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text(isSignUp ? 'Sign Up' : 'Sign In'),
              ),
              TextButton(
                onPressed: () => setModalState(() => isSignUp = !isSignUp),
                child: Text(isSignUp ? 'Already registered? Sign In' : 'New user? Sign Up'),
              ),
            ],
          ),
        ),
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
