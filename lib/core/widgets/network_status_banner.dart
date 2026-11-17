import 'dart:math' as math;

import 'package:app/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NetworkStatusOverlay extends StatefulWidget {
  final Widget child;
  final ConnectivityService? service;

  const NetworkStatusOverlay({
    super.key,
    required this.child,
    this.service,
  });

  @override
  State<NetworkStatusOverlay> createState() => _NetworkStatusOverlayState();
}

class _NetworkStatusOverlayState extends State<NetworkStatusOverlay>
    with WidgetsBindingObserver {
  ConnectivityService get _service =>
      widget.service ?? ConnectivityService.instance;

  NetworkBannerStatus _renderedStatus = NetworkBannerStatus.offline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = math.max(
      mediaQuery.viewPadding.bottom,
      mediaQuery.viewInsets.bottom,
    );

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        ValueListenableBuilder<NetworkBannerStatus>(
          valueListenable: _service.bannerStatus,
          builder: (context, status, _) {
            final isVisible = status != NetworkBannerStatus.hidden;
            if (isVisible) {
              _renderedStatus = status;
            }
            final displayStatus = isVisible ? status : _renderedStatus;
            final isOffline = displayStatus == NetworkBannerStatus.offline;

            return Positioned(
              left: 14,
              right: 14,
              bottom: bottomInset + 14,
              child: IgnorePointer(
                ignoring: !isVisible,
                child: ExcludeSemantics(
                  excluding: !isVisible,
                  child: AnimatedSlide(
                    offset: isVisible ? Offset.zero : const Offset(0, 1.35),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: _NetworkStatusCard(
                        isOffline: isOffline,
                        onOpenSettings: _service.openNetworkSettings,
                        onDismiss: _service.dismissBanner,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NetworkStatusCard extends StatelessWidget {
  final bool isOffline;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  const _NetworkStatusCard({
    required this.isOffline,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  static const Color _offlineRed = Color(0xFFFF4D4F);
  static const Color _restoredGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final accentColor = isOffline ? _offlineRed : _restoredGreen;
    final actionColor =
        isOffline ? const Color(0xFFFF80AB) : const Color(0xFF4ADE80);

    return Material(
      color: const Color(0xFF1F242D),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: accentColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOffline
                    ? 'Mất kết nối internet'
                    : 'Đã có kết nối internet',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '|',
                style: GoogleFonts.roboto(
                  color: Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ),
            InkWell(
              onTap: isOffline ? onOpenSettings : onDismiss,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  isOffline ? 'Cài đặt' : 'Đóng',
                  style: GoogleFonts.roboto(
                    color: actionColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
