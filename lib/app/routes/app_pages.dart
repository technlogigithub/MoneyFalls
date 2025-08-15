import 'package:get/get.dart';

import '../modules/bottom_bar/bindings/bottom_bar_binding.dart';
import '../modules/bottom_bar/views/bottom_bar_view.dart';
import '../modules/change_password/bindings/ChangePasswordBinding.dart';
import '../modules/change_password/views/ChangePasswordScreenView.dart';
import '../modules/chat_screen/bindings/chat_screen_binding.dart';
import '../modules/chat_screen/views/chat_screen_view.dart';
import '../modules/edit_profile/bindings/profile_binding.dart';
import '../modules/edit_profile/views/profile_view.dart';
import '../modules/favourite/bindings/favourite_binding.dart';
import '../modules/favourite/views/favourite_view.dart';
import '../modules/forget_password/bindings/forget_password_binding.dart';
import '../modules/forget_password/views/forget_password_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_signup_binding.dart';
import '../modules/login/views/login_signup_view.dart';
import '../modules/other_person_profile/bindings/other_person_profile_binding.dart';
import '../modules/other_person_profile/views/other_person_profile_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/referal_level/bindings/referal_level_binding.dart';
import '../modules/referal_level/views/referal_level_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/wallet/bindings/wallet_binding.dart';
import '../modules/wallet/views/wallet_view.dart';
import '../modules/winners/bindings/winners_binding.dart';
import '../modules/winners/views/winners_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN_SIGNUP,
      page: () => LoginSignupView(),
      binding: LoginSignupBinding(),
    ),
    GetPage(
      name: _Paths.FORGET_PASSWORD,
      page: () => const ForgetPasswordView(),
      binding: ForgetPasswordBinding(),
    ),
    // GetPage(
    //   name: _Paths.OTP_SCREEN,
    //   page: () => const OtpScreenView(),
    //   binding: OtpScreenBinding(),
    // ),
    GetPage(
      name: _Paths.CHANGE_PASSWORD_SCREEN,
      page: () => ChangePasswordScreenView(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: _Paths.BOTTOM_BAR,
      page: () => const BottomBarView(),
      binding: BottomBarBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: _Paths.WALLET,
      page: () => WalletView(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: _Paths.FAVOURITE,
      page: () => FavouriteView(),
      binding: FavouriteBinding(),
    ),
    GetPage(
      name: _Paths.EDITPROFILE,
      page: () => EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_SCREEN,
      page: () => const ChatScreenView(),
      binding: ChatScreenBinding(),
    ),
    GetPage(
      name: _Paths.WINNERS,
      page: () => const WinnersView(),
      binding: WinnersBinding(),
    ),
    GetPage(
      name: _Paths.REFERAL_LEVEL,
      page: () => const ReferalLevelView(),
      binding: ReferalLevelBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.OTHER_PERSON_PROFILE,
      page: () => OtherPersonProfile(),
      binding: OtherPersonProfileBinding(),
    ),
  ];
}
