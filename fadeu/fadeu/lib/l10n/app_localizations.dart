import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// No description provided for @yourActivity.
  ///
  /// In en, this message translates to:
  /// **'Your Activity'**
  String get yourActivity;

  /// No description provided for @a1Level.
  ///
  /// In en, this message translates to:
  /// **'A1 Level'**
  String get a1Level;

  /// No description provided for @a2Level.
  ///
  /// In en, this message translates to:
  /// **'A2 Level'**
  String get a2Level;

  /// No description provided for @b1Level.
  ///
  /// In en, this message translates to:
  /// **'B1 Level'**
  String get b1Level;

  /// No description provided for @refreshActivityData.
  ///
  /// In en, this message translates to:
  /// **'Refresh activity data'**
  String get refreshActivityData;

  /// No description provided for @yourProgressAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Your Progress at a Glance'**
  String get yourProgressAtAGlance;

  /// No description provided for @totalStudyTime.
  ///
  /// In en, this message translates to:
  /// **'Total Study Time'**
  String get totalStudyTime;

  /// No description provided for @totalStudyTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'Total time spent watching videos and learning.'**
  String get totalStudyTimeDescription;

  /// No description provided for @wordsSearched.
  ///
  /// In en, this message translates to:
  /// **'Words Searched'**
  String get wordsSearched;

  /// No description provided for @wordsSearchedDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of unique words you have looked up.'**
  String get wordsSearchedDescription;

  /// No description provided for @wordsSaved.
  ///
  /// In en, this message translates to:
  /// **'Words Saved'**
  String get wordsSaved;

  /// No description provided for @wordsSavedDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of words you have saved for later review.'**
  String get wordsSavedDescription;

  /// No description provided for @flashcardsViewedTotal.
  ///
  /// In en, this message translates to:
  /// **'Flashcards Viewed (Total)'**
  String get flashcardsViewedTotal;

  /// No description provided for @flashcardsViewedTotalDescription.
  ///
  /// In en, this message translates to:
  /// **'Total number of flashcards you have reviewed.'**
  String get flashcardsViewedTotalDescription;

  /// No description provided for @flashcardsViewedByLevel.
  ///
  /// In en, this message translates to:
  /// **'Flashcards Viewed by Level'**
  String get flashcardsViewedByLevel;

  /// No description provided for @longestDailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest Daily Streak'**
  String get longestDailyStreak;

  /// No description provided for @longestDailyStreakDescription.
  ///
  /// In en, this message translates to:
  /// **'Your record for consecutive days of app usage.'**
  String get longestDailyStreakDescription;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used: {date}'**
  String lastUsed(String date);

  /// No description provided for @comparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get comparison;

  /// No description provided for @towardsGoal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% towards goal'**
  String towardsGoal(int percent);

  /// No description provided for @errorInitializingData.
  ///
  /// In en, this message translates to:
  /// **'Error initializing user activity data. Please restart the app.'**
  String get errorInitializingData;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @flashcards.
  ///
  /// In en, this message translates to:
  /// **'flashcards'**
  String get flashcards;

  /// No description provided for @yourMainActivities.
  ///
  /// In en, this message translates to:
  /// **'Your Main Activities'**
  String get yourMainActivities;

  /// No description provided for @searched.
  ///
  /// In en, this message translates to:
  /// **'Searched'**
  String get searched;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @viewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get viewed;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get words;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @noTranslationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No translation available.'**
  String get noTranslationAvailable;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @wordReminders.
  ///
  /// In en, this message translates to:
  /// **'Word Reminders'**
  String get wordReminders;

  /// No description provided for @wordRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'A channel for periodic word learning notifications.'**
  String get wordRemindersDescription;

  /// No description provided for @failedToLoadTranslations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load translations from server: {error}'**
  String failedToLoadTranslations(String error);

  /// No description provided for @failedToConnectToServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to your server.'**
  String get failedToConnectToServer;

  /// No description provided for @signupSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Signup successful!'**
  String get signupSuccessful;

  /// No description provided for @emailError.
  ///
  /// In en, this message translates to:
  /// **'Email error: {errors}'**
  String emailError(String errors);

  /// No description provided for @passwordError.
  ///
  /// In en, this message translates to:
  /// **'Password error: {errors}'**
  String passwordError(String errors);

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed'**
  String get signupFailed;

  /// No description provided for @couldNotConnectToServer.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not connect to server'**
  String get couldNotConnectToServer;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {reason}'**
  String loginFailed(String reason);

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent successfully!'**
  String get passwordResetEmailSent;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get failedToSendResetEmail;

  /// No description provided for @couldNotConnectToServerCheckInternet.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not connect to server. Please check your internet connection.'**
  String get couldNotConnectToServerCheckInternet;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @passwordResetSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful!'**
  String get passwordResetSuccessful;

  /// No description provided for @failedToResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get failedToResetPassword;

  /// No description provided for @fromYourDictionary.
  ///
  /// In en, this message translates to:
  /// **'From Your Dictionary'**
  String get fromYourDictionary;

  /// No description provided for @onlineResults.
  ///
  /// In en, this message translates to:
  /// **'Online Results'**
  String get onlineResults;

  /// No description provided for @word.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get word;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createAccountTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequiredError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailError;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log In'**
  String get alreadyHaveAccount;

  /// No description provided for @requiredFieldError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredFieldError;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordLengthError;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fadeu'**
  String get appTitle;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @flashcardsTab.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get flashcardsTab;

  /// No description provided for @savedTab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTab;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @noWordsFoundForLevel.
  ///
  /// In en, this message translates to:
  /// **'No words found for this level'**
  String get noWordsFoundForLevel;

  /// No description provided for @flashcardLevelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get flashcardLevelAll;

  /// No description provided for @flashcardLevelA1.
  ///
  /// In en, this message translates to:
  /// **'A1'**
  String get flashcardLevelA1;

  /// No description provided for @flashcardLevelA2.
  ///
  /// In en, this message translates to:
  /// **'A2'**
  String get flashcardLevelA2;

  /// No description provided for @flashcardLevelB1.
  ///
  /// In en, this message translates to:
  /// **'B1'**
  String get flashcardLevelB1;

  /// No description provided for @saveWordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save word to your collection'**
  String get saveWordTooltip;

  /// No description provided for @resetRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset password request'**
  String get resetRequestFailed;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link'**
  String get resetPasswordInstruction;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @weWillSendYouTheCode.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code'**
  String get weWillSendYouTheCode;

  /// No description provided for @resetEmailSentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent. Please check your inbox.'**
  String get resetEmailSentConfirmation;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet connection.'**
  String get connectionError;

  /// No description provided for @emailValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailValidationError;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @passwordValidationError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordValidationError;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordButton;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account'**
  String get setNewPasswordInstruction;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPasswordHint;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @resetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Error resetting password'**
  String get resetPasswordError;

  /// No description provided for @verifyCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCodeTitle;

  /// No description provided for @enterCodeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your email'**
  String get enterCodeInstruction;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get codeHint;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @userActivity.
  ///
  /// In en, this message translates to:
  /// **'Your Activity'**
  String get userActivity;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @forgottenPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgotten Password'**
  String get forgottenPassword;

  /// No description provided for @englishMeaning.
  ///
  /// In en, this message translates to:
  /// **'English Meaning'**
  String get englishMeaning;

  /// No description provided for @article.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get article;

  /// No description provided for @partOfSpeech.
  ///
  /// In en, this message translates to:
  /// **'Part of Speech'**
  String get partOfSpeech;

  /// No description provided for @plural.
  ///
  /// In en, this message translates to:
  /// **'Plural'**
  String get plural;

  /// No description provided for @cases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get cases;

  /// No description provided for @tenses.
  ///
  /// In en, this message translates to:
  /// **'Tenses'**
  String get tenses;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @exampleGerman.
  ///
  /// In en, this message translates to:
  /// **'Example (German)'**
  String get exampleGerman;

  /// No description provided for @exampleEnglish.
  ///
  /// In en, this message translates to:
  /// **'Example (English)'**
  String get exampleEnglish;

  /// No description provided for @examplePersian.
  ///
  /// In en, this message translates to:
  /// **'Example (Persian)'**
  String get examplePersian;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for words...'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @startTypingToSearch.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search...'**
  String get startTypingToSearch;

  /// No description provided for @noSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Your search history will appear here.'**
  String get noSearchHistory;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearRecentSearches;

  /// No description provided for @errorLoadingSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Error loading search results'**
  String get errorLoadingSearchResults;

  /// No description provided for @noTranslation.
  ///
  /// In en, this message translates to:
  /// **'No translation'**
  String get noTranslation;

  /// No description provided for @wordDetailsError.
  ///
  /// In en, this message translates to:
  /// **'Error loading word details'**
  String get wordDetailsError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @wordRemoved.
  ///
  /// In en, this message translates to:
  /// **'{word} removed from saved words'**
  String wordRemoved(Object word);

  /// No description provided for @noSavedWords.
  ///
  /// In en, this message translates to:
  /// **'No saved words found.'**
  String get noSavedWords;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enableLearningSessions.
  ///
  /// In en, this message translates to:
  /// **'Enable Learning Sessions'**
  String get enableLearningSessions;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get timeRange;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @notificationInterval.
  ///
  /// In en, this message translates to:
  /// **'Notification Interval'**
  String get notificationInterval;

  /// No description provided for @wordLevel.
  ///
  /// In en, this message translates to:
  /// **'Word Level'**
  String get wordLevel;

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get allLevels;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @disableBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Disable Battery Optimization'**
  String get disableBatteryOptimization;

  /// No description provided for @batteryOptimizationAlreadyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is already disabled for this app.'**
  String get batteryOptimizationAlreadyDisabled;

  /// No description provided for @learningSessionScheduled.
  ///
  /// In en, this message translates to:
  /// **'Learning session scheduled! You will get words every {interval}.'**
  String learningSessionScheduled(Object interval);

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled.'**
  String get notificationsDisabled;

  /// No description provided for @improveNotificationDelivery.
  ///
  /// In en, this message translates to:
  /// **'Improve Notification Delivery'**
  String get improveNotificationDelivery;

  /// No description provided for @essentialForNotifications.
  ///
  /// In en, this message translates to:
  /// **'Essential for notifications to work correctly on some devices.'**
  String get essentialForNotifications;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @levelA1.
  ///
  /// In en, this message translates to:
  /// **'Beginner (A1)'**
  String get levelA1;

  /// No description provided for @levelA2.
  ///
  /// In en, this message translates to:
  /// **'Elementary (A2)'**
  String get levelA2;

  /// No description provided for @levelB1.
  ///
  /// In en, this message translates to:
  /// **'Intermediate (B1)'**
  String get levelB1;

  /// No description provided for @clearAllConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Clear All Saved Words?'**
  String get clearAllConfirmation;

  /// No description provided for @clearAllDescription.
  ///
  /// In en, this message translates to:
  /// **'This will remove all your saved words. This action cannot be undone.'**
  String get clearAllDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @allWordsCleared.
  ///
  /// In en, this message translates to:
  /// **'All saved words cleared'**
  String get allWordsCleared;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fa': return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
