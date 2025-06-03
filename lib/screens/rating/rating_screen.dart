import 'package:chefoo/providers/rating_session.dart';
import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets//star_ratings/star_rating.dart';
import 'package:chefoo/widgets/border_text_field.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';
import 'rating_controller.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  late RatingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RatingController();
  }

  void _addEntry() {
    setState(() {
      _controller.addEntry();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratingSession = Provider.of<RatingSessionProvider>(context);
    final restaurantName = ratingSession.restaurantName ?? 'Unknown';
    final imagePhotoRef = ratingSession.restaurantPhoto ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    image: DecorationImage(
                      image: AssetImage(imagePhotoRef),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  restaurantName,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: StarRating(rating: 5.0),
              ),
              const SizedBox(height: 8),
              ..._controller.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Dismissible(
                    key: ValueKey(entry['meal']),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      setState(() {
                        _controller.removeEntry(_controller.entries.indexOf(entry));
                      });
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('What did you eat?', style: AppTextStyles.headline3),
                          const SizedBox(height: 8),
                          BorderTextField(
                            label: '',
                            key: ValueKey(entry['meal']),
                            onChanged: (value) {
                              entry['meal']?.text = value;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('How was the meal?', style: AppTextStyles.headline3),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Your response will be used to train our AI for better recommendations.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          BorderTextField(
                            label: '',
                            key: ValueKey(entry['comment']),
                            onChanged: (value) {
                              entry['comment']?.text = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 2),
              Center(
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                  onPressed: _addEntry,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GlowingButton(
                  text: 'Done',
                  onPressed: () {
                    // Handle submission logic here
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}