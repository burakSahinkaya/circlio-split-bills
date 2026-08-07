import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ru'),
    Locale('tr'),
  ];

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful!'**
  String get purchaseSuccessful;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username is available!'**
  String get usernameAvailable;

  /// No description provided for @leftGroups.
  ///
  /// In en, this message translates to:
  /// **'Left Groups'**
  String get leftGroups;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'settled'**
  String get settled;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No Groups Yet'**
  String get noGroupsYet;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @whatLikeToAdd.
  ///
  /// In en, this message translates to:
  /// **'What would you like to add?'**
  String get whatLikeToAdd;

  /// No description provided for @loadingGroupInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading group info...'**
  String get loadingGroupInfo;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @choosePhotoUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo and a unique username'**
  String get choosePhotoUsername;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmount;

  /// No description provided for @expensesPaymentsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Expenses and payments will appear here'**
  String get expensesPaymentsAppearHere;

  /// No description provided for @splitCircle.
  ///
  /// In en, this message translates to:
  /// **'SplitCircle'**
  String get splitCircle;

  /// No description provided for @searchUsersToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search for users to add to this group'**
  String get searchUsersToAdd;

  /// No description provided for @backToGroups.
  ///
  /// In en, this message translates to:
  /// **'Back to Groups'**
  String get backToGroups;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @fullAmount.
  ///
  /// In en, this message translates to:
  /// **'Full Amount'**
  String get fullAmount;

  /// No description provided for @inviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get inviteMembers;

  /// No description provided for @pendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending invites'**
  String get pendingInvites;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroup;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @pendingInvitesCapitalized.
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get pendingInvitesCapitalized;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️'**
  String get madeWithLove;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// No description provided for @createFirstGroup.
  ///
  /// In en, this message translates to:
  /// **'Create your first group to start splitting expenses with friends.'**
  String get createFirstGroup;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @joinWithInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Join with Invite Code'**
  String get joinWithInviteCode;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @addFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to get started'**
  String get addFirstExpense;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @addPurchaseAsExpense.
  ///
  /// In en, this message translates to:
  /// **'Add this purchase as a group expense easily to divide the cost.'**
  String get addPurchaseAsExpense;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get deleteExpenseConfirm;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmed;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @noActivitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get noActivitiesYet;

  /// No description provided for @groupDeletedList.
  ///
  /// In en, this message translates to:
  /// **'Group deleted from your list'**
  String get groupDeletedList;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get members;

  /// No description provided for @shareInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Share Invite Link'**
  String get shareInviteLink;

  /// No description provided for @invalidInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid Invite Link'**
  String get invalidInviteLink;

  /// No description provided for @chooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get chooseFromLibrary;

  /// No description provided for @splitExpensesTagline.
  ///
  /// In en, this message translates to:
  /// **'Split expenses with friends,\neffortlessly.'**
  String get splitExpensesTagline;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete your account while you have unsettled balances in your groups. Please settle your debts or collect your loans first.'**
  String get deleteAccountWarning;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @addGroupExpense.
  ///
  /// In en, this message translates to:
  /// **'Add as Group Expense'**
  String get addGroupExpense;

  /// No description provided for @loadingGroups.
  ///
  /// In en, this message translates to:
  /// **'Loading groups...'**
  String get loadingGroups;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group Created! 🎉'**
  String get groupCreated;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @individualBalances.
  ///
  /// In en, this message translates to:
  /// **'Individual Balances'**
  String get individualBalances;

  /// No description provided for @joinCreateGroupActivity.
  ///
  /// In en, this message translates to:
  /// **'Join or create a group to see activity'**
  String get joinCreateGroupActivity;

  /// No description provided for @expenseSplittingSimple.
  ///
  /// In en, this message translates to:
  /// **'Expense splitting made simple'**
  String get expenseSplittingSimple;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @someonePaidBack.
  ///
  /// In en, this message translates to:
  /// **'Someone paid someone back'**
  String get someonePaidBack;

  /// No description provided for @termsAgree.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our\nTerms of Service and Privacy Policy'**
  String get termsAgree;

  /// No description provided for @noPackagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No packages currently available. Please check back later.'**
  String get noPackagesAvailable;

  /// No description provided for @deleteGroupPermanent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this group from your list?'**
  String get deleteGroupPermanent;

  /// No description provided for @setUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Profile'**
  String get setUpProfile;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @outOfExpenseRights.
  ///
  /// In en, this message translates to:
  /// **'Out of Expense Rights'**
  String get outOfExpenseRights;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurity;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @deleteAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'For security reasons, please log out and log back in before deleting your account.'**
  String get deleteAccountSecurity;

  /// No description provided for @suggestedSettlements.
  ///
  /// In en, this message translates to:
  /// **'Suggested Settlements'**
  String get suggestedSettlements;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelled;

  /// No description provided for @pasteInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite code you received to join a group.'**
  String get pasteInviteCode;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @chooseGroupPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Group Photo'**
  String get chooseGroupPhoto;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No Activity Yet'**
  String get noActivityYet;

  /// No description provided for @leaveGroupWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group? You will lose access to all expenses and balances.'**
  String get leaveGroupWarning;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @shareInviteLinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Share an invite link so others can join instantly.'**
  String get shareInviteLinkDesc;

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get yourBalance;

  /// No description provided for @youLeftGroup.
  ///
  /// In en, this message translates to:
  /// **'You have left the group'**
  String get youLeftGroup;

  /// No description provided for @errorLoadingGroups.
  ///
  /// In en, this message translates to:
  /// **'Error loading groups'**
  String get errorLoadingGroups;

  /// No description provided for @groupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group not found'**
  String get groupNotFound;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get noThanks;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? '**
  String get deleteAccountConfirm;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get appleSignInFailed;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @outstandingBalances.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balances'**
  String get outstandingBalances;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @keepSplittingByBuyingRights.
  ///
  /// In en, this message translates to:
  /// **'Keep splitting expenses easily by buying more rights for the group.'**
  String get keepSplittingByBuyingRights;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @invitedYouToJoin.
  ///
  /// In en, this message translates to:
  /// **'Invited you to join'**
  String get invitedYouToJoin;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @splitCostMembers.
  ///
  /// In en, this message translates to:
  /// **'Split a cost between members'**
  String get splitCostMembers;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Create Groups'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Organize expenses with friends,\nfamily, or housemates'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Split Expenses'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Add expenses and split them\nequally or by custom amounts'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Settle Up'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'See who owes whom and settle\ndebts with minimal transactions'**
  String get onboardingSubtitle3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About SplitCircle'**
  String get aboutApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @activeGroup.
  ///
  /// In en, this message translates to:
  /// **'active group'**
  String get activeGroup;

  /// No description provided for @activeGroups.
  ///
  /// In en, this message translates to:
  /// **'active groups'**
  String get activeGroups;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get member;

  /// No description provided for @leftGroupText.
  ///
  /// In en, this message translates to:
  /// **'Left group'**
  String get leftGroupText;

  /// No description provided for @trip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get trip;

  /// No description provided for @house.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get house;

  /// No description provided for @couple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get couple;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @searchByUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by username...'**
  String get searchByUsername;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Bali Trip 2026'**
  String get nameHint;

  /// No description provided for @expenseRightsLeft.
  ///
  /// In en, this message translates to:
  /// **'expense rights left'**
  String get expenseRightsLeft;

  /// No description provided for @activitiesTab.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesTab;

  /// No description provided for @balancesTab.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balancesTab;

  /// No description provided for @membersTab.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTab;

  /// No description provided for @joinedViaInviteLink.
  ///
  /// In en, this message translates to:
  /// **'joined the group via invite link'**
  String get joinedViaInviteLink;

  /// No description provided for @whatWouldYouLikeToAdd.
  ///
  /// In en, this message translates to:
  /// **'What would you like to add?'**
  String get whatWouldYouLikeToAdd;

  /// No description provided for @addExpenseCapitalized.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpenseCapitalized;

  /// No description provided for @someonePaidSomeoneBack.
  ///
  /// In en, this message translates to:
  /// **'Someone paid someone back'**
  String get someonePaidSomeoneBack;

  /// No description provided for @todayCapitalized.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayCapitalized;

  /// No description provided for @yesterdayCapitalized.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayCapitalized;

  /// No description provided for @paidWord.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get paidWord;

  /// No description provided for @splitPrefix.
  ///
  /// In en, this message translates to:
  /// **'split '**
  String get splitPrefix;

  /// No description provided for @splitSuffix.
  ///
  /// In en, this message translates to:
  /// **' ways'**
  String get splitSuffix;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @getsBack.
  ///
  /// In en, this message translates to:
  /// **'gets back'**
  String get getsBack;

  /// No description provided for @allSettledUp.
  ///
  /// In en, this message translates to:
  /// **'all settled up'**
  String get allSettledUp;

  /// No description provided for @owesWord.
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get owesWord;

  /// No description provided for @paysWord.
  ///
  /// In en, this message translates to:
  /// **'pays'**
  String get paysWord;

  /// No description provided for @getsBackMoney.
  ///
  /// In en, this message translates to:
  /// **'gets back money'**
  String get getsBackMoney;

  /// No description provided for @owesMoney.
  ///
  /// In en, this message translates to:
  /// **'owes money'**
  String get owesMoney;

  /// No description provided for @allSettledUpState.
  ///
  /// In en, this message translates to:
  /// **'all settled up'**
  String get allSettledUpState;

  /// No description provided for @youAreOwed.
  ///
  /// In en, this message translates to:
  /// **'You are owed '**
  String get youAreOwed;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe '**
  String get youOwe;

  /// No description provided for @generatingLink.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generatingLink;

  /// No description provided for @inviteLinkBtn.
  ///
  /// In en, this message translates to:
  /// **'Invite Link'**
  String get inviteLinkBtn;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **' (You)'**
  String get youSuffix;

  /// No description provided for @thatsOnlyPrefix.
  ///
  /// In en, this message translates to:
  /// **'That\'s only '**
  String get thatsOnlyPrefix;

  /// No description provided for @perPersonSuffix.
  ///
  /// In en, this message translates to:
  /// **' per person!'**
  String get perPersonSuffix;

  /// No description provided for @iapSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful!'**
  String get iapSuccessTitle;

  /// No description provided for @iapSuccessBody1.
  ///
  /// In en, this message translates to:
  /// **'You have successfully added '**
  String get iapSuccessBody1;

  /// No description provided for @iapSuccessBody2.
  ///
  /// In en, this message translates to:
  /// **' expense rights to the group.\n\nWould you like to add this '**
  String get iapSuccessBody2;

  /// No description provided for @iapSuccessBody3.
  ///
  /// In en, this message translates to:
  /// **' purchase as a shared group expense? (Adding this will NOT use any of your new expense rights).'**
  String get iapSuccessBody3;

  /// No description provided for @expenseRightsCapitalized.
  ///
  /// In en, this message translates to:
  /// **'Expense Rights'**
  String get expenseRightsCapitalized;

  /// No description provided for @selectGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroupTitle;

  /// No description provided for @joinOrCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Join or create a group to see activity'**
  String get joinOrCreateGroup;

  /// No description provided for @activityWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Expenses and payments will appear here'**
  String get activityWillAppearHere;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @whatWasItFor.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get whatWasItFor;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @paidByLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidByLabel;

  /// No description provided for @splitBetweenLabel.
  ///
  /// In en, this message translates to:
  /// **'Split between'**
  String get splitBetweenLabel;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmountLabel;

  /// No description provided for @whoPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get whoPaidLabel;

  /// No description provided for @paidToLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid to'**
  String get paidToLabel;

  /// No description provided for @fullAmountBtn.
  ///
  /// In en, this message translates to:
  /// **'Full Amount'**
  String get fullAmountBtn;

  /// No description provided for @youOnly.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youOnly;

  /// No description provided for @foodCategory.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get foodCategory;

  /// No description provided for @travelCategory.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelCategory;

  /// No description provided for @stayCategory.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stayCategory;

  /// No description provided for @transportCategory.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transportCategory;

  /// No description provided for @rentCategory.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rentCategory;

  /// No description provided for @groceriesCategory.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceriesCategory;

  /// No description provided for @funCategory.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get funCategory;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @owesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Owes: '**
  String get owesPrefix;

  /// No description provided for @addGuestMember.
  ///
  /// In en, this message translates to:
  /// **'Add Guest Member'**
  String get addGuestMember;

  /// No description provided for @guestBadge.
  ///
  /// In en, this message translates to:
  /// **'GUEST'**
  String get guestBadge;

  /// No description provided for @guestMemberName.
  ///
  /// In en, this message translates to:
  /// **'Guest Name'**
  String get guestMemberName;

  /// No description provided for @guestMemberNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Alice (friend)'**
  String get guestMemberNameHint;

  /// No description provided for @guestMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No app needed — they\'ll appear as a group member.'**
  String get guestMemberSubtitle;

  /// No description provided for @guestMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added as a guest member'**
  String guestMemberAdded(String name);

  /// No description provided for @removeGuestMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Guest Member'**
  String get removeGuestMember;

  /// No description provided for @removeGuestMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from this group? Their expenses will remain.'**
  String removeGuestMemberConfirm(String name);

  /// No description provided for @failedToRemoveGuest.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove guest member'**
  String get failedToRemoveGuest;

  /// No description provided for @failedToAddGuest.
  ///
  /// In en, this message translates to:
  /// **'Failed to add guest member'**
  String get failedToAddGuest;

  /// No description provided for @failedToRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment'**
  String get failedToRecordPayment;

  /// No description provided for @whoOwesWhom.
  ///
  /// In en, this message translates to:
  /// **'Who Owes Whom'**
  String get whoOwesWhom;

  /// No description provided for @selectedUserOwes.
  ///
  /// In en, this message translates to:
  /// **'{name} owes'**
  String selectedUserOwes(String name);

  /// No description provided for @selectedUserIsOwed.
  ///
  /// In en, this message translates to:
  /// **'{name} is owed'**
  String selectedUserIsOwed(String name);

  /// No description provided for @confirmedStatus.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmedStatus;

  /// No description provided for @expenseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseDate;

  /// No description provided for @splitDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Split Details'**
  String get splitDetailsLabel;

  /// No description provided for @paymentRecipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get paymentRecipientLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'fr',
    'it',
    'ru',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
