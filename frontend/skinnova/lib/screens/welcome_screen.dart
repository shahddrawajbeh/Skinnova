// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:video_player/video_player.dart';
// import 'auth_popup.dart';

// class WelcomeScreen extends StatefulWidget {
//   const WelcomeScreen({super.key});

//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> {
//   static const Color beetroot = Color(0xFFAC9C90);
//   static const Color barelyMauve = Color(0xFFD5C4BE);
//   static const Color softLight = Color(0xFFF1E9E2);
//   static const Color softRose = Color(0xFFC8CEC7);

//   late VideoPlayerController _videoController;
//   bool _isReady = false;

//   @override
//   void initState() {
//     super.initState();
//     _initVideo();
//   }

//   Future<void> _initVideo() async {
//     _videoController = VideoPlayerController.asset('assets/videos/video1.mp4');

//     await _videoController.initialize();
//     await _videoController.setLooping(true);
//     await _videoController.setVolume(0.0);
//     await _videoController.play();

//     if (mounted) {
//       setState(() {
//         _isReady = true;
//       });
//     }
//   }

//   void _openAuthPopup() {
//     showGeneralDialog(
//       context: context,
//       barrierLabel: "Auth",
//       barrierDismissible: true,
//       barrierColor: Colors.black.withOpacity(0.22),
//       transitionDuration: const Duration(milliseconds: 500),
//       pageBuilder: (context, animation, secondaryAnimation) {
//         return const AuthPopup();
//       },
//       transitionBuilder: (context, animation, secondaryAnimation, child) {
//         final curved = CurvedAnimation(
//           parent: animation,
//           curve: Curves.easeOutCubic,
//         );

//         return FadeTransition(
//           opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
//           child: SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(0, 0.18),
//               end: Offset.zero,
//             ).animate(curved),
//             child: ScaleTransition(
//               scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
//               child: child,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _videoController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: softLight,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: _isReady
//                 ? FittedBox(
//                     fit: BoxFit.cover,
//                     child: SizedBox(
//                       width: _videoController.value.size.width,
//                       height: _videoController.value.size.height,
//                       child: VideoPlayer(_videoController),
//                     ),
//                   )
//                 : Container(
//                     color: softLight,
//                     child: const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   ),
//           ),
//           Positioned.fill(
//             child: Container(
//               color: beetroot.withOpacity(0.10),
//             ),
//           ),
//           Positioned.fill(
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     beetroot.withOpacity(0.30),
//                     beetroot.withOpacity(0.10),
//                     Colors.transparent,
//                     Colors.transparent,
//                   ],
//                   stops: const [0.0, 0.18, 0.40, 1.0],
//                 ),
//               ),
//             ),
//           ),
//           Positioned.fill(
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.transparent,
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.12),
//                     beetroot.withOpacity(0.72),
//                     beetroot.withOpacity(0.94),
//                   ],
//                   stops: const [0.0, 0.42, 0.62, 0.82, 1.0],
//                 ),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//               child: Column(
//                 children: [
//                   const Spacer(),
//                   Text(
//                     'Welcome to Skinova',
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.marcellus(
//                       fontSize: 32,
//                       fontWeight: FontWeight.w700,
//                       color: softLight,
//                       height: 1.15,
//                       letterSpacing: -0.4,
//                       shadows: [
//                         Shadow(
//                           blurRadius: 18,
//                           offset: const Offset(0, 6),
//                           color: Colors.black.withOpacity(0.25),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Your ultimate companion for your skincare journey. Achieve healthier skin with personalized routines and progress tracking.',
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w400,
//                       color: barelyMauve.withOpacity(0.95),
//                       height: 1.55,
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 58,
//                     child: ElevatedButton(
//                       onPressed: _openAuthPopup,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: softLight,
//                         foregroundColor: beetroot,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(999),
//                         ),
//                       ),
//                       child: Text(
//                         'Get Started',
//                         style: GoogleFonts.marcellus(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'auth_popup.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);

  late VideoPlayerController _videoController;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/video1.mp4');

    await _videoController.initialize();
    await _videoController.setLooping(true);
    await _videoController.setVolume(0.0);
    await _videoController.play();

    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  void _openAuthPopup() {
    showGeneralDialog(
      context: context,
      barrierLabel: "Auth",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.22),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AuthPopup();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteSmoke,
      body: Stack(
        children: [
          Positioned.fill(
            child: _isReady
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(
                    color: whiteSmoke,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Container(
              color: wine.withOpacity(0.10),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    wine.withOpacity(0.30),
                    wine.withOpacity(0.10),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.18, 0.40, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.12),
                    wine.withOpacity(0.72),
                    wine.withOpacity(0.94),
                  ],
                  stops: const [0.0, 0.42, 0.62, 0.82, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'Welcome to Skinova',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.marcellus(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: whiteSmoke,
                      height: 1.15,
                      letterSpacing: -0.4,
                      shadows: [
                        Shadow(
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                          color: Colors.black.withOpacity(0.25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your ultimate companion for your skincare journey. Achieve healthier skin with personalized routines and progress tracking.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: whiteSmoke.withOpacity(0.95),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _openAuthPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteSmoke,
                        foregroundColor: wine,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'Get Started',
                        style: GoogleFonts.marcellus(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
