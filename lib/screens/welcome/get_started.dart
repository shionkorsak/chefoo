import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_skeleton/widgets/buttons/glowing_button.dart';
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
      onTap: () {
        setState(() {
          state = 1;
        });
      },
      child: Center(
        child: Stack(
          // to keep the logo fixed don't change plsssss
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 120),
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: EdgeInsets.zero,
                          width: state == 1 ? 659 : 119,
                          height: state == 1 ? 182 : 33,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: state == 1 ? 659 : 1.0,
                                height: state == 1 ? 182 : 1.0,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFCBAB)
                                      .withOpacity(state == 1 ? 1 : 0),
                                  shape: OvalBorder(),
                                ),
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: state == 1 ? 464 : 1.0,
                                height: state == 1 ? 128 : 1.0,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF8B78F)
                                      .withOpacity(state == 1 ? 1 : 0),
                                  shape: OvalBorder(),
                                ),
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: state == 1 ? 239 : 1.0,
                                height: state == 1 ? 66 : 1.0,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF58F51)
                                      .withOpacity(state == 1 ? 1 : 0),
                                  shape: OvalBorder(),
                                ),
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: 119,
                                height: 33,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF16614),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/svgs/Logo-3.svg',
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.only(top: state == 1 ? 240 : 160),
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 400),
                  opacity: state == 1 ? 1.0 : 0.0,
                  child: Visibility(
                    visible: state == 1,
                    child: GlowingButton(
                      onPressed: () {
                        setState(() {
                          state = 0;
                        });
                      },
                      text: "Get Started",
                    ),
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
