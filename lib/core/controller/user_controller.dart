import 'package:get/get.dart';

class UserController extends GetxController {
  var userId = ''.obs;
  var phone = ''.obs;
  var fullName = ''.obs;
  var balance = ''.obs;
  var hasPin = false.obs;
  final RxInt postpaidRefreshTick = 0.obs;
  final RxnInt postpaidUsedAmount = RxnInt();
  final RxnInt postpaidAvailableLimit = RxnInt();
  final RxnString postpaidStatus = RxnString();
  final RxnString postpaidLastEventType = RxnString();

  static int? _tryInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.round();
    return int.tryParse(val?.toString() ?? '');
  }

  void notifyPostpaidUpdated(Map<String, dynamic> data) {
    final nextUsed = _tryInt(data['usedAmount']);
    final nextAvail = _tryInt(data['availableLimit']);
    final nextStatus = data['status']?.toString();
    final eventType = data['type']?.toString();
    if (nextUsed != null) postpaidUsedAmount.value = nextUsed;
    if (nextAvail != null) postpaidAvailableLimit.value = nextAvail;
    if (nextStatus != null && nextStatus.isNotEmpty) {
      postpaidStatus.value = nextStatus;
    }
    if (eventType != null && eventType.isNotEmpty) {
      postpaidLastEventType.value = eventType;
    }
    postpaidRefreshTick.value++;
  }

  void setUserData({
    required String newId,
    required String newPhone,
    required String newFullName,
    required String newBalance,
    required bool newHasPin,
  }) {
    userId.value = newId;
    phone.value = newPhone;
    fullName.value = newFullName;
    balance.value = newBalance;
    hasPin.value = newHasPin;
  }

  void setUserFullName({required String newFullName}) {
    fullName.value = newFullName;
  }

  void clearData() {
    userId.value = '';
    phone.value = '';
    fullName.value = '';
    balance.value = '';
    hasPin.value = false;
    postpaidRefreshTick.value = 0;
    postpaidUsedAmount.value = null;
    postpaidAvailableLimit.value = null;
    postpaidStatus.value = null;
    postpaidLastEventType.value = null;
  }
}
