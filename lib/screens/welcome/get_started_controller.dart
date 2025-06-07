part of 'get_started_screen.dart';

abstract class GetStartedController extends State<GetStartedScreen> {
  final _auth = AuthService();
  int state = 0;
  bool showFinalScreenContent = false;
  final TextEditingController allergyController = TextEditingController();
  bool nameError = false;
  late GetStartedProvider provider;
  late UserAccountProvider userAccountProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider = Provider.of<GetStartedProvider>(context);
    userAccountProvider = Provider.of<UserAccountProvider>(context, listen: false);
  }

  @override
  void dispose() {
    provider.nameController.dispose();
    super.dispose();
  }

  Widget buildBackground() {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedPadding(
        duration: Duration(milliseconds: 600), // Increased duration
        curve: Curves.easeOutCubic, // Smoother curve
        padding: EdgeInsets.only(top: (provider.state == 5 || provider.state == 6) ? 20 : 120),
        child: Stack(
          children: [
            OverflowBox(
              alignment: Alignment.center,
              maxWidth: 1000,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOval(
                    width: 540,
                    height: 210,
                    color: const Color(0xFFFFCBAB),
                    state: provider.state,
                    paddingTop: 60,
                  ),
                  AnimatedOval(
                    width: 360,
                    height: 120,
                    color: const Color(0xFFF8B78F),
                    state: provider.state,
                    paddingTop: 75,
                  ),
                  AnimatedOval(
                    width: 240,
                    height: 60,
                    color: const Color(0xFFF58F51),
                    state: provider.state,
                    paddingTop: 90,
                  ),
                  AnimatedOval(
                    width: 120,
                    height: 30,
                    color: const Color(0xFFF16614),
                    state: 1,
                    paddingTop: 105,
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Hero(
                    tag: 'logo_hero',
                    flightShuttleBuilder: (
                      BuildContext flightContext,
                      Animation<double> animation,
                      HeroFlightDirection flightDirection,
                      BuildContext fromHeroContext,
                      BuildContext toHeroContext,
                    ) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: animation.value,
                            child: SvgPicture.asset(
                              'assets/svgs/Logo-3.svg',
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/svgs/Logo-3.svg',
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWelcomeContent() {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(top: provider.state >= 1 ? 240 : 160),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 200),
            const Text(
              "welcome to",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            kGap5,
            SvgPicture.asset(
              'assets/svgs/chefoo.svg',
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget buildAuthCard() {
    return OverflowBox(
      maxHeight: double.infinity,
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: provider.state >= 1 ? const Offset(0, 60) : const Offset(0, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600), // Increased duration
          curve: Curves.easeOutCubic, // Smoother curve
          child: AnimatedSlide(
            offset: provider.state >= 2 ? const Offset(0, 0) : const Offset(0, 1),
            duration: const Duration(milliseconds: 600), // Increased duration
            curve: Curves.easeOutCubic, // Smoother curve
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 800), // Increased duration
              switchInCurve: Curves.easeOutCubic, // Smoother curve
              switchOutCurve: Curves.easeInCubic, // Smoother curve
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, 0.3), // Reduced slide distance
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic, // Smoother curve
                  )),
                  child: FadeTransition(
                    // Added fade transition
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: AnimatedSize(
                duration: Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                child: AuthCard(
                  key: ValueKey(provider.state),
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: EdgeInsets.zero,
                  children: [
                    if (provider.state < 7)
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 18,
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            vertical: provider.state >= 2 ? 24 : 40,
                            horizontal: 18,
                          ),
                          child: buildCardContent(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCardContent() {
    switch (provider.state) {
      case 2:
        return Column(
          key: ValueKey(2),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Discover nearby delicacies",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            kGap8,
            kGap8,
            kGap8,
            Text(
              "Never break a sweat over what to eat — let us serve up the perfect meal idea anytime, anywhere.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            kGap8,
            kGap8,
            ElevatedButton(
              onPressed: () async {
                await Future.delayed(Duration(milliseconds: 300), () {
                  provider.setState(3);
                });
              },
              child: Text("Next"),
            ),
            SizedBox(height: 48),
          ],
        );
      case 3:
        return Column(
          key: ValueKey(3),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Welcome!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            kGap8,
            Text(
              "Login with Google \n to unlock your best experience.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            kGap8,
            GoogleLoginButton(
              onPressed: () async {
                await Future.delayed(Duration(milliseconds: 300), () async {
                  await _auth.signInWithGoogle();
                  await Future.delayed(Duration(seconds: 1)); 
                  await userAccountProvider.fetchUserAccount();

                  final account = userAccountProvider.userAccount;
                  final hasPrefs = account?.preferences!.dietaryPreferences.isNotEmpty == true ||
                                    account?.preferences!.allergies.isNotEmpty == true;
                  if(hasPrefs) {
                    provider.setState(7);
                    provider.setShowFinalScreenContent(false);
                    await Future.delayed(Duration(milliseconds: 700));
                    provider.setShowFinalScreenContent(true);
                  } else {
                    provider.setState(5);
                  }
                });
              },
            ),
            SizedBox(height: 48),
          ],
        );
      case 5:
        return Column(
          key: ValueKey(5),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "What are your dietary preferences?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            kGap5,
            kGap5,
            Text(
              "Help us get to know you better!!",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            kGap5,
            kGap5,
            TagMap(tags: [
              'No Preference',
              'No Pork',
              'No Beef',
              'No Seafood',
              'Dairy-free',
              'Gluten-free',
              'Vegan',
              'Vegetarian',
              'Pescatarian',
            ],
            onSelectionChanged: (tags) {
              provider.setSelectedTags(tags);
            },),
            kGap8,
            kGap8,
            kGap8,
            kGap8,
            TextField(
              controller: provider.otherDietaryController,
              decoration: InputDecoration(
                hintText: "Others",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            kGap8,
            kGap8,
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  "Do you have any allergies we should know about?",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            kGap5,
            TextField(
              controller: provider.allergiesController,
              decoration: InputDecoration(
                hintText: "Write your allergies here",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            kGap8,
            kGap8,
            kGap8,
            kGap8,
            ElevatedButton(
              onPressed: () async {
                final dietaryPreferences = [
                  ...provider.selectedTags,
                  if (provider.otherDietaryController.text.trim().isNotEmpty)
                    provider.otherDietaryController.text.trim(),
                ];

                final allergies = [
                  if(provider.allergiesController.text.trim().isNotEmpty)
                    provider.allergiesController.text.trim(),
                ];

                final success = await userAccountProvider.addUserPreferences(dietaryPreferences, allergies);

                if(success) {
                  await Future.delayed(Duration(milliseconds: 300), () {
                    provider.setState(6);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update preferences. Please try again.")),
                  );
                }
              },
              child: Text("Next"),
            ),
            SizedBox(height: 48),
          ],
        );
      case 6:
        return Column(
          key: ValueKey(6),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Sync Your Calendar\nfor Smarter Suggestions!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            kGap8,
            Text(
              "Help us get to know you better",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            kGap8,
            SvgPicture.asset(
              'assets/svgs/lock.svg',
              height: 120,
            ),
            kGap8,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                "We’ll only use your data to suggest the best restaurants for you.\nYour information stays private and secure",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            kGap8,
            GoogleImportButton(
              onPressed: () {
                // handle import action
              },
            ),
            kGap8,
            ElevatedButton(
              onPressed: () async {
                await Future.delayed(Duration(milliseconds: 300), () {
                  provider.setState(7);
                  provider.setShowFinalScreenContent(false);
                });
                await Future.delayed(Duration(milliseconds: 700));
                provider.setShowFinalScreenContent(true);
              },
              child: Text("Next"),
            ),
            kGap8,
            TextButton(
              onPressed: () async {
                await Future.delayed(Duration(milliseconds: 300), () {
                  provider.setState(7);
                  provider.setShowFinalScreenContent(false);
                });
                await Future.delayed(Duration(milliseconds: 700));
                provider.setShowFinalScreenContent(true);
              },
              child: Text("Skip for now"),
            ),
            SizedBox(height: 48),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget buildFinalScreen() {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 1000),
      opacity: provider.state == 7 ? 1.0 : 0.0,
      curve: Curves.easeInOut,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 450),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 800),
            opacity: provider.showFinalScreenContent ? 1.0 : 0.0,
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "welcome",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                kGap5,
                Text(
                  _auth.getCurrentUserDisplayName() ?? provider.nameController.text,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                kGap8,
                TextButton(
                  onPressed: () {
                    provider.setState(0);
                    provider.setShowFinalScreenContent(false);
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(
                        builder: (BuildContext context) => ProfileScreen()
                      )
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Are you hungry yet?",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_right_alt, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBottomButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Visibility(
          visible: provider.state == 1,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: GlowingButton(
            onPressed: () async {
              await Future.delayed(Duration(milliseconds: 300), () {
                provider.setState(2);
              });
            },
            text: "Get Started",
          ),
        ),
      ),
    );
  }
}
