import 'package:get/get.dart';

class UserController extends GetxController {
  var userId = ''.obs;
  var phone = ''.obs;
  var fullName = ''.obs;
  var balance = ''.obs; 
  var hasPin = false.obs;


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

  void clearData() {
    phone.value = '';
    fullName.value = '';
    balance.value = '';
    hasPin.value = false;
  }
}