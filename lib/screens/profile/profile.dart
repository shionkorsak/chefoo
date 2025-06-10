import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/screens/favorites/favorites_screen.dart';
import 'package:chefoo/screens/history/history_screen.dart';
import 'package:chefoo/screens/settings/account_settings.dart';
import 'package:chefoo/widgets/cards/favorite_list.dart';
import 'package:chefoo/widgets/cards/history_list.dart';
import 'package:chefoo/widgets/healthy_score.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserAccountProvider>(context, listen: false).fetchUserAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Consumer<UserAccountProvider>(builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null) {
              return Center(
                  child: Text(provider.errorMessage!,
                      style: TextStyle(color: Colors.red)));
            }

            final account = provider.userAccount;
            if (account == null) {
              return Center(child: Text("No user data available."));
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header + HealthyScore section (with horizontal padding)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
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
                                            const SettingsScreen(),
                                      ),
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
                                                      .profile?.photoURL !=
                                                  null &&
                                              account.profile!.photoURL!
                                                  .isNotEmpty
                                          ? NetworkImage(
                                              account.profile!.photoURL!)
                                          : const AssetImage(
                                                  'assets/images/profile_picture.png')
                                              as ImageProvider,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      account.profile!.displayName,
                                      style: AppTextStyles.headline2.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: HealthyScore(
                                score: account.healthInsight?.healthScore
                                        .toInt() ??
                                    0),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Favorites section title row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Favorites',
                              style: AppTextStyles.headline2
                                  .copyWith(color: AppColors.textPrimary)),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios_rounded,
                                size: 18, color: AppColors.textPrimary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FavoritesScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const FavoriteList(),
                    // History section title row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('History',
                              style: AppTextStyles.headline2
                                  .copyWith(color: AppColors.textPrimary)),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios_rounded,
                                size: 18, color: AppColors.textPrimary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HistoryScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const HistoryList(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
