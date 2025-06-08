import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/tags/tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  String selectedTab = 'Dietary Preference';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserAccountProvider>(context, listen: false).fetchUserAccount();
    });
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
                child: Text("Food Preferences", style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: tabLabels.map((label) => _buildTab(label)).toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(thickness: 1, height: 20, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isShaking = false),
                  behavior: HitTestBehavior.opaque,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() {
                      selectedTab = tabLabels[index];
                      isShaking = false;
                    }),
                    itemCount: tabLabels.length,
                    itemBuilder: (context, index) => _buildTagWrap(tabLabels[index]),
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
                      onAccept: (tag) =>
                          Provider.of<UserAccountProvider>(context, listen: false)
                              .removeTag(selectedTab, tag),
                      builder: (context, _, __) => const Icon(Icons.delete, size: 32, color: Colors.red),
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
                  onPressed: () => _addTag(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = selectedTab == label;
    return GestureDetector(
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
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.body.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textPrimary,
              )),
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

  Widget _buildTagWrap(String category) {
    final provider = Provider.of<UserAccountProvider>(context);
    final tags = category == 'Dislike'
        ? provider.dislikeTags
        : category == 'Allergy'
            ? provider.allergyTags
            : provider.dietaryTags;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => _buildTag(tag, category)).toList(),
        ),
      ),
    );
  }

  Widget _buildTag(String tag, String category) {
    return KeyedSubtree(
      key: ValueKey(tag),
      child: isShaking
          ? Draggable<String>(
              data: tag,
              feedback: Material(
                color: Colors.transparent,
                child: Tag(label: tag, selected: false, isShaking: true, isTappable: false),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: Tag(
                  label: tag,
                  selected: false,
                  isShaking: true,
                  isTappable: false,
                  isLongPressable: true,
                  onLongPress: () => setState(() => isShaking = true),
                ),
              ),
              child: Tag(
                label: tag,
                selected: false,
                isShaking: true,
                isTappable: false,
                isLongPressable: true,
                onLongPress: () => setState(() => isShaking = true),
              ),
            )
          : Tag(
              label: tag,
              selected: false,
              isShaking: false,
              isTappable: false,
              isLongPressable: true,
              onLongPress: () => setState(() => isShaking = true),
            ),
    );
  }

  void _addTag() {
    final provider = Provider.of<UserAccountProvider>(context, listen: false);
    final baseName = 'New ${selectedTab.split(' ').first}';
    int counter = 1;
    String newTag = baseName;

    final existingTags = selectedTab == 'Dislike'
        ? provider.dislikeTags
        : selectedTab == 'Allergy'
            ? provider.allergyTags
            : provider.dietaryTags;

    while (existingTags.contains(newTag)) {
      newTag = '$baseName $counter';
      counter++;
    }

    provider.addTag(selectedTab, newTag);
  }

  void _editTag(String oldValue) async {
    final controller = TextEditingController(text: oldValue);
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Edit Tag"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(controller: controller, autofocus: true),
        ),
        actions: [
          CupertinoDialogAction(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(child: const Text("Save"), onPressed: () => Navigator.pop(context, controller.text.trim())),
        ],
      ),
    );

    if (newTag != null && newTag.isNotEmpty && newTag != oldValue) {
      Provider.of<UserAccountProvider>(context, listen: false).editTag(selectedTab, oldValue, newTag);
    }
  }
}
