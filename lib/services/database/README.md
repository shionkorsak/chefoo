# Database Services Documentation
Open these directories beforehand: `../providers/user_account.dart/` and `../models/user`
The services are still not completed, yet. Some methods might have different names by the time you're reading this.
Read until the end before usage.

## `user_account_service`
Call this instance if you need to fetch user's data from their account in the database.

### Available Services (WIP)
1. `fetchUserAccount()`
The example I provided is advised to be used in a provider instead of calling it directly, to avoid multiple fetches.
```dart
final _userAccountService = UserAccountService();
UserAccount? _userAccount;
UserAccount? get userAccount => _userAccount;

Future<void> getUserAccount() async {
    try {
        _userAccount = await _service.fetchUserAccount();
        if(_userAccount == null) {
            ... // do stuff if account does not exist
        } 
    } catch(e) {
        ... // do stuff if other error persists
    }
}
```
or another simple way, using getter (don't use in provider)
```dart
final _userAccountService = UserAccountService();
Future<UserAccount?> get _userAccount async => await _userAccountService.fetchUserAccount();
```

If you need full example of the usage + provider, I have provided it in the `../providers/user_account.dart/` directory.

From now onwards refer to the provider file, the example usages I will be providing will be based on the provider.
1. After setting the provider up in the initialization state method in the widget, refer to the provider in the UI (i.e. accountProvider)
2. You're supposedly to have these lines in the file, if not then do so according to your own provider logic
```dart
...
final account = accountProvider.userAccount; // you can access the entire database of the user with this
//example: get user's displayName
final displayName = account.profile.displayName;
...
```
According to the previous example, `account` is an object of the model UserAccount. You can further refer to the model in the `../models/user/user_account.dart` directory.
*!nb: models are still unstable, use with cautions*

2. `updateUserPreferences()`
This is an update preferences method that handles the **dietaryPreferences** and **allergies** in the database, it will only pass client's new **dietaryPreferences** and **allergies** (so make sure that you have these set up). It will also update the user's nutrition personalities from the AI with the new client updates.
Example usage (+providers, also will be based on previous fetchUserAccount() example):
```provider.dart
Future<void> updateUserPreferences(List<String> dietaryPreferences, List<String> allergies) async {
    final success = await _service.updateUserPreferences(
        dietaryPreferences: dietaryPreferences,
        allergies: allergies,
    ); // calling the service

    if (success) {
        // what happens after the update has happened in the database (i.e. make sure to fetch the account again)
        ...
    }

    return success;
}
```
```dart
Button(
    ...
    onPressed: () async {
        final dietary = ... // new dietaryPreferences
        final allergies = ... // new allergies
        await accountProvider.updateUserPreferences(dietary, allergies);
    }
)
```

### Additional Information
The current services available do not handle updates in terms of favorite restaurant, meals history, and recommendation yet.
Make sure to import `commons.dart` before usages.