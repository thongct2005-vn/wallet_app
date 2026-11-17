import 'package:flutter/material.dart';

/// Hoãn thực thi [callback] cho tới khi hiệu ứng chuyển màn hình của route
/// hoàn tất để không làm khựng animation bởi platform channel/API/setState.
VoidCallback runAfterRouteTransition(
  BuildContext context,
  VoidCallback callback,
) {
  final route = ModalRoute.of(context);
  final animation = route?.animation;
  if (animation == null || (animation.isCompleted && !route!.offstage)) {
    var cancelled = false;
    Future.microtask(() {
      if (!cancelled) callback();
    });
    return () => cancelled = true;
  }

  var cancelled = false;
  var triggered = false;
  VoidCallback? detachListener;

  void attachWhenOnstage() {
    if (cancelled || triggered) return;
    final anim = route!.animation;
    if (anim == null || (anim.isCompleted && !route.offstage)) {
      triggered = true;
      callback();
      return;
    }

    late final void Function(AnimationStatus) listener;
    listener = (status) {
      if (!cancelled &&
          !triggered &&
          status == AnimationStatus.completed &&
          !route.offstage) {
        triggered = true;
        anim.removeStatusListener(listener);
        callback();
      }
    };
    anim.addStatusListener(listener);
    detachListener = () => anim.removeStatusListener(listener);
  }

  if (route!.offstage) {
    // HeroController tạm set offstage=true ở frame đầu (làm animation proxy=1.0 giả),
    // đợi post-frame khi offstage được trả về false rồi mới theo dõi transition thật.
    WidgetsBinding.instance.addPostFrameCallback((_) => attachWhenOnstage());
  } else {
    attachWhenOnstage();
  }

  return () {
    cancelled = true;
    detachListener?.call();
  };
}

