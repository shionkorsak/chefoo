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
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Stack(
                  children: [
                    OverflowBox(
                      alignment: Alignment.center,
                      //maxHeight: 500,
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
          width: state == 1 ? width : 119,
          height: state == 1 ? height : 33,
          decoration: ShapeDecoration(
            color: color.withOpacity(state == 1 ? 1 : 0),
            shape: OvalBorder(),
          ),
        ),
      ),
    );
  }
}
