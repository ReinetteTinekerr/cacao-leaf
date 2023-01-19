import 'dart:io';

import 'package:cacao_leaf_detector/src/db/picture_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../main.dart';

enum ScreenMode { liveFeed, gallery }

class CameraView extends StatefulWidget {
  const CameraView(
      {Key? key,
      required this.title,
      required this.customPaint,
      this.text,
      required this.onImage,
      this.onScreenModeChanged,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  ScreenMode _mode = ScreenMode.liveFeed;
  CameraController? _controller;
  Uint8List? imageSelected;
  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  final bool _allowPicker = true;
  bool _changingCameraLens = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();

    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }

    if (_cameraIndex != -1) {
      _startLiveFeed();
    } else {
      _mode = ScreenMode.gallery;
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_allowPicker)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: _switchScreenMode,
                child: Icon(
                  _mode == ScreenMode.liveFeed
                      ? Icons.photo_library_outlined
                      : (Platform.isIOS
                          ? Icons.camera_alt_outlined
                          : Icons.camera),
                ),
              ),
            ),
        ],
      ),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget? _floatingActionButton() {
    if (_mode == ScreenMode.gallery) return null;
    if (cameras.length == 1) return null;
    return Container(
        padding: const EdgeInsets.only(left: 20),
        height: 70.0,
        width: 70.0,
        child: FloatingActionButton(
          onPressed: _switchLiveCamera,
          child: Icon(
            Platform.isIOS
                ? Icons.flip_camera_ios_outlined
                : Icons.flip_camera_android_outlined,
            size: 40,
          ),
        ));
  }

  Widget _body() {
    Widget body;
    if (_mode == ScreenMode.liveFeed) {
      body = _liveFeedBody();
    } else {
      body = _galleryBody();
    }
    return body;
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? const Center(
                      child: Text('Changing camera lens'),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null) widget.customPaint!,
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Slider(
              value: zoomLevel,
              min: minZoomLevel,
              max: maxZoomLevel,
              onChanged: (newSliderValue) {
                setState(() {
                  zoomLevel = newSliderValue;
                  _controller!.setZoomLevel(zoomLevel);
                });
              },
              divisions: (maxZoomLevel - 1).toInt() < 1
                  ? null
                  : (maxZoomLevel - 1).toInt(),
            ),
          )
        ],
      ),
    );
  }

  Widget _galleryBody() {
    return ListView(shrinkWrap: true, children: [
      _image != null
          ? SizedBox(
              height: 400,
              width: 400,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(_image!),
                  if (widget.customPaint != null) widget.customPaint!,
                ],
              ),
            )
          : Icon(
              Icons.image,
              size: 200,
            ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('From Gallery'),
          onPressed: () => _getImage(ImageSource.gallery),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('Take a picture'),
          onPressed: () => _getImage(ImageSource.camera),
        ),
      ),
      if (_image != null)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
              '${_path == null ? '' : 'Image path: $_path'}\n\n${widget.text ?? ''}'),
        ),
    ]);
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);

      // final _storeImage = File(pickedFile.path);
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      print('SAVE TO ================================= ${pickedFile.name}');
      final savePath = '$appDocPath/${pickedFile.name}';
      await pickedFile.saveTo('$appDocPath/${pickedFile.name}');

      Picture picture = Picture(
          title: DateTime.now().toIso8601String(),
          date: DateTime.now(),
          picture: savePath);
      objectBox.savePicture(picture);
    }
    setState(() {});
  }

  void _switchScreenMode() {
    _image = null;
    if (_mode == ScreenMode.liveFeed) {
      _mode = ScreenMode.gallery;
      _stopLiveFeed();
    } else {
      _mode = ScreenMode.liveFeed;
      _startLiveFeed();
    }
    if (widget.onScreenModeChanged != null) {
      widget.onScreenModeChanged!(_mode);
    }
    setState(() {});
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        zoomLevel = value;
        minZoomLevel = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        maxZoomLevel = value;
      });
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }
    setState(() {
      _image = File(path);
    });
    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    widget.onImage(inputImage);
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final byteData = allBytes.done();
    final bytes = byteData.buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage);
  }

  void capture() {
    // if (_cameraImage != null) {
    //   img.Image image = img.Image.fromBytes(
    //       width:_cameraImage!.width, height:_cameraImage!.height,
    //       _cameraImage!.planes[0].bytes, format: img.Format.bgra);
    //   Uint8List list = Uint8List.fromList(img.encodeJpg(image));
    //   _imageList.add(list);
    //   _imageList.refresh();
    // }
    // final WriteBuffer allBytes = WriteBuffer();
    // for (final Plane plane in _cameraImage.planes) {
    //   allBytes.putUint8List(plane.bytes);
    // }
    // final byteData = allBytes.done();

    // imglib.Image imgData = imglib.Image.fromBytes(
    //   width: _cameraImage.width,
    //   height: _cameraImage.height,
    //   bytes: _cameraImage.planes[0].,
    // );
    // final jpeg = imgData.toUint8List();
    // imageSelected = jpeg;
    // print('============= ${byteData.buffer.toString()}');
    // return jpeg;
  }

  // imglib.Image convertYUV420ToImage(CameraImage cameraImage) {
  //   final imageWidth = cameraImage.width;
  //   final imageHeight = cameraImage.height;

  //   final yBuffer = cameraImage.planes[0].bytes;
  //   final uBuffer = cameraImage.planes[1].bytes;
  //   final vBuffer = cameraImage.planes[2].bytes;

  //   final int yRowStride = cameraImage.planes[0].bytesPerRow;
  //   final int yPixelStride = cameraImage.planes[0].bytesPerPixel!;

  //   final int uvRowStride = cameraImage.planes[1].bytesPerRow;
  //   final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

  //   final image = imglib.Image(width: imageWidth, height: imageHeight);

  //   for (int h = 0; h < imageHeight; h++) {
  //     int uvh = (h / 2).floor();

  //     for (int w = 0; w < imageWidth; w++) {
  //       int uvw = (w / 2).floor();

  //       final yIndex = (h * yRowStride) + (w * yPixelStride);

  //       // Y plane should have positive values belonging to [0...255]
  //       final int y = yBuffer[yIndex];

  //       // U/V Values are subsampled i.e. each pixel in U/V chanel in a
  //       // YUV_420 image act as chroma value for 4 neighbouring pixels
  //       final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

  //       // U/V values ideally fall under [-0.5, 0.5] range. To fit them into
  //       // [0, 255] range they are scaled up and centered to 128.
  //       // Operation below brings U/V values to [-128, 127].
  //       final int u = uBuffer[uvIndex];
  //       final int v = vBuffer[uvIndex];

  //       // Compute RGB values per formula above.
  //       int r = (y + v * 1436 / 1024 - 179).round();
  //       int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
  //       int b = (y + u * 1814 / 1024 - 227).round();

  //       r = r.clamp(0, 255);
  //       g = g.clamp(0, 255);
  //       b = b.clamp(0, 255);

  //       // Use 255 for alpha value, no transparency. ARGB values are
  //       // positioned in each byte of a single 4 byte integer
  //       // [AAAAAAAARRRRRRRRGGGGGGGGBBBBBBBB]
  //       final int argbIndex = h * imageWidth + w;
  //       image.data[argbIndex] = 0xff000000 |
  //           ((b << 16) & 0xff0000) |
  //           ((g << 8) & 0xff00) |
  //           (r & 0xff);
  //     }
  //   }

  //   return image;
  // }
}
