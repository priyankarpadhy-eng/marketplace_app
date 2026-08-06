import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ride.dart';
import '../screens/ride_detail_screen.dart';
import '../models/app_user.dart';
import '../services/ride_service.dart';
import '../providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../widgets/ride_share_card.dart';

class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._internal();
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void init(BuildContext context, WidgetRef ref) {
    _appLinks = AppLinks();

    // Check initial link if app was closed
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(context, uri, ref);
      }
    });

    // Listen for links while app is in foreground/background
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(context, uri, ref);
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleDeepLink(BuildContext context, Uri uri, WidgetRef ref) async {
    print('Received deep link: $uri');
    
    // Format: marketapp://ride/{id} or https://igitmarketplace.vercel.app/ride/{id}
    if (uri.pathSegments.contains('ride')) {
      final rideId = uri.pathSegments.last;
      _navigateToRide(context, rideId, ref);
    } else if (uri.queryParameters.containsKey('rideId')) {
      final rideId = uri.queryParameters['rideId']!;
      _navigateToRide(context, rideId, ref);
    }
  }

  Future<void> _navigateToRide(BuildContext context, String rideId, WidgetRef ref) async {
    try {
      final rideService = RideService();
      final ride = await rideService.getRideById(rideId);
      final userState = ref.read(userProvider);
      final currentUser = userState.currentUser;

      if (ride != null && currentUser != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RideDetailScreen(
              ride: ride,
              currentUser: currentUser,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to ride via deep link: $e');
    }
  }

  static String generateRideLink(String rideId) {
    return 'https://igitmarketplace.vercel.app/ride/$rideId';
  }

  static Future<void> shareRide(Ride ride) async {
    final screenshotController = ScreenshotController();
    
    try {
      // 1. Generate the screenshot from the widget
      final imageUint8List = await screenshotController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: RideShareCard(ride: ride, showDeepLink: false),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 100),
      );

      // 2. Save it to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/ride_share_${ride.id}.png').create();
      await file.writeAsBytes(imageUint8List);

      // 3. Prepare the text
      final rideLink = generateRideLink(ride.id);
      final text = '🚗 Need a ride? Join my trip on IGIT Marketplace!\n\n'
          '*Ride #  : ${ride.rideNumber ?? "N/A"}*\n'
          'From    : ${ride.from}\n'
          'To      : ${ride.to}\n'
          'Date    : ${DateFormat('d MMMM').format(ride.departureTime)}\n'
          'Seats   : ${ride.totalSeats - ride.seatsTaken} Available\n\n'
          '🔗 Join Ride: $rideLink\n'
          '📱 Download App: https://play.google.com/store/apps/details?id=com.market.app.market_app';

      // 4. Share the file and text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'Join My Ride #${ride.rideNumber} from ${ride.from}',
      );
    } catch (e) {
      print('Error generating or sharing ride screenshot: $e');
      // Fallback to text-only share if image generation fails
      final rideLink = generateRideLink(ride.id);
      final text = '🚗 Need a ride? Join my trip on IGIT Marketplace!\n\n'
          '*Ride #  : ${ride.rideNumber ?? "N/A"}*\n'
          'From    : ${ride.from}\n'
          'To      : ${ride.to}\n'
          '🔗 Join Ride: $rideLink\n'
          '📱 Download App: https://play.google.com/store/apps/details?id=com.market.app.market_app';
      await Share.share(text);
    }
  }
}
