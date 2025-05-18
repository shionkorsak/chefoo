# Authentication Services Documentation
Knowledge prerequisites: Database Services Documentation (`../database/README.md`)
Read until the end before usage.

## `auth_gate`
This file needs to be placed in the initialization of the app, in the main.dart's home.
```main.dart
...
home: AuthGate());
...
```

The purpose of this file is to lead user that has logged in before to the home screen of the app directly and lead user that has not logged in to the onboarding screen.

## `auth_service`
This file is make an instance of the Firebase Authentication.
How to use this instance:
In whatever file you need user authentication for (i.e: fetching the user's data (uid, email, displayName, etc.))
```dart
final _auth = AuthService(); // have this line in your file
// example: get user's uid
String? get uid => _auth.getCurrentUserUID();
```

### Available Services
1. `getCurrentUser()`
return **User's instance**
*nb: user's instance should not be that useful, unless you need the Firebase User instance itself*
2. `getCurrentUserUID()`
return **String of user's uid**
*nb: uid is to differentiate each user in the database, like a name tag*
*nb: uid is useful when you want to isolate a user (i.e. fetching anything from a certain user)*
3. `getCurrentUserDisplayName()`
return **String of user's display name in their Google account**
*nb: useful to get user's display name in profile page*
4. `getCurrentUserPhotoURL()`
return **String of user's photo URL from their Google account**
*nb: useful to get user's profile picture in profile page*
5. `signInWithGoogle()`
call this function when user sign in
example:
```dart
Button(
    ...
    onPressed: () async {
        await _auth.signInWithGoogle();
        ...
    }
    ...
)
```
6. `signOut()`
call this function when user sign out
example:
```dart
Button(
    ...
    onPressed: () async {
        await _auth.signOut();
        ...
    }
    ...
)
```
7. `deleteAccount()`
call this function when user delete account
example:
```dart
Button(
    ...
    onPressed: () async {
        await _auth.deleteAccount();
        ...
    }
    ...
)
```

### Additional Information
This is a direct fetch from the User's account. Don't use this unless you want to debug your own authentication.
To fetch the user's data from the database, I have already provided another service for that, in the `user_account_service.dart` service. Refer to that for more information.
Make sure to import `commons.dart` before usages