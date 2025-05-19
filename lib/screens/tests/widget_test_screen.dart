import 'package:chefoo/widgets/ai_input_field.dart';
import 'package:chefoo/widgets/buttons/arrow_button.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';
import 'package:chefoo/widgets/star_ratings/star_rating_editable.dart';
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
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';

class WidgetTestScreen extends StatefulWidget {
  WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthCard(
                    children: [
                      BorderTextField(label: 'Enter your text here'),
                      SizedBox(
                        height: 32,
                      ),
                      GlowingButton(onPressed: () {}, text: 'Get Started'),
                      SizedBox(
                        height: 32,
                      ),
                      TagMap(tags: ['aaaa', 'bbbb', 'cccc']),
                      SizedBox(
                        height: 32,
                      ),
                      GoogleLoginButton(),
                      SizedBox(
                        height: 32,
                      ),
                      GoogleImportButton(),
                      SizedBox(
                        height: 32,
                      ),
                      LinearProgressIndicator(
                        value: 0.5,
                      ),
                      SizedBox(
                        height: 32,
                      ),
                      DotsPageIndicator(pageCount: 5, currentPage: 4),
                      SizedBox(
                        height: 32,
                      ),
                      ArrowButton(
                        onPressed: () {},
                      ),
                      SizedBox(
                        height: 32,
                      ),
                      AIInputField(),
                      SizedBox(height: 32),
                      StarRatingEditable(rating: 1)
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: CustomBottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ]),
      ),
    );
  }
}
