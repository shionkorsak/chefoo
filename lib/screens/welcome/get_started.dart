import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Padding(
      padding: kPadd40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svgs/Logo.svg',
            height: 360,
            fit: BoxFit.cover,
          ),
          
          kGap0,
          // ✨ Welcome Text
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

          const SizedBox(height: 160),
          //const Spacer(),

          ElevatedButton(
            onPressed: () {
              //print("Get Started!");
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: const Text("Get Started", style: AppTextStyles.button),
          ),
        ],
      ),
    )));
  }
}
