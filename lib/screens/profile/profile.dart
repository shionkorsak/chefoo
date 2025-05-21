import 'package:chefoo/models/user/user_account.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/screens/main_test.dart';
import 'package:chefoo/widgets/cards/favorite_list.dart';
import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/settings/account_settings.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';
import 'package:chefoo/screens/map_view.dart';
import 'package:chefoo/providers/restaurant.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<UserAccountProvider>(context, listen: false).fetchUserAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Consumer<UserAccountProvider>(
                builder: (context, provider, child) {
              if (provider.isLoading)
                return Center(child: CircularProgressIndicator());
              if (provider.errorMessage != null) {
                return Center(
                    child: Text(provider.errorMessage!,
                        style: TextStyle(color: Colors.red)));
              }

              final account = provider.userAccount;
              if (account == null)
                return Center(child: Text("No user data available."));

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header background
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/chefoo_banner.png',
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SettingsScreen()),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.settings,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 16,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: account
                                                      .profile.photoURL !=
                                                  null &&
                                              account
                                                  .profile.photoURL!.isNotEmpty
                                          ? NetworkImage(
                                              account.profile.photoURL!)
                                          : AssetImage(
                                                  'assets/images/profile_picture.png')
                                              as ImageProvider,
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        Text(
                                          account.profile.displayName,
                                          style:
                                              AppTextStyles.headline2.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'TO DO: HEALTH INSIGHTS',
                                style: AppTextStyles.detail
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Favorites', style: AppTextStyles.headline2),
                          const SizedBox(height: 8),
                          FavoriteList(),
                          const SizedBox(height: 24),
                          Text('History', style: AppTextStyles.headline2),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 240,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) => Container(
                                width: 160,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text('TO DO',
                                      style: AppTextStyles.detail),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentIndex: 2,
              onTap: (index) {
                if (index == 1) {
                  // Replace this with your actual GPS toggle or navigation logic
                  print('Map tab tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MapViewScreen(
                              places: Provider.of<RestaurantProvider>(context, listen: false).places,
                            )),
                  );
                } else if (index == 0) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  print('Home tab tapped');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
