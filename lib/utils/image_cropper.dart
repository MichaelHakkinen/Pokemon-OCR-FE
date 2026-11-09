import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCropperHelper {
  /**
   * Slices the captured camera image precisely to the card cutout rectangle.
   * Accurately scales coordinates from UI screen pixels to native image sensor pixels.
   */
  static Future<File> cropImageToCutout({
    required String sourceImagePath,
    required Rect cutoutRect,
    required Size screenSize,
  }) async {
    // 1. Read source image file bytes
    final sourceBytes = await File(sourceImagePath).readAsBytes();
    final decodedImage = img.decodeImage(sourceBytes);

    if (decodedImage == null) {
      throw Exception('Failed to decode captured image for cropping.');
    }

    // 2. Handle camera orientation / bake orientation if needed
    final orientedImage = img.bakeOrientation(decodedImage);

    final double imageWidth = orientedImage.width.toDouble();
    final double imageHeight = orientedImage.height.toDouble();

    // 3. Compute scale factors between screen UI and actual captured image resolution
    // When CameraPreview uses BoxFit.cover:
    final double scaleX = imageWidth / screenSize.width;
    final double scaleY = imageHeight / screenSize.height;

    // Use the max scale if BoxFit.cover is used
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    // Center offset difference if aspect ratios differ
    final double renderedWidth = screenSize.width * scale;
    final double renderedHeight = screenSize.height * scale;
    final double offsetX = (renderedWidth - imageWidth) / 2.0;
    final double offsetY = (renderedHeight - imageHeight) / 2.0;

    // 4. Map screen cutoutRect to pixel coordinates on image
    int cropX = ((cutoutRect.left * scale) - offsetX).round();
    int cropY = ((cutoutRect.top * scale) - offsetY).round();
    int cropW = (cutoutRect.width * scale).round();
    int cropH = (cutoutRect.height * scale).round();

    // 5. Clamp bounds within actual image dimensions to prevent out-of-bounds error
    cropX = cropX.clamp(0, orientedImage.width - 1);
    cropY = cropY.clamp(0, orientedImage.height - 1);
    cropW = cropW.clamp(1, orientedImage.width - cropX);
    cropH = cropH.clamp(1, orientedImage.height - cropY);

    // 6. Crop using image package
    final croppedImage = img.copyCrop(
      orientedImage,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // 7. Write cropped JPEG to temporary cache directory
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/cropped_card_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final croppedFile = File(targetPath);

    final jpgBytes = img.encodeJpg(croppedImage, quality: 90);
    await croppedFile.writeAsBytes(jpgBytes);

    return croppedFile;
  }
}

