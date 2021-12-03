import 'dart:ui';

class Config {
  static const String tab_home = 'HOME';
  static const String tab_file = 'FILE';
  static const String tab_mine = 'MINE';

  static const String KEY_SWITCH_BANNER = 'KEY_SWITCH_BANNER';
  static const String KEY_NICK_NAME = 'KEY_NICK_NAME';
  static const String KEY_MOBILE = 'KEY_MOBILE';
  static const String KEY_USER_ID = 'KEY_USER_ID';
  static const String KEY_USER_PW = 'KEY_USER_PW';

  static final int EVENT_BUS_CODE_BANNER = 0x1; //home page banner
  static final int EVENT_BUS_FILE_REFRESH = 0x2; //refresh
  static final int EVENT_BUS_SET_INDEX = 0x3; //switch

  static const int WECHAT = 0; //wechat
  static const int WECHAT_PYQ = 1; //wechat moments
}

class ColorConfig {
  static const Color tab_color_normal = Color(0xffBFBFBF);
  static const Color white_alpha_66 = Color(0x66FFFFFF);
  static const Color blue = Color(0xff0077DA);
  static const Color indicator_unselected = Color(0xffffffff);
  static const Color indicator_selected = Color(0x55ffffff);

  static const Color main_txt_color = Color(0xff333333);
  static const Color sub_txt_color = Color(0xff65696D);
  static const Color sub_sub_txt_color = Color(0xff8D94A1);
  static const Color sub_asub_txt_color = Color(0x7f8D94A1);
  static const Color red_txt_color = Color(0xffFC453A);
  static const Color txt_color_back = Color(0xffCCCCCC);
  static const Color line_color = Color(0x80F1EEEE);


  static const Color common_line = Color(0x7fB1B3BF);

  static const Color toast_back = Color(0xCC000000);
  static const Color collection_back = Color(0xFF4C4C4C);
  static const Color text_dark_gray = Color(0xff666666);
}
