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

class OwlSkin
{
  final kindCount = 5;  // == accentCount + 1
  final frameCount = 5;  // == subbeatCount
  //List<List<Image>> _images;
  List<Image> _images;
  Size _imageSize = Size.zero;
  Size _imageSize0 = Size.zero;
  double aspect = 1;

  OwlSkin();

  List<Image> get images => new List<Image>.unmodifiable(_images);

  bool init()
  {
    Future<ui.Image> futImage = _loadImage('images/owl1-0.png');
    futImage.then((ui.Image image) => _imageSize0 = new Size(image.width.toDouble(), image.height.toDouble()));
    aspect = _imageSize0.width > 0 ? _imageSize0.height / _imageSize0.width : 310 / 250.0;
    return true;
  }

  int getImageIndex(int accent, int subbeat, int subbeatCount)
  {
    int indexImage = 0;
    if (accent >= 0)  // Select image with switched ON owl
    {
      indexImage = 2 + frameCount * accent;
      if (subbeat >= 0)  // Select image with active owl
      {
        subbeat = subbeat % subbeatCount;
        if (subbeatCount <= 2)
          indexImage += subbeat > 0 ? 4 : 1;
        else
        {
          indexImage += subbeat % 3 + 1;
        }
      }
    }
    return indexImage;
  }

  void cacheImages(BuildContext context, Size size)
  {
    loadImages(context, size);
    precacheImages(context, size);
  }

  void loadImages(BuildContext context, Size size)
  {
    if (_imageSize == size)
      return;

    _imageSize = size;
    //AssetImage
    _images = new List<Image>(2 + (kindCount - 1) * frameCount);
    int iImage = 0;
    for (int i = 0; i < kindCount; i++)
    {
      //List<Image> il = new List<Image>(5);
      //_images[i] = il;
      int i1 = i < 2 ? i : 1;
      int jCount = i == 0 ? 2 : frameCount;
      for (int j = 0; j < jCount; j++, iImage++)
      {
        _images[iImage] = new Image.asset('images/owl$i1-$j.png',
          width: size.width,
          //height: size.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium, //TODO Choose right one
          /// !!! To prevent flickering of first owls !!!
          gaplessPlayback: true);
      }
    }

    //debugPrint('loadImages $size');
  }

  /// Using precacheImages in didChangeDependencies as they suggested don't have any effect
  void precacheImages(BuildContext context, Size size)
  {
    //debugPrint('precacheImages');
    for (int i = 0; i < _images.length; i++)
      precacheImage(_images[i].image, context);
  }
}
