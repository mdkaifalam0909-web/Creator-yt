import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      home: const AuthGatekeeper(),
    );
  }
}

// ---------------- 1. AUTH GATEKEEPER ----------------
class AuthGatekeeper extends StatelessWidget {
  const AuthGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFFF0033))),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return MainAppNavigation(currentUser: snapshot.data!);
        }
        return const GoogleLoginScreen();
      },
    );
  }
}

// ---------------- 2. REAL GOOGLE LOGIN ----------------
class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'name': userCred.user!.displayName ?? 'Creator',
          'email': userCred.user!.email,
          'photoUrl': userCred.user!.photoURL ?? '',
          'subscribers': 0,
          'following': [],
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_filled_rounded, size: 95, color: Color(0xFFFF0033)),
              const SizedBox(height: 20),
              const Text('ApexStream', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('The Censorship-Free Video Hub', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 50),
              _loading
                  ? const CircularProgressIndicator(color: Color(0xFFFF0033))
                  : ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.black),
                      label: const Text('Sign In With Google', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- 3. MAIN NAVIGATION ----------------
class MainAppNavigation extends StatefulWidget {
  final User currentUser;
  const MainAppNavigation({super.key, required this.currentUser});

  @override
  State<MainAppNavigation> createState() => _MainAppNavigationState();
}

class _MainAppNavigationState extends State<MainAppNavigation> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeExploreScreen(currentUser: widget.currentUser),
      FullscreenReelsFeed(currentUser: widget.currentUser),
      SubscriptionsScreen(currentUser: widget.currentUser),
      ChannelProfileScreen(currentUser: widget.currentUser),
    ];

    return Scaffold(
      body: pages[_tabIndex],
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

// ---------------- 4. HOME & EXPLORE (WITH GALLERY UPLOAD) ----------------
class HomeExploreScreen extends StatefulWidget {
  final User currentUser;
  const HomeExploreScreen({super.key, required this.currentUser});

  @override
  State<HomeExploreScreen> createState() => _HomeExploreScreenState();
}

class _HomeExploreScreenState extends State<HomeExploreScreen> {
  String selectedFilter = 'All';
  final List<String> tags = ['All', 'Car Racing', 'Gaming', 'Action', 'Trending', 'Football', 'Shorts'];
  final ImagePicker _picker = ImagePicker();

  void _openGalleryUploadSheet() {
    final titleCtrl = TextEditingController();
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
              const Text('Upload Video From Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Video Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              // Video Picker Button
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
                  selectedVideoFile != null ? 'Video Selected from Gallery' : 'Choose Video from Gallery',
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
                Text('Uploading to Cloud: ${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0033), minimumSize: const Size(double.infinity, 48)),
                onPressed: isUploading
                    ? null
                    : () async {
                        if (titleCtrl.text.isNotEmpty && selectedVideoFile != null) {
                          setModalState(() => isUploading = true);

                          String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
                          UploadTask task = FirebaseStorage.instance.ref(fileName).putFile(selectedVideoFile!);

                          task.snapshotEvents.listen((TaskSnapshot snap) {
                            setModalState(() {
                              progress = snap.bytesTransferred / snap.totalBytes;
                            });
                          });

                          TaskSnapshot snapshot = await task;
                          String downloadUrl = await snapshot.ref.getDownloadURL();

                          await FirebaseFirestore.instance.collection('videos').add({
                            'title': titleCtrl.text.trim(),
                            'videoUrl': downloadUrl,
                            'creatorId': widget.currentUser.uid,
                            'creatorName': widget.currentUser.displayName ?? 'Creator',
                            'creatorAvatar': widget.currentUser.photoURL ?? '',
                            'isShort': isShort,
                            'likes': [],
                            'views': 0,
                            'createdAt': FieldValue.serverTimestamp(),
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
          IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFFF0033), size: 30), onPressed: _openGalleryUploadSheet),
        ],
      ),
      body: Column(
        children: [
          // Filter Tags Bar
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
          // Live Database Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('videos').where('isShort', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF0033)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No videos in feed. Tap + to upload first video from Gallery!', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return LiveVideoCard(doc: doc, currentUser: widget.currentUser);
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

// ---------------- 5. LIVE VIDEO COMPONENT ----------------
class LiveVideoCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final User currentUser;
  const LiveVideoCard({super.key, required this.doc, required this.currentUser});

  @override
  State<LiveVideoCard> createState() => _LiveVideoCardState();
}

class _LiveVideoCardState extends State<LiveVideoCard> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.doc['videoUrl']));
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
    List likes = widget.doc['likes'] ?? [];
    bool isLiked = likes.contains(widget.currentUser.uid);
    String creatorId = widget.doc['creatorId'];
    String photo = widget.doc['creatorAvatar'] ?? '';

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
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.doc['title'], maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${widget.doc['creatorName']} • ${likes.length} likes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? const Color(0xFFFF0033) : Colors.white),
                  onPressed: () async {
                    if (isLiked) {
                      await widget.doc.reference.update({'likes': FieldValue.arrayRemove([widget.currentUser.uid])});
                    } else {
                      await widget.doc.reference.update({'likes': FieldValue.arrayUnion([widget.currentUser.uid])});
                    }
                  },
                ),
                SubscribeToggle(creatorId: creatorId, currentUserId: widget.currentUser.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 6. SUBSCRIBE BUTTON ----------------
class SubscribeToggle extends StatelessWidget {
  final String creatorId;
  final String currentUserId;
  const SubscribeToggle({super.key, required this.creatorId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (creatorId == currentUserId) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        List following = (snapshot.data!.data() as Map<String, dynamic>?)?['following'] ?? [];
        bool isSub = following.contains(creatorId);

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSub ? const Color(0xFF2A2A2A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          onPressed: () async {
            if (isSub) {
              await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
                'following': FieldValue.arrayRemove([creatorId])
              });
            } else {
              await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
                'following': FieldValue.arrayUnion([creatorId])
              });
            }
          },
          child: Text(
            isSub ? 'Subscribed' : 'Subscribe',
            style: TextStyle(color: isSub ? Colors.white70 : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      },
    );
  }
}

