//import 'package:intl/intl.dart' show DateFormat;

class DateUtil {
  static bool isSameDay(int time) {
    var today = DateTime.now();
    var date = DateTime.fromMillisecondsSinceEpoch(time);
    return today.isAtSameMomentAs(date);
  }

  static bool isNowDayThanUnlockDay(int time) {
    var date = DateTime.fromMillisecondsSinceEpoch(time);
    var today = DateTime.now();
    return today.isAfter(date);
  }

  static String format(int time) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
    //return DateFormat('yyyy-MM-dd').format(date);
    return '$time';
  }

  static String formatDate(int time, {String format = "yyyy/MM/dd  HH:mm:ss"}) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
    //return DateFormat(format).format(date);
    return '$time';
  }

  static String myFormatDateTime(DateTime date,
      {String format = "yyyy/MM/dd HH:mm:ss"}) {
    DateTime createTime =
        DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch);
    //return DateFormat(format).format(createTime);
    return '';
  }

  static String formatCustom(String newPattern, int time) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
    //return DateFormat(newPattern).format(date);
    return '$time';
  }

  static String getAge(DateTime brt) {
    int age = 0;
    DateTime dateTime = DateTime.now();
    if (brt.isAfter(dateTime)) {

      return 'Birthday is not correct';
    }
    int yearNow = dateTime.year;
    int monthNow = dateTime.month;
    int dayOfMonthNow = dateTime.day;

    int yearBirth = brt.year;
    int monthBirth = brt.month;
    int dayOfMonthBirth = brt.day;
    age = yearNow - yearBirth;
    if (monthNow <= monthBirth) {
      if (monthNow == monthBirth) {
        if (dayOfMonthNow < dayOfMonthBirth) age--;
      } else {
        age--;
      }
    }
    return age.toString();
  }

  static String getFormatTimeFromAudio(double time) {
    String totalTime;
    int total = (time / 1000).floor();
    int m = (total / 60).floor();
    int s = total - m * 60;
    if (m < 10) {
      totalTime = '0${m}:';
    } else {
      totalTime = '${m}:';
    }
    if (s < 10) {
      totalTime = totalTime + '0${s}';
    } else {
      totalTime = totalTime + '${s}';
    }
    return totalTime;
  }
}
