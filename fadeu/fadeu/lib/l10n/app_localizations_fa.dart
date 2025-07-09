// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get yourActivity => 'فعالیت شما';

  @override
  String get a1Level => 'سطح A1';

  @override
  String get a2Level => 'سطح A2';

  @override
  String get b1Level => 'سطح B1';

  @override
  String get refreshActivityData => 'به‌روزرسانی داده‌های فعالیت';

  @override
  String get yourProgressAtAGlance => 'پیشرفت شما در یک نگاه';

  @override
  String get totalStudyTime => 'مجموع زمان مطالعه';

  @override
  String get totalStudyTimeDescription => 'مجموع زمان صرف شده برای تماشای ویدیوها و یادگیری.';

  @override
  String get wordsSearched => 'کلمات جستجو شده';

  @override
  String get wordsSearchedDescription => 'تعداد کلمات منحصر به فردی که جستجو کرده‌اید.';

  @override
  String get wordsSaved => 'کلمات ذخیره شده';

  @override
  String get wordsSavedDescription => 'تعداد کلماتی که برای مرور بعدی ذخیره کرده‌اید.';

  @override
  String get flashcardsViewedTotal => 'فلش‌کارت‌های مشاهده شده (کل)';

  @override
  String get flashcardsViewedTotalDescription => 'مجموع تعداد فلش‌کارت‌هایی که مرور کرده‌اید.';

  @override
  String get flashcardsViewedByLevel => 'فلش‌کارت‌های مشاهده شده بر اساس سطح';

  @override
  String get longestDailyStreak => 'طولانی‌ترین روند روزانه';

  @override
  String get longestDailyStreakDescription => 'رکورد شما برای روزهای متوالی استفاده از برنامه.';

  @override
  String lastUsed(String date) {
    return 'آخرین استفاده: $date';
  }

  @override
  String get comparison => 'مقایسه';

  @override
  String towardsGoal(int percent) {
    return '$percent% تا رسیدن به هدف';
  }

  @override
  String get errorInitializingData => 'خطا در بارگذاری اولیه داده‌های فعالیت کاربر. لطفاً برنامه را مجدداً راه‌اندازی کنید.';

  @override
  String get notAvailable => 'در دسترس نیست';

  @override
  String get flashcards => 'فلش‌کارت‌ها';

  @override
  String get yourMainActivities => 'فعالیت‌های اصلی شما';

  @override
  String get searched => 'جستجو شده';

  @override
  String get saved => 'ذخیره شده';

  @override
  String get viewed => 'مشاهده شده';

  @override
  String get minutes => 'دقیقه';

  @override
  String get words => 'کلمه';

  @override
  String get days => 'روز';

  @override
  String get noTranslationAvailable => 'ترجمه‌ای موجود نیست.';

  @override
  String get refresh => 'بارگیری مجدد';

  @override
  String get wordReminders => 'یادآور کلمات';

  @override
  String get wordRemindersDescription => 'کانالی برای اعلان‌های دوره‌ای یادگیری کلمات.';

  @override
  String failedToLoadTranslations(String error) {
    return 'بارگیری ترجمه‌ها از سرور ناموفق بود: $error';
  }

  @override
  String get failedToConnectToServer => 'اتصال به سرور شما ناموفق بود.';

  @override
  String get signupSuccessful => 'ثبت‌نام با موفقیت انجام شد!';

  @override
  String emailError(String errors) {
    return 'خطای ایمیل: $errors';
  }

  @override
  String passwordError(String errors) {
    return 'خطای رمز عبور: $errors';
  }

  @override
  String get signupFailed => 'ثبت‌نام ناموفق بود';

  @override
  String get couldNotConnectToServer => 'خطا: امکان اتصال به سرور وجود ندارد';

  @override
  String get loginSuccessful => 'ورود با موفقیت انجام شد!';

  @override
  String loginFailed(String reason) {
    return 'ورود ناموفق بود: $reason';
  }

  @override
  String get passwordResetEmailSent => 'ایمیل بازنشانی رمز عبور با موفقیت ارسال شد!';

  @override
  String get failedToSendResetEmail => 'ارسال ایمیل بازنشانی ناموفق بود';

  @override
  String get couldNotConnectToServerCheckInternet => 'خطا: امکان اتصال به سرور وجود ندارد. لطفاً اتصال اینترنت خود را بررسی کنید.';

  @override
  String get verificationFailed => 'تأیید ناموفق بود';

  @override
  String get passwordResetSuccessful => 'بازنشانی رمز عبور با موفقیت انجام شد!';

  @override
  String get failedToResetPassword => 'بازنشانی رمز عبور ناموفق بود';

  @override
  String get fromYourDictionary => 'از دیکشنری شما';

  @override
  String get onlineResults => 'نتایج آنلاین';

  @override
  String get word => 'کلمه';

  @override
  String get createAccountTitle => 'حساب کاربری خود را بسازید';

  @override
  String get emailLabel => 'ایمیل';

  @override
  String get emailRequiredError => 'وارد کردن ایمیل الزامی است';

  @override
  String get invalidEmailError => 'لطفاً یک آدرس ایمیل معتبر وارد کنید';

  @override
  String get passwordLabel => 'رمز عبور';

  @override
  String get confirmPasswordLabel => 'تکرار رمز عبور';

  @override
  String get passwordsDoNotMatchError => 'رمزهای عبور یکسان نیستند';

  @override
  String get signUpButton => 'ثبت‌نام';

  @override
  String get alreadyHaveAccount => 'قبلاً حساب کاربری ساخته‌اید؟ وارد شوید';

  @override
  String get requiredFieldError => 'این فیلد الزامی است';

  @override
  String get passwordLengthError => 'رمز عبور باید حداقل ۸ کاراکتر باشد';

  @override
  String get appTitle => 'فادئو';

  @override
  String get searchTooltip => 'جستجو';

  @override
  String get flashcardsTab => 'فلش‌کارت‌ها';

  @override
  String get savedTab => 'ذخیره‌شده‌ها';

  @override
  String get settings => 'تنظیمات';

  @override
  String get settingsTab => 'تنظیمات';

  @override
  String get noWordsFoundForLevel => 'هیچ کلمه‌ای برای این سطح یافت نشد';

  @override
  String get flashcardLevelAll => 'همه سطوح';

  @override
  String get flashcardLevelA1 => 'A1';

  @override
  String get flashcardLevelA2 => 'A2';

  @override
  String get flashcardLevelB1 => 'B1';

  @override
  String get saveWordTooltip => 'ذخیره کلمه در مجموعه شما';

  @override
  String get resetRequestFailed => 'ارسال درخواست بازنشانی رمز عبور ناموفق بود';

  @override
  String get resetPasswordTitle => 'بازنشانی رمز عبور';

  @override
  String get resetPasswordInstruction => 'برای دریافت لینک بازنشانی، ایمیل خود را وارد کنید';

  @override
  String get emailHint => 'ایمیل';

  @override
  String get weWillSendYouTheCode => 'کد تأیید برای شما ارسال خواهد شد';

  @override
  String get resetEmailSentConfirmation => 'ایمیل بازنشانی ارسال شد. لطفاً صندوق ورودی خود را بررسی کنید.';

  @override
  String get unknownError => 'یک خطای ناشناخته رخ داد';

  @override
  String get connectionError => 'خطای اتصال. لطفاً اینترنت خود را بررسی کنید.';

  @override
  String get emailValidationError => 'لطفاً یک آدرس ایمیل معتبر وارد کنید';

  @override
  String get passwordHint => 'رمز عبور';

  @override
  String get passwordValidationError => 'رمز عبور باید حداقل ۶ کاراکتر باشد';

  @override
  String get loginButton => 'ورود';

  @override
  String get forgotPasswordButton => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get skipButton => 'رد شدن';

  @override
  String get setNewPasswordTitle => 'تنظیم رمز عبور جدید';

  @override
  String get setNewPasswordInstruction => 'یک رمز عبور جدید برای حساب خود ایجاد کنید';

  @override
  String get newPasswordHint => 'رمز عبور جدید';

  @override
  String get confirmPasswordHint => 'تکرار رمز عبور جدید';

  @override
  String get resetPasswordButton => 'بازنشانی رمز عبور';

  @override
  String get resetPasswordError => 'خطا در بازنشانی رمز عبور';

  @override
  String get verifyCodeTitle => 'تأیید کد';

  @override
  String get enterCodeInstruction => 'کد تأیید ارسال شده به ایمیل خود را وارد کنید';

  @override
  String get codeHint => 'کد تأیید';

  @override
  String get verifyButton => 'تأیید';

  @override
  String get language => 'زبان';

  @override
  String get theme => 'پوسته';

  @override
  String get userActivity => 'فعالیت شما';

  @override
  String get notifications => 'اعلان‌ها';

  @override
  String get signUp => 'ثبت‌نام';

  @override
  String get login => 'ورود';

  @override
  String get forgottenPassword => 'فراموشی رمز عبور';

  @override
  String get englishMeaning => 'معنی انگلیسی';

  @override
  String get article => 'حرف تعریف (آرتیکل)';

  @override
  String get partOfSpeech => 'نوع کلمه (نقش دستوری)';

  @override
  String get plural => 'جمع';

  @override
  String get cases => 'حالت‌ها (گرامری)';

  @override
  String get tenses => 'زمان‌ها (فعل)';

  @override
  String get level => 'سطح';

  @override
  String get exampleGerman => 'مثال (آلمانی)';

  @override
  String get exampleEnglish => 'مثال (انگلیسی)';

  @override
  String get examplePersian => 'مثال (فارسی)';

  @override
  String get searchHint => 'جستجوی کلمات...';

  @override
  String get noResults => 'نتیجه‌ای یافت نشد';

  @override
  String get startTypingToSearch => 'برای جستجو تایپ کنید...';

  @override
  String get noSearchHistory => 'تاریخچه جستجوی شما اینجا نمایش داده می‌شود.';

  @override
  String get recentSearches => 'جستجوهای اخیر';

  @override
  String get clearRecentSearches => 'حذف همه';

  @override
  String get errorLoadingSearchResults => 'خطا در بارگیری نتایج جستجو';

  @override
  String get noTranslation => 'بدون ترجمه';

  @override
  String get wordDetailsError => 'خطا در بارگذاری جزئیات کلمه';

  @override
  String get tryAgain => 'دوباره تلاش کنید';

  @override
  String wordRemoved(Object word) {
    return '$word از کلمات ذخیره شده حذف شد';
  }

  @override
  String get noSavedWords => 'هیچ کلمه ذخیره شده‌ای یافت نشد.';

  @override
  String get pullToRefresh => 'برای به‌روزرسانی به پایین بکشید';

  @override
  String get clearAll => 'پاک کردن همه';

  @override
  String get notificationSettings => 'تنظیمات اعلان‌ها';

  @override
  String get enableLearningSessions => 'فعال‌سازی جلسات یادگیری';

  @override
  String get timeRange => 'Time Range';

  @override
  String get to => 'to';

  @override
  String get notificationInterval => 'Notification Interval';

  @override
  String get wordLevel => 'سطح کلمه';

  @override
  String get allLevels => 'همه سطوح';

  @override
  String get saveSettings => 'ذخیره تنظیمات';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get disableBatteryOptimization => 'Disable Battery Optimization';

  @override
  String get batteryOptimizationAlreadyDisabled => 'Battery optimization is already disabled for this app.';

  @override
  String learningSessionScheduled(Object interval) {
    return 'Learning session scheduled! You will get words every $interval.';
  }

  @override
  String get notificationsDisabled => 'اعلان‌ها غیرفعال شد.';

  @override
  String get improveNotificationDelivery => 'بهبود تحویل اعلان‌ها';

  @override
  String get essentialForNotifications => 'برای عملکرد صحیح اعلان‌ها در برخی دستگاه‌ها ضروری است.';

  @override
  String get hour => '۱ ساعت';

  @override
  String get hours => 'ساعت';

  @override
  String get minute => 'دقیقه';

  @override
  String get startTime => 'زمان شروع';

  @override
  String get endTime => 'زمان پایان';

  @override
  String get frequency => 'تکرار';

  @override
  String get levelA1 => 'مبتدی (A1)';

  @override
  String get levelA2 => 'مقدماتی (A2)';

  @override
  String get levelB1 => 'متوسط (B1)';

  @override
  String get clearAllConfirmation => 'حذف همه کلمات ذخیره شده؟';

  @override
  String get clearAllDescription => 'این کار تمام کلمات ذخیره شده شما را حذف می‌کند. این عمل قابل بازگشت نیست.';

  @override
  String get cancel => 'انصراف';

  @override
  String get allWordsCleared => 'همه کلمات ذخیره شده حذف شدند';
}
