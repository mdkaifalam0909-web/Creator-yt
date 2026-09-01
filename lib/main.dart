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
    debugPrint("Firebase log: $e");
  }
  runApp(const ApexStreamApp());
}

final List<Map<String, dynamic>> globalApexFeed = [
  {
    'id': 'v_1',
    'title': '4K Hypercar Night Drift & Ray-Tracing Showcase 60FPS',
    'creatorName': 'Apex Horizon Pro',
    'creatorAvatar': 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'views': '2.8M views',
    'time': '1 hour ago',
    'likesCount': 54200,
    'subscribers': '1.2M',
  },
  {
    'id': 'v_2',
    'title': 'Next-Gen Open World Cyber Exploration & Stealth Mission',
    'creatorName': 'Cyber Gaming Hub',
    'creatorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'views': '940K views',
    'time': '3 hours ago',
    'likesCount': 38900,
    'subscribers': '850K',
  },
  {
    'id': 'v_3',
    'title': 'Champions League Unstoppable Clutch & Impossible Goals 2026',
    'creatorName': 'Pro Sports Central',
    'creatorAvatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'views': '5.1M views',
    'time': '6 hours ago',
    'likesCount': 120500,
    'subscribers': '3.4M',
  },
];

final List<Map<String, dynamic>> globalShortsFeed = [
  {
    'id': 'sh_1',
    'creator': 'VelocityRider',
    'title': 'Wait for the crazy drift exit! 🔥🏎️ #supercar #speed',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'likes': '520K',
    'comments': '4,100',
  },
  {
    'id': 'sh_2',
    'creator': 'GoalGod',
    'title': 'Unbelievable 90th minute bicycle kick 😱⚽ #football',
    'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'likes': '890K',
    'comments': '6,720',
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
      home: const MainTabHolder(),
    );
  }
}

class MainTabHolder extends StatefulWidget {
  const MainTabHolder({super.key});

  @override
  State<MainTabHolder> createState() => _MainTabHolderState();
}

class _MainTabHolderState extends State<MainTabHolder> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeFeedView(),
    ReelsShortsView(),
    SubscriptionsFeedView(),
    UserProfileStudioView(),
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

class HomeFeedView extends StatefulWidget {
  const HomeFeedView({super.key});

  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView> {
  String selectedFilter = 'All';
  final List<String> categories = ['All', 'Gaming', 'Racing', 'Live', 'Shorts', 'Trending', 'Football', 'Highlights'];
  final ImagePicker _picker = ImagePicker();

  void _openGmailAuthSheet() {
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, color: Color(0xFFFF0033), size: 30),
                  const SizedBox(width: 8),
                  Text(isSignUp ? 'Create Gmail Account' : 'Sign In with Gmail', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  labelText: 'Gmail / Email ID',
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth Error: $e')));
                  }
                },
                child: Text(isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setModalState(() => isSignUp = !isSignUp),
                child: Text(
                  isSignUp ? 'Already registered? Sign In' : "Don't have an account? Sign Up with Gmail",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUploadSheet() {
    final titleCtrl = TextEditingController();
    final creatorCtrl = TextEditingController();
    File? pickedVideo;
    bool isUploading = false;
    double uploadProgress = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
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
                  side: BorderSide(color: pickedVideo != null ? Colors.green : Colors.white30),
                ),
                onPressed: () async {
                  final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
                  if (file != null) {
                    setModalState(() => pickedVideo = File(file.path));
                  }
                },
                icon: Icon(pickedVideo != null ? Icons.check_circle : Icons.video_library,
                    color: pickedVideo != null ? Colors.green : Colors.white),
                label: Text(
                  pickedVideo != null ? 'Video Selected from Phone Gallery' : 'Select Video from Phone Gallery',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (isUploading) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: uploadProgress, color: const Color(0xFFFF0033)),
                const SizedBox(height: 6),
                Text('Publishing to Feed: ${(uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                        if (titleCtrl.text.isNotEmpty && pickedVideo != null) {
                          setModalState(() => isUploading = true);
                          String videoUrl = '';

                          try {
                            String fName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
                            UploadTask task = FirebaseStorage.instance.ref(fName).putFile(pickedVideo!);
                            task.snapshotEvents.listen((snap) {
                              setModalState(() => uploadProgress = snap.bytesTransferred / snap.totalBytes);
                            });
                            TaskSnapshot snap = await task;
                            videoUrl = await snap.ref.getDownloadURL();
                          } catch (e) {
                            videoUrl = pickedVideo!.path;
                          }

                          var newVideo = {
                            'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
                            'title': titleCtrl.text.trim(),
                            'creatorName': creatorCtrl.text.isEmpty ? (FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Kaif Creator') : creatorCtrl.text.trim(),
                            'creatorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                            'videoUrl': videoUrl,
                            'views': '1 view',
                            'time': 'Just now',
                            'likesCount': 1,
                            'subscribers': '100',
                          };

                          try {
                            await FirebaseFirestore.instance.collection('videos').add(newVideo);
                          } catch (_) {}

                          setState(() {
                            globalApexFeed.insert(0, newVideo);
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
            onPressed: _openUploadSheet,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4),
            child: InkWell(
              onTap: _openGmailAuthSheet,
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
          Expanded(
            child: ListView.builder(
              itemCount: globalApexFeed.length,
              itemBuilder: (context, index) {
                return VideoPlayerFeedCard(videoData: globalApexFeed[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

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

class ReelsShortsView extends StatelessWidget {
  const ReelsShortsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: globalShortsFeed.length,
      itemBuilder: (context, index) {
        return SingleReelViewer(reelData: globalShortsFeed[index]);
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

class SubscriptionsFeedView extends StatelessWidget {
  const SubscriptionsFeedView({super.key});

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
                _buildChannelAvatar('Apex Horizon', 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150'),
                _buildChannelAvatar('Cyber Gaming', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                _buildChannelAvatar('Pro Sports', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150'),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          VideoPlayerFeedCard(videoData: globalApexFeed[0]),
          VideoPlayerFeedCard(videoData: globalApexFeed[1]),
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

class UserProfileStudioView extends StatefulWidget {
  const UserProfileStudioView({super.key});

  @override
  State<UserProfileStudioView> createState() => _UserProfileStudioViewState();
}

class _UserProfileStudioViewState extends State<UserProfileStudioView> {
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
              user != null ? (user.displayName ?? user.email?.split('@')[0] ?? 'Kaif Creator') : 'Guest User',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              user != null ? user.email! : 'Sign in to manage your uploads & analytics',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 25),
          if (user != null)
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
              _buildStatBox('Views', '15.2M'),
              _buildStatBox('Watch Time', '460K hrs'),
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
