import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:iconsax/iconsax.dart';

class ImageCacheHelper {
  static String? profileImageUrl;
  static bool isImageLoaded = false;
  static void clearCache() {
    profileImageUrl = null;
    isImageLoaded = false;
  }
}

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final User? user;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.user,
  }) : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  String? firestoreProfileImageUrl;
  String? firestoreUsername; // <-- nuevo campo
  bool isImageLoaded = false;

  @override
  void initState() {
    super.initState();

    if (!ImageCacheHelper.isImageLoaded && widget.user != null) {
      getUserData(widget.user!.uid).then((data) {
        if (mounted) {
          setState(() {
            firestoreProfileImageUrl = data['profileImageUrl'];
            firestoreUsername = data['username'];
            isImageLoaded = true;
            ImageCacheHelper.profileImageUrl = firestoreProfileImageUrl;
            ImageCacheHelper.isImageLoaded = true;
          });
        }
      });
    } else {
      firestoreProfileImageUrl = ImageCacheHelper.profileImageUrl;
      isImageLoaded = true;
    }
  }

  // Trae URL de imagen y username desde Firestore
  Future<Map<String, String?>> getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final url = data['profileImageUrl'] as String?;
        final username = data['username'] as String?;
        return {'profileImageUrl': url, 'username': username};
      }
    } catch (e, stackTrace) {
      print("Error obteniendo datos del usuario: $e");
      print("StackTrace: $stackTrace");
    }
    return {'profileImageUrl': null, 'username': null};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    double imageSize = 13;
    bool isProfileSelected = widget.currentIndex == 3;

    // Inicial para Initicon
    final String initText = (firestoreUsername?.trim().isNotEmpty ?? false)
        ? firestoreUsername!.substring(0, 1).toUpperCase()
        : (widget.user?.displayName?.trim().isNotEmpty ?? false)
        ? widget.user!.displayName!.substring(0, 1).toUpperCase()
        : 'C';

    return SizedBox(
      height: 56,
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        backgroundColor: theme.bottomAppBarTheme.color,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onBackground.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontSize: 0),
        unselectedLabelStyle: const TextStyle(fontSize: 0),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.box, size: 30.0),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.shopping_cart, size: 30.0),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.message_text, size: 30.0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: imageSize + 1,
              backgroundColor: isProfileSelected
                  ? colorScheme.primary
                  : colorScheme.onBackground.withOpacity(0.6),
              child: CircleAvatar(
                radius: imageSize,
                backgroundColor: theme.scaffoldBackgroundColor,
                child: isImageLoaded
                    ? (firestoreProfileImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: firestoreProfileImageUrl!,
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                    backgroundImage: imageProvider,
                                    radius: imageSize,
                                  ),
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                              errorWidget: (context, url, error) => Initicon(
                                text: initText,
                                size: imageSize * 2.5,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                backgroundColor: Color(0xFFA30000),
                              ),
                            )
                          : Initicon(
                              text: initText,
                              size: imageSize * 2.5,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              backgroundColor: Color(0xFFA30000),
                            ))
                    : CircularProgressIndicator(color: colorScheme.primary),
              ),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
//BOTTOMBAR DE CLIENTE

class ImageCacheHelperCliente {
  static final Map<String, String?> _profileImages = {};
  static final Map<String, bool> _loadedFlags = {};

  static String? getProfileImage(String userId) => _profileImages[userId];
  static bool isImageLoaded(String userId) => _loadedFlags[userId] ?? false;

  static void setProfileImage(String userId, String? url) {
    _profileImages[userId] = url;
    _loadedFlags[userId] = true;
  }

  static void clearCache(String userId) {
    _profileImages.remove(userId);
    _loadedFlags.remove(userId);
  }
}

class CustomBottomNavBarCliente extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final User? user;

  const CustomBottomNavBarCliente({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.user,
  }) : super(key: key);

  @override
  _CustomBottomNavBarClienteState createState() =>
      _CustomBottomNavBarClienteState();
}

class _CustomBottomNavBarClienteState extends State<CustomBottomNavBarCliente> {
  String? firestoreProfileImageUrl;
  String? firestoreUsername; // <-- Nuevo campo
  bool isImageLoaded = false;

  @override
  void initState() {
    super.initState();

    if (widget.user == null) {
      print("⚠️ No hay usuario logueado en CustomBottomNavBarCliente");
      return; // ⛔ No seguimos, porque no hay usuario
    }

    final cachedUrl = ImageCacheHelperCliente.getProfileImage(widget.user!.uid);
    final loaded = ImageCacheHelperCliente.isImageLoaded(widget.user!.uid);

    if (!loaded) {
      getUserData(widget.user!.uid).then((data) {
        if (mounted) {
          setState(() {
            firestoreProfileImageUrl = data['profileImageUrl'];
            firestoreUsername = data['username'];
            isImageLoaded = true;
            ImageCacheHelperCliente.setProfileImage(
              widget.user!.uid,
              firestoreProfileImageUrl,
            );
          });
        }
      });
    } else {
      firestoreProfileImageUrl = cachedUrl;
      isImageLoaded = true;
    }
  }

  // Trae URL de imagen y username desde Firestore
  Future<Map<String, String?>> getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final url = data['profileImageUrl'] as String?;
        final username = data['username'] as String?;
        return {'profileImageUrl': url, 'username': username};
      }
    } catch (e, stackTrace) {
      print("Error obteniendo datos del usuario: $e");
      print("StackTrace: $stackTrace");
    }
    return {'profileImageUrl': null, 'username': null};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    double imageSize = 13;
    bool isProfileSelected = widget.currentIndex == 3;
    final String initText = (firestoreUsername?.trim().isNotEmpty ?? false)
        ? firestoreUsername!.substring(0, 1).toUpperCase()
        : (widget.user?.displayName?.trim().isNotEmpty ?? false)
        ? widget.user!.displayName!.substring(0, 1).toUpperCase()
        : 'C'; // 🔥 fallback seguro

    return SizedBox(
      height: 55,
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        backgroundColor: theme.bottomAppBarTheme.color,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onBackground.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontSize: 0),
        unselectedLabelStyle: const TextStyle(fontSize: 0),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.home, size: 30.0),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.shopping_cart, size: 30.0),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.building, size: 30.0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: imageSize + 1,
              backgroundColor: isProfileSelected
                  ? colorScheme.primary
                  : colorScheme.onBackground.withOpacity(0.6),
              child: CircleAvatar(
                radius: imageSize,
                child: isImageLoaded
                    ? (firestoreProfileImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: firestoreProfileImageUrl!,
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                    backgroundImage: imageProvider,
                                    radius: imageSize,
                                  ),
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                              errorWidget: (context, url, error) => Initicon(
                                text: initText,
                                size: imageSize * 2.5,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                                backgroundColor: Color(0xFFA30000),
                              ),
                            )
                          : Initicon(
                              text: initText,
                              size: imageSize * 2.5,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                              backgroundColor: Color(0xFFA30000),
                            ))
                    : CircularProgressIndicator(color: colorScheme.primary),
              ),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