// ---------------- 7. FULLSCREEN VERTICAL REELS / SHORTS ----------------
class FullscreenReelsFeed extends StatelessWidget {
  final User currentUser;
  const FullscreenReelsFeed({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').where('isShort', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF0033)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No Shorts uploaded yet. Tap + on Home to add one!', style: TextStyle(color: Colors.grey)));
        }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return SingleShortItem(doc: snapshot.data!.docs[index], user: currentUser);
          },
        );
      },
    );
  }
}

class SingleShortItem extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final User user;
  const SingleShortItem({super.key, required this.doc, required this.user});

  @override
  State<SingleShortItem> createState() => _SingleShortItemState();
}

class _SingleShortItemState extends State<SingleShortItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.doc['videoUrl']))
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
    List likes = widget.doc['likes'] ?? [];
    bool isLiked = likes.contains(widget.user.uid);

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
              Text('@${widget.doc['creatorName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.doc['title'], style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        Positioned(
          bottom: 40,
          right: 15,
          child: Column(
            children: [
              IconButton(
                iconSize: 36,
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFFFF0033) : Colors.white),
                onPressed: () async {
                  if (isLiked) {
                    await widget.doc.reference.update({'likes': FieldValue.arrayRemove([widget.user.uid])});
                  } else {
                    await widget.doc.reference.update({'likes': FieldValue.arrayUnion([widget.user.uid])});
                  }
                },
              ),
              Text('${likes.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              const Icon(Icons.share, size: 30),
            ],
          ),
        )
      ],
    );
  }
}

// ---------------- 8. SUBSCRIPTIONS TAB ----------------
class SubscriptionsScreen extends StatelessWidget {
  final User currentUser;
  const SubscriptionsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF0033)));
          List following = (userSnap.data!.data() as Map<String, dynamic>?)?['following'] ?? [];

          if (following.isEmpty) {
            return const Center(child: Text('Subscribe to creators to see their videos here!', style: TextStyle(color: Colors.grey)));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('videos').where('creatorId', whereIn: following).snapshots(),
            builder: (context, videoSnap) {
              if (!videoSnap.hasData || videoSnap.data!.docs.isEmpty) {
                return const Center(child: Text('No uploads from subscribed channels yet.'));
              }
              return ListView.builder(
                itemCount: videoSnap.data!.docs.length,
                itemBuilder: (context, i) => LiveVideoCard(doc: videoSnap.data!.docs[i], currentUser: currentUser),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------- 9. CHANNEL PROFILE & LOGOUT ----------------
class ChannelProfileScreen extends StatelessWidget {
  final User currentUser;
  const ChannelProfileScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF0033)),
            onPressed: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundImage: currentUser.photoURL != null ? NetworkImage(currentUser.photoURL!) : null,
              child: currentUser.photoURL == null ? const Icon(Icons.person, size: 40) : null,
            ),
          ),
          const SizedBox(height: 14),
          Center(child: Text(currentUser.displayName ?? 'Creator', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          Center(child: Text(currentUser.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13))),
          const SizedBox(height: 35),
          ListTile(
            leading: const Icon(Icons.cloud_done_rounded, color: Colors.green),
            title: const Text('Firebase & Cloud Storage Connected'),
            subtitle: const Text('Direct gallery video streaming active'),
          ),
        ],
      ),
    );
  }
}
