// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get yourActivity => 'Your Activity';

  @override
  String get a1Level => 'A1 Level';

  @override
  String get a2Level => 'A2 Level';

  @override
  String get b1Level => 'B1 Level';

  @override
  String get refreshActivityData => 'Refresh activity data';

  @override
  String get yourProgressAtAGlance => 'Your Progress at a Glance';

  @override
  String get totalStudyTime => 'Total Study Time';

  @override
  String get totalStudyTimeDescription => 'Total time spent watching videos and learning.';

  @override
  String get wordsSearched => 'Words Searched';

  @override
  String get wordsSearchedDescription => 'Number of unique words you have looked up.';

  @override
  String get wordsSaved => 'Words Saved';

  @override
  String get wordsSavedDescription => 'Number of words you have saved for later review.';

  @override
  String get flashcardsViewedTotal => 'Flashcards Viewed (Total)';

  @override
  String get flashcardsViewedTotalDescription => 'Total number of flashcards you have reviewed.';

  @override
  String get flashcardsViewedByLevel => 'Flashcards Viewed by Level';

  @override
  String get longestDailyStreak => 'Longest Daily Streak';

  @override
  String get longestDailyStreakDescription => 'Your record for consecutive days of app usage.';

  @override
  String lastUsed(String date) {
    return 'Last used: $date';
  }

  @override
  String get comparison => 'Comparison';

  @override
  String towardsGoal(int percent) {
    return '$percent% towards goal';
  }

  @override
  String get errorInitializingData => 'Error initializing user activity data. Please restart the app.';

  @override
  String get notAvailable => 'N/A';

  @override
  String get flashcards => 'flashcards';

  @override
  String get yourMainActivities => 'Your Main Activities';

  @override
  String get searched => 'Searched';

  @override
  String get saved => 'Saved';

  @override
  String get viewed => 'Viewed';

  @override
  String get minutes => 'minutes';

  @override
  String get words => 'words';

  @override
  String get days => 'days';

  @override
  String get noTranslationAvailable => 'No translation available.';

  @override
  String get refresh => 'Refresh';

  @override
  String get wordReminders => 'Word Reminders';

  @override
  String get wordRemindersDescription => 'A channel for periodic word learning notifications.';

  @override
  String failedToLoadTranslations(String error) {
    return 'Failed to load translations from server: $error';
  }

  @override
  String get failedToConnectToServer => 'Failed to connect to your server.';

  @override
  String get signupSuccessful => 'Signup successful!';

  @override
  String emailError(String errors) {
    return 'Email error: $errors';
  }

  @override
  String passwordError(String errors) {
    return 'Password error: $errors';
  }

  @override
  String get signupFailed => 'Signup failed';

  @override
  String get couldNotConnectToServer => 'Error: Could not connect to server';

  @override
  String get loginSuccessful => 'Login successful!';

  @override
  String loginFailed(String reason) {
    return 'Login failed: $reason';
  }

  @override
  String get passwordResetEmailSent => 'Password reset email sent successfully!';

  @override
  String get failedToSendResetEmail => 'Failed to send reset email';

  @override
  String get couldNotConnectToServerCheckInternet => 'Error: Could not connect to server. Please check your internet connection.';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get passwordResetSuccessful => 'Password reset successful!';

  @override
  String get failedToResetPassword => 'Failed to reset password';

  @override
  String get fromYourDictionary => 'From Your Dictionary';

  @override
  String get onlineResults => 'Online Results';

  @override
  String get word => 'Word';

  @override
  String get createAccountTitle => 'Create Your Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequiredError => 'Email is required';

  @override
  String get invalidEmailError => 'Please enter a valid email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log In';

  @override
  String get requiredFieldError => 'This field is required';

  @override
  String get passwordLengthError => 'Password must be at least 8 characters long';

  @override
  String get appTitle => 'Fadeu';

  @override
  String get searchTooltip => 'Search';

  @override
  String get flashcardsTab => 'Flashcards';

  @override
  String get savedTab => 'Saved';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTab => 'Settings';

  @override
  String get noWordsFoundForLevel => 'No words found for this level';

  @override
  String get flashcardLevelAll => 'All';

  @override
  String get flashcardLevelA1 => 'A1';

  @override
  String get flashcardLevelA2 => 'A2';

  @override
  String get flashcardLevelB1 => 'B1';

  @override
  String get saveWordTooltip => 'Save word to your collection';

  @override
  String get resetRequestFailed => 'Failed to send reset password request';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordInstruction => 'Enter your email to receive a password reset link';

  @override
  String get emailHint => 'Email';

  @override
  String get weWillSendYouTheCode => 'We\'ll send you a verification code';

  @override
  String get resetEmailSentConfirmation => 'Reset email sent. Please check your inbox.';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get connectionError => 'Connection error. Please check your internet connection.';

  @override
  String get emailValidationError => 'Please enter a valid email address';

  @override
  String get passwordHint => 'Password';

  @override
  String get passwordValidationError => 'Password must be at least 6 characters';

  @override
  String get loginButton => 'Log In';

  @override
  String get forgotPasswordButton => 'Forgot Password?';

  @override
  String get skipButton => 'Skip';

  @override
  String get setNewPasswordTitle => 'Set New Password';

  @override
  String get setNewPasswordInstruction => 'Create a new password for your account';

  @override
  String get newPasswordHint => 'New Password';

  @override
  String get confirmPasswordHint => 'Confirm New Password';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get resetPasswordError => 'Error resetting password';

  @override
  String get verifyCodeTitle => 'Verify Code';

  @override
  String get enterCodeInstruction => 'Enter the verification code sent to your email';

  @override
  String get codeHint => 'Verification Code';

  @override
  String get verifyButton => 'Verify';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get userActivity => 'Your Activity';

  @override
  String get notifications => 'Notifications';

  @override
  String get signUp => 'Sign Up';

  @override
  String get login => 'Login';

  @override
  String get forgottenPassword => 'Forgotten Password';

  @override
  String get englishMeaning => 'English Meaning';

  @override
  String get article => 'Article';

  @override
  String get partOfSpeech => 'Part of Speech';

  @override
  String get plural => 'Plural';

  @override
  String get cases => 'Cases';

  @override
  String get tenses => 'Tenses';

  @override
  String get level => 'Level';

  @override
  String get exampleGerman => 'Example (German)';

  @override
  String get exampleEnglish => 'Example (English)';

  @override
  String get examplePersian => 'Example (Persian)';

  @override
  String get searchHint => 'Search for words...';

  @override
  String get noResults => 'No results found';

  @override
  String get startTypingToSearch => 'Start typing to search...';

  @override
  String get noSearchHistory => 'Your search history will appear here.';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearRecentSearches => 'Clear All';

  @override
  String get errorLoadingSearchResults => 'Error loading search results';

  @override
  String get noTranslation => 'No translation';

  @override
  String get wordDetailsError => 'Error loading word details';

  @override
  String get tryAgain => 'Try Again';

  @override
  String wordRemoved(Object word) {
    return '$word removed from saved words';
  }

  @override
  String get noSavedWords => 'No saved words found.';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get clearAll => 'Clear All';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enableLearningSessions => 'Enable Learning Sessions';

  @override
  String get timeRange => 'Time Range';

  @override
  String get to => 'to';

  @override
  String get notificationInterval => 'Notification Interval';

  @override
  String get wordLevel => 'Word Level';

  @override
  String get allLevels => 'All Levels';

  @override
  String get saveSettings => 'Save Settings';

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
  String get notificationsDisabled => 'Notifications disabled.';

  @override
  String get improveNotificationDelivery => 'Improve Notification Delivery';

  @override
  String get essentialForNotifications => 'Essential for notifications to work correctly on some devices.';

  @override
  String get hour => '1 hour';

  @override
  String get hours => 'hours';

  @override
  String get minute => 'minute';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get frequency => 'Frequency';

  @override
  String get levelA1 => 'Beginner (A1)';

  @override
  String get levelA2 => 'Elementary (A2)';

  @override
  String get levelB1 => 'Intermediate (B1)';

  @override
  String get clearAllConfirmation => 'Clear All Saved Words?';

  @override
  String get clearAllDescription => 'This will remove all your saved words. This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get allWordsCleared => 'All saved words cleared';
}
