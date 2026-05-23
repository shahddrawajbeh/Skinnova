// import 'dart:io';
// import 'dart:math';
// //import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:image/image.dart' as img;

// class SkinImageQualityResult {
//   final bool isValid;
//   final String message;
//   final Map<String, bool> checks;

//   SkinImageQualityResult({
//     required this.isValid,
//     required this.message,
//     required this.checks,
//   });
// }

// class SkinImageQualityService {
//   static Future<SkinImageQualityResult> checkImage(File imageFile) async {
//     final inputImage = InputImage.fromFile(imageFile);

//     final faceDetector = FaceDetector(
//       options: FaceDetectorOptions(
//         performanceMode: FaceDetectorMode.accurate,
//         enableLandmarks: true,
//         enableContours: false,
//       ),
//     );

//     final faces = await faceDetector.processImage(inputImage);
//     await faceDetector.close();

//     if (faces.isEmpty) {
//       return _fail("No face detected. Please upload a clear face photo.", {
//         "Face detected": false,
//       });
//     }

//     if (faces.length > 1) {
//       return _fail("Please upload a photo with one face only.", {
//         "One face only": false,
//       });
//     }

//     final bytes = await imageFile.readAsBytes();
//     final decodedImage = img.decodeImage(bytes);

//     if (decodedImage == null) {
//       return _fail("Could not read this image. Please try another photo.", {});
//     }

//     final face = faces.first;
//     final imageWidth = decodedImage.width;
//     final imageHeight = decodedImage.height;

//     final faceBox = face.boundingBox;
//     final faceArea = faceBox.width * faceBox.height;
//     final imageArea = imageWidth * imageHeight;
//     final faceRatio = faceArea / imageArea;

//     final faceCenterX = faceBox.left + faceBox.width / 2;
//     final faceCenterY = faceBox.top + faceBox.height / 2;

//     final centerX = imageWidth / 2;
//     final centerY = imageHeight / 2;

//     final distanceFromCenter =
//         sqrt(pow(faceCenterX - centerX, 2) + pow(faceCenterY - centerY, 2));

//     final maxAllowedDistance = imageWidth * 0.25;

//     final brightness = _calculateBrightness(decodedImage);
//     final sharpness = _calculateSharpness(decodedImage);

//     final checks = {
//       "Face detected": true,
//       "One face only": true,
//       "Face close enough": faceRatio >= 0.12,
//       "Face centered": distanceFromCenter <= maxAllowedDistance,
//       "Good lighting": brightness >= 70 && brightness <= 200,
//       "Clear image": sharpness >= 12,
//     };

//     if (!checks["Face close enough"]!) {
//       return _fail("Move closer to the camera.", checks);
//     }

//     if (!checks["Face centered"]!) {
//       return _fail("Center your face in the frame.", checks);
//     }

//     if (brightness < 70) {
//       return _fail("The image is too dark. Use better lighting.", checks);
//     }

//     if (brightness > 200) {
//       return _fail("The image is too bright. Avoid strong light.", checks);
//     }

//     if (sharpness < 12) {
//       return _fail(
//           "The image is blurry. Please retake a clearer photo.", checks);
//     }

//     return SkinImageQualityResult(
//       isValid: true,
//       message: "Image is ready for skin analysis.",
//       checks: checks,
//     );
//   }

//   static SkinImageQualityResult _fail(
//     String message,
//     Map<String, bool> checks,
//   ) {
//     return SkinImageQualityResult(
//       isValid: false,
//       message: message,
//       checks: checks,
//     );
//   }

//   static double _calculateBrightness(img.Image image) {
//     double total = 0;
//     int count = 0;

//     for (int y = 0; y < image.height; y += 10) {
//       for (int x = 0; x < image.width; x += 10) {
//         final pixel = image.getPixel(x, y);
//         final brightness = (pixel.r + pixel.g + pixel.b) / 3;
//         total += brightness;
//         count++;
//       }
//     }

//     return total / count;
//   }

//   static double _calculateSharpness(img.Image image) {
//     double totalDiff = 0;
//     int count = 0;

//     for (int y = 1; y < image.height - 1; y += 10) {
//       for (int x = 1; x < image.width - 1; x += 10) {
//         final current = image.getPixel(x, y);
//         final right = image.getPixel(x + 1, y);
//         final bottom = image.getPixel(x, y + 1);

//         final currentGray = (current.r + current.g + current.b) / 3;
//         final rightGray = (right.r + right.g + right.b) / 3;
//         final bottomGray = (bottom.r + bottom.g + bottom.b) / 3;

//         totalDiff += (currentGray - rightGray).abs();
//         totalDiff += (currentGray - bottomGray).abs();
//         count += 2;
//       }
//     }

//     return totalDiff / count;
//   }
// }
