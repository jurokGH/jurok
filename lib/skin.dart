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
  final int kindCount = 5;  // == accentCount + 1
  final int frameCount = 5;  // == subbeatCount
  //List<List<Image>> _images;
  List<Image> _images;
  Size _imageSize = Size.zero;
  Size _imageSize0 = Size.zero;
  double aspect = 1;

  int animationType = 0;

  OwlSkin();

  List<Image> get images => new List<Image>.unmodifiable(_images);

  Future<bool> init() async //TODO
  {
    Future<ui.Image> futImage = _loadImage('images/owl1-0.png');
    futImage.then((ui.Image image) => _imageSize0 = new Size(image.width.toDouble(), image.height.toDouble()));
    aspect = _imageSize0.width > 0 ? _imageSize0.height / _imageSize0.width : 310 / 250.0;
    return new Future.value(true);
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

  int getImageIndex(int accent, int subbeat, int subbeatCount)
  {
    int indexImage = 0;
    if (accent >= 0)  // Select image with switched ON owl
    {
      indexImage = 2 + frameCount * accent;
      if (subbeat >= 0)  // Select image with active owl
      {
        subbeat = subbeat % subbeatCount;

        if (animationType == 0)
          indexImage += subbeat % 3 + 1;
        else if (animationType == 1)
        {
          subbeat = subbeat % 4;
          if (subbeat == 0 || subbeat == 2)
            indexImage += 1;
          else if (subbeat == 1)
            indexImage += 2;
          else if (subbeat == 3)
            indexImage += 3;
        }
        else if (animationType == 2)
          indexImage += subbeat % 2 == 0 ? 2 : 3;
        else if (animationType == 3)
          indexImage += subbeat % 2 == 0 ? 1 : 4;
        else if (animationType == 4)
        {
          if (subbeatCount <= 2)
            indexImage += subbeat == 1 ? 4 : 1;
          else
            indexImage += subbeat % 3 + 1;
        }
      }
    }
    else
      indexImage = 0;
    return indexImage;
  }

  void cacheImages(BuildContext context, Size size)
  {
    if (size != _imageSize)
    {
      loadImages(context, size);
      precacheImages(context, size);
    }
  }

  void loadImages(BuildContext context, Size size)
  {
    if (size == _imageSize)
      return;

    //_imageSize = size;
    //AssetImage
    _images = new List<Image>(2 + (kindCount - 1) * frameCount);
    int iImage = 0;
    for (int i = 0; i < kindCount; i++)
    {
      //List<Image> il = new List<Image>(5);
      //_images[i] = il;
      int jCount = i == 0 ? 2 : frameCount;
      for (int j = 0; j < jCount; j++, iImage++)
      {
        _images[iImage] = new Image.asset('images/owl$i-$j.png',
          width: size.width,
          //height: size.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium, //TODO Choose right one
          /// !!! To prevent flickering of first owls !!!
          gaplessPlayback: true);
      }
    }

    debugPrint('loadImages $size');
  }

  /// Using precacheImages in didChangeDependencies as they suggested don't have any effect
  void precacheImages(BuildContext context, Size size)
  {
    if (size != _imageSize)
    {
      for (int i = 0; i < _images.length; i++)
        precacheImage(_images[i].image, context, size: size);
      _imageSize = size;
    }
  }
}
