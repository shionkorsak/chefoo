import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/tags/tag_map.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  String selectedTab = 'Dietary Preference';

  final List<String> dietaryTags = ['Vegetarian', 'Halal', 'Vegan', 'Low Sugar'];
  final List<String> dislikeTags = ['No Pork', 'No Beef', 'No Seafood', 'Spicy', 'Coriander-Free'];
  final List<String> allergyTags = ['Lactose Intolerant', 'Nut Allergy', 'Gluten-Free'];

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
                  "Food Preferences",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTab('Dietary Preference', isSelected: selectedTab == 'Dietary Preference', onTap: () {
                      setState(() {
                        selectedTab = 'Dietary Preference';
                      });
                    }),
                    _buildTab('Dislike', isSelected: selectedTab == 'Dislike', onTap: () {
                      setState(() {
                        selectedTab = 'Dislike';
                      });
                    }),
                    _buildTab('Allergy', isSelected: selectedTab == 'Allergy', onTap: () {
                      setState(() {
                        selectedTab = 'Allergy';
                      });
                    }),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  thickness: 1,
                  height: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TagMap(
                      tags: selectedTab == 'Dislike'
                          ? dislikeTags
                          : selectedTab == 'Allergy'
                              ? allergyTags
                              : dietaryTags,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GlowingButton(
                  text: selectedTab == 'Dislike'
                      ? 'Add Dislike'
                      : selectedTab == 'Allergy'
                          ? 'Add Allergy'
                          : 'Add Preference',
                  onPressed: () {
                    setState(() {
                      final newTag = 'New ${selectedTab.split(' ').first}';
                      if (selectedTab == 'Dislike') {
                        dislikeTags.add(newTag);
                      } else if (selectedTab == 'Allergy') {
                        allergyTags.add(newTag);
                      } else {
                        dietaryTags.add(newTag);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 30,
              height: 2,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Text(
        label,
        style: AppTextStyles.detail.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
