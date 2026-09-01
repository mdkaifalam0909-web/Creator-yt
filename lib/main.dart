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
    debugPrint("Firebase Initialization: $e");
  }
  runApp(const ProductionVideoApp());
}

class ProductionVideoApp extends StatelessWidget {
  const ProductionVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamSphere',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.redAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0F0F),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
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
            body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return MainNavigationShell(currentUser: snapshot.data!);
        }
        return const GoogleLoginScreen();
      },
    );
  }
}

// ---------------- 2. GOOGLE LOGIN SCREEN ----------------
class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _inProgress = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _inProgress = true);
    try {
      final GoogleSignInAccount? googleAccount = await GoogleSignIn().signIn();
      if (googleAccount == null) {
        setState(() => _inProgress = false);
        return;
      }
      final GoogleSignInAuthentication auth = await googleAccount.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'name': userCred.user!.displayName ?? 'Creator User',
          'email': userCred.user!.email,
          'photoUrl': userCred.user!.photoURL ?? '',
          'subscribersCount': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _inProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_filled_rounded, size: 100, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                'Next-Gen Video Hub',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Decentralized • Uncensored • High Bitrate',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              _inProgress
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.security, color: Colors.black),
                      label: const Text(
                        'Continue with Google Account',
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- 3. MAIN NAVIGATION SHELL ----------------
class MainNavigationShell extends StatefulWidget {
  final User currentUser;
  const MainNavigationShell({super.key, required this.currentUser});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreenFeed(user: widget.currentUser),
      ReelsShortsFeed(user: widget.currentUser),
      SubscriptionsFeed(user: widget.currentUser),
      UserProfileScreen(user: widget.currentUser),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Shorts'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions_outlined), activeIcon: Icon(Icons.subscriptions), label: 'Subscriptions'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), activeIcon: Icon(Icons.account_circle), label: 'You'),
        ],
      ),
    );
  }
}

// ---------------- 4. TAB 1: HOME FEED (LONG VIDEOS) ----------------
class HomeScreenFeed extends StatelessWidget {
  final User user;
  const HomeScreenFeed({super.key, required this.user});

  void _openUploadDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    bool isShort = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
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
              const Text('Publish New Video / IPFS CID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 15),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Direct MP4 URL or IPFS Gateway URL', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isShort,
                    activeColor: Colors.redAccent,
                    onChanged: (val) => setModalState(() => isShort = val ?? false),
                  ),
                  const Text('Mark as Short / Reel', style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 45)),
                onPressed: () async {
                  if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('videos').add({
                      'title': titleController.text.trim(),
                      'videoUrl': urlController.text.trim(),
                      'creatorId': user.uid,
                      'creatorName': user.displayName ?? 'Creator',
                      'creatorPhoto': user.photoURL ?? '',
                      'isShort': isShort,
                      'likes': [],
                      'views': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Upload & Stream'),
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
            Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('StreamSphere', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 28), onPressed: () => _openUploadDialog(context)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('videos').where('isShort', isEqualTo: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No long videos yet. Tap + to upload!', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return LongVideoCard(doc: doc, currentUser: user);
            },
          );
        },
      ),
    );
  }
}

// ---------------- 5. LONG VIDEO COMPONENT (WITH LIKES & SUBSCRIBE) ----------------
class LongVideoCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final User currentUser;
  const LongVideoCard({super.key, required this.doc, required this.currentUser});

  @override
  State<LongVideoCard> createState() => _LongVideoCardState();
}

class _LongVideoCardState extends State<LongVideoCard> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.doc['videoUrl']));
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(playedColor: Colors.redAccent, handleColor: Colors.redAccent),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List likes = widget.doc['likes'] ?? [];
    bool isLiked = likes.contains(widget.currentUser.uid);
    String creatorId = widget.doc['creatorId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: widget.doc['creatorPhoto'] != '' ? NetworkImage(widget.doc['creatorPhoto']) : null,
                  child: widget.doc['creatorPhoto'] == '' ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.doc['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${widget.doc['creatorName']} • ${likes.length} likes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? Colors.redAccent : Colors.white),
                  onPressed: () async {
                    if (isLiked) {
                      await widget.doc.reference.update({'likes': FieldValue.arrayRemove([widget.currentUser.uid])});
                    } else {
                      await widget.doc.reference.update({'likes': FieldValue.arrayUnion([widget.currentUser.uid])});
                    }
                  },
                ),
                SubscribeButton(creatorId: creatorId, currentUserId: widget.currentUser.uid),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------- 6. SUBSCRIBE BUTTON COMPONENT ----------------
class SubscribeButton extends StatelessWidget {
  final String creatorId;
  final String currentUserId;
  const SubscribeButton({super.key, required this.creatorId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (creatorId == currentUserId) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        List subscriptions = (snapshot.data!.data() as Map<String, dynamic>?)?['following'] ?? [];
        bool isSubscribed = subscriptions.contains(creatorId);

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSubscribed ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          ),
          onPressed: () async {
            if (isSubscribed) {
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
            isSubscribed ? 'Subscribed' : 'Subscribe',
            style: TextStyle(color: isSubscribed ? Colors.white70 : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      },
    );
  }
}

// ---------------- 7. TAB 2: VERTICAL SHORTS / REELS PLAYER ----------------
class ReelsShortsFeed extends StatelessWidget {
  final User user;
  const ReelsShortsFeed({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').where('isShort', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No Shorts uploaded yet.', style: TextStyle(color: Colors.grey)));
        }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return SingleReelItem(doc: snapshot.data!.docs[index], user: user);
          },
        );
      },
    );
  }
}

class SingleReelItem extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final User user;
  const SingleReelItem({super.key, required this.doc, required this.user});

  @override
  State<SingleReelItem> createState() => _SingleReelItemState();
}

class _SingleReelItemState extends State<SingleReelItem> {
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
            ? FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller)))
            : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
        Positioned(
          bottom: 30,
          left: 15,
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
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.white, si
