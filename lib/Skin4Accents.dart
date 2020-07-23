import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

///Этот скин работает всего с 4 картинками для данного типа совы. Пятую картинку Юрик не прислал, будем
///вычислять, что делать при двух акцентах.
///Картинки нумеруются двумя индексами, акцент определяется вторым индексом от 0 до 3,
///для полузакрытых глаз
///первый индекс 0, для открытых   1 (и left).
///Акценты раздаются в зависимости от максимального акцента в данном ритме.
///0 всегда рисуется картинкой 0, наибольший - всегда картинкой 3.
///Если нужно рисовать акценты (0,1,2,3), то они очевидно переходят 1 в 1;
/// (0,1) -> (0, 3);
/// остаётся случай с maxAcc=2: тут (0,1,2) ->(0,2[это произвол],3)
const int typesOfOwls = 4;

Future<ui.Image> _loadImage(String imgName) {
  Completer<ui.Image> completer = new Completer<ui.Image>();
  new AssetImage(imgName).resolve(new ImageConfiguration()).addListener(
      new ImageStreamListener((ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
      }));
  return completer.future;
}

class OwlSkin4Acc {
  ///Организация массива: 4 туши (по числу акцентов)
  final String _fileBase = 'images/owlZ-';
  ///Восемь (два по четыре) голов
  final String _fileBaseHead = 'images/nhowl';
  ///Запасем для паузы (акцент=-1)
  final String  silenceName='images/nhowl-closed.png';

  ///Ключевая функция-делегат, которая определит номер картинки для отрисовки в HeadOfWol
  List<int> getImageIndex(int accent, int maxAccent, bool bActive, bool bPlaying, bool bLeft) {
    int indexHead=typesOfOwls*3; //глазки закрывай...
    if ((accent>=0)) {//Распределим акценты
      List<int> mapAccToFile = List<int>(maxAccent + 1);
      mapAccToFile[0]=0;
      mapAccToFile[maxAccent] = typesOfOwls-1; //Получилось 0 -> 0, max-> max;
      //Теперь то, что посередке.
      if (maxAccent == 3) {        mapAccToFile[1] = 1;        mapAccToFile[2] = 2;      }
      if (maxAccent == 2) {        mapAccToFile[1] = 2; }
      indexHead = mapAccToFile[accent] +
          (/*bActive &*/ bPlaying ?
          typesOfOwls*(1+(bLeft?1:0))
          : 0);//полуоткрыты/открыты (право-лево)
      //Отзывы пользователей и прочие объективные вещи заставили меня пока сделать всех
      //сов с открытимы глазами во время игры. Чтобы открывала глаза лишь одна, выпустить bActive.
    }
    return [0,// если хотим тушки анимировать, то ставь mapToAcc[accent] (и ниже картинки закачай в loadImages)//ToDo
      indexHead];
  }

  List<Image> _images;
  List<Image> _headImages;
  Size _imageSize = Size.zero;
  Size _imageSize0 = Size.zero;
  Size _imageSizeHead0 = Size.zero;

  /// Aspect ratio of full owl image rectangle
  double aspect = 310.0 / 250.0;
  bool _isInit = false;


  OwlSkin4Acc();

  List<Image> get images => new List<Image>.unmodifiable(_images);
  List<Image> get headImages => new List<Image>.unmodifiable(_headImages);

  bool get isInit => _isInit;

  Future<bool> init() async //TODO
      {
    // TODO
    aspect = 330 / 250.0; //310 / 250.0;
    // Preload images
    Future<ui.Image> futImage = _loadImage(_fileBase + '1.png');
    Future<ui.Image> futImageHead = _loadImage(_fileBaseHead + '0-0.png');
    // Get original image dimensions
    return Future.wait([
      futImage.then((ui.Image image) {
        _imageSize0 = new Size(image.width.toDouble(), image.height.toDouble());
        print('_imageSize0 $_imageSize0');
      }),
      futImageHead.then((ui.Image image) => _imageSizeHead0 =
      new Size(image.width.toDouble(), image.height.toDouble()))
    ]).then((_) {
      _isInit = true;
      return true;
    }).catchError((Object err) {
      return false;
    });
  }


  void cacheImages(BuildContext context, Size size) {
    if (size.width != _imageSize.width &&
        _imageSize0.width > 0 &&
        _imageSize0.height > 0 &&
        _imageSizeHead0.width > 0 &&
        _imageSizeHead0.height > 0) {
      loadImages(context, size);
      precacheImages(context, size);
    }
  }

  void loadImages(BuildContext context, Size size) {
    if (size.width == _imageSize.width) return;
    _images = new List<Image>(typesOfOwls);
    // TODO 240/259
    Size bodySize = new Size(
        size.width, size.width * _imageSize0.height / _imageSize0.width);
    ///ToDo:  пока убираю разные оперения, не меняя механику
    /* //Вариант с разными оперениями
    for (int i = 0; i < kindCount; i++) {
      _images[i] = new Image.asset(_fileBase + '${i + 1}.png',
          width: bodySize.width,
          height: bodySize.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium, //TODO Choose right one
          /// !!! To prevent flickering of first owls !!!
          gaplessPlayback: true);
    }*/
    _images = List<Image>.filled(
        images.length,
        Image.asset(_fileBase + '1.png',
            width: bodySize.width,
            height: bodySize.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium, //TODO Choose right one
            /// !!! To prevent flickering of first owls !!!
            gaplessPlayback: true));

    // TODO 205/259
    _headImages = new List<Image>(3*typesOfOwls+1);//прикрытые, открытые (два вида) и еще запасём тишину в конце
    Size headSize = new Size(size.width,
        size.width * _imageSizeHead0.height / _imageSizeHead0.width);
    int iImage = 0;
    for (int i = 0; i <=2; i++) {
      for (int j = 0; j < typesOfOwls; j++, iImage++) {
        int iOpen=(i<2)?i:1;
        String sForLeft=(i==2)?"left":'';
        _headImages[iImage] = new Image.asset(_fileBaseHead + '$iOpen-$j'+sForLeft+'.png',
            width: headSize.width,
            height: headSize.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium, //TODO Choose right one
            /// !!! To prevent flickering of first owls !!!
            gaplessPlayback: true);
      }
    }
    //Закрытые глаза:
    _headImages[3*typesOfOwls]=   new Image.asset(silenceName,
        width: headSize.width,
        height: headSize.height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium, //TODO Choose right one
        /// !!! To prevent flickering of first owls !!!
        gaplessPlayback: true);
    /*
    print('loadImages $size - $bodySize - $headSize');
    debugPrint('loadImages $size');*/
  }

  /// Using precacheImages in didChangeDependencies as they suggested don't have any effect
  void precacheImages(BuildContext context, Size size) {
    if (size.width != _imageSize.width)
        {
      Size bodySize = new Size(
          size.width, size.width * _imageSize0.height / _imageSize0.width);
      for (int i = 0; i < _images.length; i++)
        precacheImage(_images[i].image, context, size: bodySize);

      Size headSize = new Size(size.width,
          size.width * _imageSizeHead0.height / _imageSizeHead0.width);
      for (int i = 0; i < _headImages.length; i++)
        precacheImage(_headImages[i].image, context, size: headSize);
      _imageSize = size;
    }
  }
}
