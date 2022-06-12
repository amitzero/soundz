import 'dart:developer';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdData {
  Future<InitializationStatus> status;

  AdData(this.status);

  String get bannerAdUnitId =>
      'ca-app-pub-3940256099942544/6300978111'; //test ad
      // 'ca-app-pub-6699737363209117/7067853459';

  BannerAdListener get listener => BannerAdListener(
        onAdClicked: (ad) {
          log('onAdClicked: $ad');
        },
        onAdClosed: (ad) {
          log('onAdClosed: $ad');
        },
        onAdFailedToLoad: (ad, error) {
          log('onAdFailedToLoad: ${ad.adUnitId}, $error');
        },
        onAdLoaded: (ad) {
          log('onAdLoaded: $ad');
        },
        onAdOpened: (ad) {
          log('onAdOpened: $ad');
        },
      );
}
