import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class AIInputField extends StatefulWidget {
  const AIInputField({super.key});

  @override
  State<AIInputField> createState() => _AIInputFieldState();
}

class _AIInputFieldState extends State<AIInputField> {
  final TextEditingController _controller = TextEditingController();

  void _sendInput() {
    final input = _controller.text;
    print('Input sent: $input');
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Type your prompt here (eg.. I’m craving spicy food.)',
          hintStyle: TextStyle(color: AppColors.surface.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
          fillColor: AppColors.secondary,
          suffixIcon: Padding(
            padding: const EdgeInsets.all(4.0),
            child: IconButton(
              icon: Icon(IconsaxPlusLinear.send_1),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.secondary,
                iconSize: 24,
              ),
              onPressed: _sendInput,
            ),
          ),
        ),
        style: TextStyle(color: AppColors.surface),
        onSubmitted: (_) => _sendInput(),
      ),
    );
  }
}
