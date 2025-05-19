import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/widgets/buttons/arrow_button.dart';
import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/border_text_field.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_import_button.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_login_button.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';
import 'package:chefoo/widgets/cards/restaurant_card_vertical.dart';
import 'package:chefoo/widgets/dots_page_indicator.dart';
import 'package:chefoo/widgets/tags/tag_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chefoo/widgets/settings/settingstile.dart';
import 'package:chefoo/widgets/star_rating.dart';
import 'package:chefoo/widgets/restaurant_list.dart';
import 'package:chefoo/widgets/restaurant_card.dart';
import 'package:chefoo/widgets/ai_input_field.dart';

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AuthCard(
                children: [
                  SettingsTile(
                    icon: Icons.settings,
                    title: 'Manage Account',
                    onTap: () {
                      print('Chefoo tile tapped');
                    },
                  ),
                  SettingsTile(
                    icon: Icons.room_preferences,
                    title: 'Preferences',
                    onTap: () {
                      print('Preferencs tapped');
                    },
                  ),
                ],
              ),
              SizedBox(height: 32),
              AuthCard(
                children: [
                  BorderTextField(label: 'Enter your text here'),
                  SizedBox(height: 32),
                  GlowingButton(onPressed: () {}, text: 'Get Started'),
                  SizedBox(height: 32),
                  TagMap(tags: ['aaaa', 'bbbb', 'cccc']),
                  SizedBox(height: 32),
                  GoogleLoginButton(),
                  SizedBox(height: 32),
                  GoogleImportButton(),
                  SizedBox(height: 32),
                  LinearProgressIndicator(value: 0.5),
                  SizedBox(height: 32),
                  DotsPageIndicator(pageCount: 5, currentPage: 4),
                  ArrowButton(onPressed: () {})
                ],
              ),
              SizedBox(height: 32),
              AuthCard(
                children: [
                  SettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    trailing: Switch(
                      value: notificationsEnabled,
                      trackOutlineColor: WidgetStateColor.transparent,
                      activeColor: Colors.white,
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              StarRating(rating: 3.5),
              SizedBox(height: 32),
              Text("RestaurantList Preview", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(
                height: 200,
                child: RestaurantList(
                  places: [], // You can mock some Place objects if needed
                  isLoading: false,
                ),
              ),
              SizedBox(height: 32),
              AuthCard(
                children: [
                  Text("RestaurantCard Preview", style: Theme.of(context).textTheme.titleLarge),
                  RestaurantCard(
                    place: Place(
                      id: 'test_place',
                      name: 'Mock Restaurant',
                      address: '123 Test St, Test City',
                      rating: 4.2,
                      distance: 400, // ← Add this line to satisfy the required parameter
                      walkingDistance: 0.4,
                      isOpenNow: true,
                      pictureUrls: [],
                      reviews: [],
                      openingHours: [],
                      popularTimes: [],
                      phone: '123-456-7890',
                      lat: 25.033964,
                      lng: 121.564468,
                      tags: ['mock', 'test', 'demo'],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              AIInputField(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
