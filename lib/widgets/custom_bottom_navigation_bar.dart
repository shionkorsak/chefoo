import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/main/main_screen.dart';
import 'package:chefoo/screens/map/map_screen.dart';
import 'package:chefoo/screens/profile/profile.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: Offset(8, 20))
      ]),
      child: ClipRRect(
        borderRadius: kRadius30,
        child: BottomNavigationBar(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          iconSize: 28,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(IconsaxPlusLinear.home_1),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconsaxPlusLinear.location),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconsaxPlusLinear.user_square),
              label: 'Profile',
            ),
          ],
          currentIndex: currentIndex,
          onTap: onTap,
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final bool showWelcomeDialog;
  const MainNavigation({super.key, required this.showWelcomeDialog});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final places = Provider.of<RestaurantProvider>(context).places;

    final List<Widget> screens = [
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
        child: MainScreen(showWelcomeDialog: false,),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
        child: MapScreen(places: places),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
        child: ProfileScreen(),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}