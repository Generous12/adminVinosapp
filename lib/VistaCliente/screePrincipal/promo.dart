import 'package:app_bootsup/Widgets/comentarios.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ReelsScreen extends StatefulWidget {
  final bool isVisible; // 👈 Nuevo: saber si está visible

  const ReelsScreen({Key? key, required this.isVisible}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> videos = [];
  bool isLoading = false;
  bool hasMore = true;
  int documentLimit = 10;
  DocumentSnapshot? lastDocument;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _getVideos();
  }

  Future<void> _getVideos() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    Query query = _firestore
        .collection('videos')
        .orderBy('fechaSubida', descending: true)
        .limit(documentLimit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;
      videos.addAll(querySnapshot.docs);
    } else {
      hasMore = false;
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: videos.length + 1,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
                if (index == videos.length - 1) {
                  _getVideos();
                }
              },
              itemBuilder: (context, index) {
                if (index == videos.length) {
                  return hasMore
                      ? const Center(child: CircularProgressIndicator())
                      : const Center(
                          child: Text(
                            "No hay más videos",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                }

                final videoData = videos[index];
                final videoUrl = videoData['urlVideo'];
                final descripcion = videoData['descripcion'] ?? '';
                final videoId = videoData.id;
                return VideoTile(
                  videoId: videoId,
                  videoUrl: videoUrl,
                  descripcion: descripcion,
                  isActive: widget.isVisible && currentIndex == index,
                );
              },
            ),
    );
  }
}

class VideoTile extends StatefulWidget {
  final String videoUrl;
  final String descripcion;
  final bool isActive;
  final String videoId;

  const VideoTile({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.descripcion,
    required this.isActive,
  });

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black, // Barra superior negra
        statusBarIconBrightness: Brightness.light, // Iconos de arriba blancos
        systemNavigationBarColor: Colors.black, // Barra inferior negra
        systemNavigationBarIconBrightness:
            Brightness.light, // Iconos de abajo blancos
      ),
    );
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _chewieController = ChewieController(
          videoPlayerController: _controller!,
          autoPlay: false,
          looping: true,
          showControls: false,
        );
        _updatePlayState();
      });
  }

  @override
  void didUpdateWidget(covariant VideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePlayState();
  }

  void _updatePlayState() {
    if (_controller == null) return;
    if (widget.isActive && !_controller!.value.isPlaying) {
      _controller!.play();
    } else if (!widget.isActive && _controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator()),
        ),
        Positioned(
          bottom: 30,
          left: 20,
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/images/logo1.png'),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'La Casita del Pisco',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Text(
                      widget.descripcion,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 90,
          right: 20,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Iconsax.like, color: Colors.white, size: 30),
                onPressed: () {},
              ),
              const SizedBox(height: 14),
              IconButton(
                icon: const Icon(
                  Iconsax.message,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  showBarModalBottomSheet(
                    context: context,
                    expand: true,
                    builder: (context) => ComentariosScreenVideos(
                      videoid: widget.videoId,
                      userId: userId!,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
