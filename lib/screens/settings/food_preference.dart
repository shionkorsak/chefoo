import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/tags/tag_map.dart';
import 'package:chefoo/widgets/tags/tag.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  String selectedTab = 'Dietary Preference';

  List<String> dietaryTags = ['Vegetarian', 'Halal', 'Vegan', 'Low Sugar'];
  List<String> dislikeTags = [
    'No Pork',
    'No Beef',
    'No Seafood',
    'Spicy',
    'Coriander-Free'
  ];
  List<String> allergyTags = [
    'Lactose Intolerant',
    'Nut Allergy',
    'Gluten-Free'
  ];

  List<String> dietarySelectedTags = [];
  List<String> dislikeSelectedTags = [];
  List<String> allergySelectedTags = [];

  bool isShaking = false;

  late final PageController _pageController;
  final List<String> tabLabels = [
    'Dietary Preference',
    'Dislike',
    'Allergy',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: tabLabels.indexOf(selectedTab));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                    for (final label in tabLabels)
                      _buildTab(
                        label,
                        isSelected: selectedTab == label,
                        onTap: () {
                          final page = tabLabels.indexOf(label);
                          if (_pageController.page?.round() != page) {
                            _pageController.animateToPage(
                              page,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
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
                child: GestureDetector(
                  onTap: () {
                    if (isShaking) setState(() => isShaking = false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedTab = tabLabels[index];
                        isShaking = false;
                      });
                    },
                    itemCount: tabLabels.length,
                    itemBuilder: (context, index) {
                      final label = tabLabels[index];
                      if (label == 'Dislike') {
                        return _buildTagWrap(dislikeTags, dislikeSelectedTags);
                      } else if (label == 'Allergy') {
                        return _buildTagWrap(allergyTags, allergySelectedTags);
                      } else {
                        return _buildTagWrap(dietaryTags, dietarySelectedTags);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isShaking)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Center(
                    child: DragTarget<String>(
                      onWillAccept: (_) => true,
                      onAccept: (tag) {
                        setState(() {
                          if (selectedTab == 'Dislike') {
                            dislikeTags = List.from(dislikeTags)..remove(tag);
                            dislikeSelectedTags.remove(tag);
                          } else if (selectedTab == 'Allergy') {
                            allergyTags.remove(tag);
                            allergySelectedTags.remove(tag);
                          } else {
                            dietaryTags.remove(tag);
                            dietarySelectedTags.remove(tag);
                          }
                        });
                      },
                      builder: (context, candidateData, rejectedData) => const Icon(
                        Icons.delete,
                        size: 32,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              Center(
                child: GlowingButton(
                  text: selectedTab == 'Dislike'
                      ? 'Add Dislike'
                      : selectedTab == 'Allergy'
                          ? 'Add Allergy'
                          : 'Add Preference',
                  onPressed: () {
                    if (isShaking) return;

                    setState(() {
                      final baseName = 'New ${selectedTab.split(' ').first}';
                      int counter = 1;
                      String newTag = baseName;

                      List<String> targetList = selectedTab == 'Dislike'
                          ? dislikeTags
                          : selectedTab == 'Allergy'
                              ? allergyTags
                              : dietaryTags;

                      // Ensure the newTag is unique by incrementing until no conflict
                      while (targetList.contains(newTag)) {
                        newTag = '$baseName $counter';
                        counter++;
                      }

                      targetList.add(newTag);
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

  Widget _buildTab(String label,
      {bool isSelected = false, VoidCallback? onTap}) {
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

  Widget _buildTagWrap(List<String> tags, List<String> selectedTags) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              KeyedSubtree(
                key: ValueKey(tag),
                child: isShaking
                    ? Draggable<String>(
                        data: tag,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Tag(
                            label: tag,
                            selected: false,
                            isShaking: true,
                            isTappable: false,
                            isLongPressable: false,
                            onSelected: (_) {},
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: Tag(
                            label: tag,
                            selected: false,
                            isShaking: true,
                            isTappable: false,
                            isLongPressable: true,
                            onSelected: (_) {},
                            onLongPress: () {
                              setState(() {
                                isShaking = true;
                              });
                            },
                          ),
                        ),
                        child: Tag(
                          label: tag,
                          selected: false,
                          isShaking: true,
                          isTappable: false,
                          isLongPressable: true,
                          onSelected: (_) {},
                          onLongPress: () {
                            setState(() {
                              isShaking = true;
                            });
                          },
                        ),
                      )
                    : Tag(
                        label: tag,
                        selected: false,
                        isShaking: false,
                        isTappable: false,
                        isLongPressable: true,
                        onSelected: (_) {},
                        onLongPress: () {
                          setState(() {
                            isShaking = true;
                          });
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  void _editTag(String oldValue) async {
    final controller = TextEditingController(text: oldValue);
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Edit Tag"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text("Save"),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );

    if (newTag == null || newTag.isEmpty || newTag == oldValue) return;

    setState(() {
      final sanitizedTab = selectedTab.trim();
      final tagListMap = {
        'Dietary Preference': dietaryTags,
        'Dislike': dislikeTags,
        'Allergy': allergyTags,
      };

      final tagsList = tagListMap[sanitizedTab];
      if (tagsList == null) return;

      final index = tagsList.indexOf(oldValue);
      if (index != -1) {
        tagsList[index] = newTag;

        if (sanitizedTab == 'Dislike') {
          if (dislikeSelectedTags.contains(oldValue)) {
            dislikeSelectedTags = dislikeSelectedTags
                .map((tag) => tag == oldValue ? newTag : tag)
                .toList();
          }
        } else if (sanitizedTab == 'Allergy') {
          if (allergySelectedTags.contains(oldValue)) {
            allergySelectedTags = allergySelectedTags
                .map((tag) => tag == oldValue ? newTag : tag)
                .toList();
          }
        } else {
          if (dietarySelectedTags.contains(oldValue)) {
            dietarySelectedTags = dietarySelectedTags
                .map((tag) => tag == oldValue ? newTag : tag)
                .toList();
          }
        }
      }
    });
  }
}
