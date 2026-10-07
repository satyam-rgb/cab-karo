import 'package:url_launcher/url_launcher.dart';
import '../models/coordinate_model.dart';

class ProviderLauncherService {
  static Future<bool> launchProvider({
    required String provider,
    String? category,
    LocationCoordinate? pickupCoord,
    LocationCoordinate? dropCoord,
    String? pickupAddress,
    String? dropAddress,
  }) async {
    final prov = provider.toLowerCase();

    if (prov.contains('uber')) {
      return _launchUber(
        pickupCoord: pickupCoord,
        dropCoord: dropCoord,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
      );
    } else if (prov.contains('ola')) {
      return _launchOla(
        pickupCoord: pickupCoord,
        dropCoord: dropCoord,
        category: category,
      );
    }

    // Generic search fallback
    final genericUrl = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent('$provider cab booking')}',
    );
    return launchUrl(genericUrl, mode: LaunchMode.externalApplication);
  }

  static Future<bool> _launchUber({
    LocationCoordinate? pickupCoord,
    LocationCoordinate? dropCoord,
    String? pickupAddress,
    String? dropAddress,
  }) async {
    final pLat = pickupCoord?.latitude ?? 21.1458;
    final pLng = pickupCoord?.longitude ?? 79.0882;
    final dLat = dropCoord?.latitude ?? 21.0922;
    final dLng = dropCoord?.longitude ?? 79.0474;

    final pNick = Uri.encodeComponent(pickupAddress ?? 'Pickup');
    final dNick = Uri.encodeComponent(dropAddress ?? 'Destination');

    // 1. Try native scheme first on mobile devices
    final deepLinkUri = Uri.parse(
      'uber://?action=setPickup&pickup[latitude]=$pLat&pickup[longitude]=$pLng&dropoff[latitude]=$dLat&dropoff[longitude]=$dLng',
    );

    if (await canLaunchUrl(deepLinkUri)) {
      final success = await launchUrl(deepLinkUri);
      if (success) return true;
    }

    // 2. Fallback to official Uber universal link
    final universalLinkUri = Uri.parse(
      'https://m.uber.com/ul/?action=setPickup&pickup[latitude]=$pLat&pickup[longitude]=$pLng&pickup[nickname]=$pNick&dropoff[latitude]=$dLat&dropoff[longitude]=$dLng&dropoff[nickname]=$dNick',
    );

    return launchUrl(universalLinkUri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> _launchOla({
    LocationCoordinate? pickupCoord,
    LocationCoordinate? dropCoord,
    String? category,
  }) async {
    final pLat = pickupCoord?.latitude ?? 21.1458;
    final pLng = pickupCoord?.longitude ?? 79.0882;
    final dLat = dropCoord?.latitude ?? 21.0922;
    final dLng = dropCoord?.longitude ?? 79.0474;

    final isAuto = category?.toLowerCase().contains('auto') ?? false;
    final catParam = isAuto ? '&category=auto' : '&category=prime';

    // 1. Try native app scheme
    final deepLinkUri = Uri.parse(
      'olacabs://app/launch?lat=$pLat&lng=$pLng&drop_lat=$dLat&drop_lng=$dLng$catParam',
    );

    if (await canLaunchUrl(deepLinkUri)) {
      final success = await launchUrl(deepLinkUri);
      if (success) return true;
    }

    // 2. Fallback to official web booking
    final webUri = Uri.parse(
      'https://book.olacabs.com/?pickup_lat=$pLat&pickup_lng=$pLng&drop_lat=$dLat&drop_lng=$dLng',
    );

    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
