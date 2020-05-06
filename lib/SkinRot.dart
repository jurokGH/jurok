import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

Future<ui.Image> _loadImage(String imgName)
{
  Completer<ui.Image> completer = new Completer<ui.Image>();
  new AssetImage(imgName).resolve(new ImageConfiguration())
    .addListener(new ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
      completer.complete(info.image);
    }
  ));
  return completer.future;
}

class OwlSkinRot
{
  final int kindCount = 4;  // == accentCount + 1
  final int frameCount = 5;  // == subbeatCount
  final String _fileBase = 'images/owl6-';
  final String _fileBaseHead = 'images/owl6h-';
  //List<List<Image>> _images;
  List<Image> _images;
  List<Image> _headImages;
  Size _imageSize = Size.zero;
  Size _imageSize0 = Size.zero;
  Size _imageSizeHead = Size.zero;
  Size _imageSizeHead0 = Size.zero;
  /// Aspect ratio of full owl image rectangle
  double aspect = 310.0 / 250.0;
  bool _isInit = false;

  int animationType;

  OwlSkinRot([this.animationType = 0]);

  List<Image> get images => new List<Image>.unmodifiable(_images);
  List<Image> get headImages => new List<Image>.unmodifiable(_headImages);

  bool get isInit => _isInit;

  Future<bool> init() async //TODO
  {
    // TODO
    aspect = 330 / 250.0;//310 / 250.0;
    // Preload images
    Future<ui.Image> futImage = _loadImage(_fileBase + '1.png');
    Future<ui.Image> futImageHead = _loadImage(_fileBaseHead + '0-0.png');
    // Get original image dimensions
    Future.wait([
      futImage.then((ui.Image image) {
        _imageSize0 = new Size(image.width.toDouble(), image.height.toDouble());
        print('_imageSize0 $_imageSize0');
      }),
      futImageHead.then((ui.Image image) =>
        _imageSizeHead0 = new Size(image.width.toDouble(), image.height.toDouble()))
    ]).then((_) {
      _isInit = true;
      //aspect = _imageSize0.width > 0 ? _imageSize0.height / _imageSize0.width : 310 / 250.0;
      return new Future.value(true);
    }).catchError((Object err) {
      return new Future.value(false);
    });
  }

/*
    int indexImage = active ? 3 : 0;
    if (active && widget.subbeatCount > 1)
    {
      indexImage = activeSubbeat % widget.subbeatCount + 1;
      if (indexImage > 4) //TODO
        indexImage = 1 + indexImage % 4;
    }
*/
  /*
    int indexImage = 2 * (widget.nAccent + 1);
    if (active)
    {
      //indexImage++;
      indexImage += activeSubbeat % 2;
    }

    //debugPrint('OwlState: ${widget.id} - $beat0 - $_counter - $active - ${widget.active} - $activeSubbeat - ${widget.activeSubbeat}');
    //if (subbeatCount != widget.subbeatCount)
      //debugPrint('!Owl:subbeatCount ${widget.subbeatCount}');
    //if (active != widget.active)
      //debugPrint('!Owl:active $active ${widget.active}');
*/

  List<int> getImageIndex(int accent, int subbeat, int maxAccent, int subbeatCount)
  {
    //if (accent >= 0)  // Select image with switched ON owl
    // Show 'strong' owl for maximum accent
    int indexBody = (accent < maxAccent || maxAccent == 0 ? accent : kindCount - 1);
    // Select image with active owl
    //subbeat = subbeat % subbeatCount;
    int indexHead = subbeat >= 0 ? 2 : 0;
    indexHead += indexBody == kindCount - 1 ? 1 : 0;
    return [indexBody, indexHead];
  }

  void cacheImages(BuildContext context, Size size)
  {
    if (size.width != _imageSize.width &&
      _imageSize0.width > 0 && _imageSize0.height > 0 &&
      _imageSizeHead0.width > 0 && _imageSizeHead0.height > 0)
    {
      loadImages(context, size);
      precacheImages(context, size);
    }
  }

  void loadImages(BuildContext context, Size size)
  {
    //if (size == _imageSize)
    if (size.width == _imageSize.width)
      return;

    //_imageSize = size;
    //AssetImage
    _images = new List<Image>(kindCount);
    // TODO 240/259
    Size bodySize = new Size(size.width, size.width * _imageSize0.height / _imageSize0.width);
    for (int i = 0; i < kindCount; i++)
    {
      _images[i] = new Image.asset(_fileBase + '${i + 1}.png',
        width: bodySize.width,
        height: bodySize.height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium, //TODO Choose right one
        /// !!! To prevent flickering of first owls !!!
        gaplessPlayback: true);
    }
    // TODO 205/259
    _headImages = new List<Image>(kindCount);
    Size headSize = new Size(size.width, size.width * _imageSizeHead0.height / _imageSizeHead0.width);
    int iImage = 0;
    for (int i = 0; i < 2; i++)
    {
      for (int j = 0; j < 2; j++, iImage++)
      {
        _headImages[iImage] = new Image.asset(_fileBaseHead + '$i-$j.png',
          width: headSize.width,
          height: headSize.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium, //TODO Choose right one
          /// !!! To prevent flickering of first owls !!!
          gaplessPlayback: true);
      }
    }

    print('loadImages $size - $bodySize - $headSize');
    debugPrint('loadImages $size');
  }

  /// Using precacheImages in didChangeDependencies as they suggested don't have any effect
  void precacheImages(BuildContext context, Size size)
  {
    if (size.width != _imageSize.width)
    //if (size != _imageSize)
    {
      Size sz1 = new Size(_images[0].width, _images[0].height);
      Size bodySize = new Size(size.width, size.width * _imageSize0.height / _imageSize0.width);
      for (int i = 0; i < _images.length; i++)
        precacheImage(_images[i].image, context, size: bodySize);

      Size sz2 = new Size(_headImages[0].width, _headImages[0].height);
      Size headSize = new Size(size.width, size.width * _imageSizeHead0.height / _imageSizeHead0.width);
      for (int i = 0; i < _headImages.length; i++)
        precacheImage(_headImages[i].image, context, size: headSize);
      _imageSize = size;
      _imageSizeHead = headSize;
    }
  }
}
