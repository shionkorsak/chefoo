import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_login_button.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';

import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => GetStartedState();
}

class GetStartedState extends State<GetStarted> {
  int state = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: GestureDetector(
      onTap: () async {
        await Future.delayed(Duration(milliseconds: 300), () {
          if (state == 0) {
            setState(() {
              state = 1;
            });
          }
        });
      },
      child: Center(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
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
                            state: state,
                            paddingTop: 60,
                          ),
                          AnimatedOval(
                            width: 360,
                            height: 120,
                            color: const Color(0xFFF8B78F),
                            state: state,
                            paddingTop: 75,
                          ),
                          AnimatedOval(
                            width: 240,
                            height: 60,
                            color: const Color(0xFFF58F51),
                            state: state,
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
                          child: SvgPicture.asset(
                            'assets/svgs/Logo-3.svg',
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (state < 2)
              Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.only(top: state >= 1 ? 240 : 160),
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
              ),
            if (state >= 1)
              OverflowBox(
                maxHeight: double.infinity,
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset:
                      state == 1 || state == 2 ? Offset(0, 60) : Offset(0, -80),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    child: AnimatedSlide(
                      offset: state == 2 || state == 3
                          ? Offset(0, 0)
                          : Offset(0, 1),
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: AuthCard(
                        margin: EdgeInsets.symmetric(horizontal: 18),
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 18,
                            child: AnimatedPadding(
                              duration: Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(
                                vertical: state == 3 ? 24 : 40,
                                horizontal: 18,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (state == 2)
                                    Text(
                                      "Discover nearby delicacies",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  if (state == 3)
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
                                  kGap8,
                                  kGap8,
                                  if (state == 2)
                                    Text(
                                      "Never break a sweat over what to eat — let us serve up the perfect meal idea anytime, anywhere.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  if (state == 3)
                                    Text(
                                      "Login with Google \n to unlock your best experience.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  kGap8,
                                  kGap8,
                                  kGap8,
                                  kGap8,
                                  if (state == 2)
                                    ElevatedButton(
                                      onPressed: () async {
                                        await Future.delayed(
                                            Duration(milliseconds: 300), () {
                                          setState(() {
                                            state = 3;
                                          });
                                        });
                                      },
                                      child: Text("Next"),
                                    ),
                                  if (state == 2)
                                    Column(
                                      children: List.generate(9, (_) => kGap8),
                                    ),
                                  if (state == 3)
                                    GoogleLoginButton(
                                      onPressed: () {
                                        setState(() {
                                          state = 0;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Visibility(
                  visible: state == 1,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: GlowingButton(
                    onPressed: () async {
                      await Future.delayed(Duration(milliseconds: 300), () {
                        setState(() {
                          state = 2;
                        });
                      });
                    },
                    text: "Get Started",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )));
  }
}

class AnimatedOval extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final int state;
  final double paddingTop;

  const AnimatedOval({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.state,
    required this.paddingTop,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: state >= 1 ? width : 119,
          height: state >= 1 ? height : 33,
          decoration: ShapeDecoration(
            color: color.withOpacity(state >= 1 ? 1 : 0),
            shape: OvalBorder(),
          ),
        ),
      ),
    );
  }
}
