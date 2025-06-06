import 'package:chefoo/screens/splash/splash.dart';
import 'package:chefoo/screens/welcome/get_started_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/settings/settingstile.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/providers/calendar_state.dart';


class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final _auth = AuthService();
  bool _calendarLinked = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkCalendarPermission();
  }

  Future<void> _checkCalendarPermission() async {
    final calendarProvider = Provider.of<CalendarStateProvider>(context, listen: false);
    try {
      final hasPermission = await calendarProvider.checkCalendarPermissions();
      
      if (mounted) {
        setState(() {
          _calendarLinked = hasPermission;
          _checkingPermissions = false;
        });
      }
    } catch (e) {
      print('Error checking calendar permission: $e');
      if (mounted) {
        setState(() {
          _calendarLinked = false;
          _checkingPermissions = false;
        });
      }
    }
  }

  Future<void> _requestCalendarPermission() async {
    setState(() => _checkingPermissions = true);
    
    try {
      final calendarProvider = Provider.of<CalendarStateProvider>(context, listen: false);
      final granted = await calendarProvider.requestCalendarPermissions();
      
      if (mounted) {
        setState(() {
          _calendarLinked = granted;
          _checkingPermissions = false;
        });
      }
      
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calendar successfully linked!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar access was not granted. Some features may be limited.'),
            backgroundColor: Colors.orange,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingPermissions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking calendar: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Manage Account",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 4),
              AuthCard(
                padding: const EdgeInsets.all(16),
                children: [
                  Text("Linked Accounts", style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.link,
                    subtitle: "Google Calendar",
                    trailing: _checkingPermissions
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _calendarLinked ? "(linked)" : "(unlinked)",
                            style: TextStyle(
                              color: _calendarLinked ? Colors.grey : Colors.red,
                            ),
                          ),
                    onTap: _checkingPermissions
                        ? null
                        : () {
                            if (!_calendarLinked) {
                              _requestCalendarPermission();
                            } else {
                              // Show options when already linked
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Calendar Access"),
                                  content: const Text(
                                    "Your Google Calendar is currently linked. Do you want to unlink it?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("CANCEL"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final calendarProvider = Provider.of<CalendarStateProvider>(
                                          context, 
                                          listen: false
                                        );
                                        await calendarProvider.revokeCalendarAccess();
                                        setState(() => _calendarLinked = false);
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Calendar unlinked successfully'),
                                          ),
                                        );
                                      },
                                      child: const Text("UNLINK", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                    leading: SvgPicture.asset("assets/svgs/google_icon.svg", height: 24),
                  ),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.link,
                    subtitle: "Google",
                    trailing: const Text("(linked)", style: TextStyle(color: Colors.grey)),
                    onTap: () {
                      // Handle Google press
                    },
                    leading: SvgPicture.asset("assets/svgs/google_icon.svg", height: 24),
                  ),
                ],
              ),
              //const SizedBox(height: 8),
              //kGap5,
              AuthCard(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Delete Account",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Deleting your account is permanent. When you delete your chefoo account, all of your data will be permanently removed.",
                  ),
                  const SizedBox(height: 16),
                  GlowingButton(
                    text: "Delete",
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text("Alert"),
                          content: const Text("Are you sure about deleting your Chefoo account ?"),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the first dialog
                                showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text("Alert"),
                                    content: const Text("Your Chefoo account has been successfully deleted."),
                                    actions: [
                                      CupertinoDialogAction(
                                        isDefaultAction: true,
                                        onPressed: () async {
                                          final navigator = Navigator.of(context); // Save BEFORE pop
                                          navigator.pop(); // Close the dialog
                                          await _auth.deleteAccount();
                                          navigator.pushReplacement(
                                            MaterialPageRoute(builder: (_) => GetStartedScreen()),
                                          );
                                        },
                                        child: const Text("Done", style: TextStyle(color: AppColors.primary)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              //kGap5,
              Center(
                child: GlowingButton(
                  onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text("Alert"),
                          content: const Text("Do you want to logout your \nChefoo account ?"),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () async {
                                Navigator.of(context).pop(); // Close the first dialog
                                showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text("Alert"),
                                    content: const Text("You have been successfully logged out."),
                                    actions: [
                                      CupertinoDialogAction(
                                        isDefaultAction: true,
                                        onPressed: () async { 
                                          Navigator.of(context).pop();
                                          Navigator.pushReplacement(
                                            context, 
                                            MaterialPageRoute(
                                              builder: (BuildContext context) => GetStartedScreen()
                                            )
                                          );
                                          await _auth.signOut();
                                        },
                                        child: const Text("Done", style: TextStyle(color: AppColors.primary)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );
                    },
                  text: "Log Out",
                  textColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  //foregroundColor: AppColors.primary,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}