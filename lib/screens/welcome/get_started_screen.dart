import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_login_button.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_import_button.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';
import 'package:chefoo/widgets/tags/tag_map.dart';
import 'package:chefoo/commons.dart';

part 'get_started_controller.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends GetStartedController {
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
                buildBackground(),
                if (state < 2) buildWelcomeContent(),
                if (state >= 1 && state <= 7) buildAuthCard(),
                if (state == 7) buildFinalScreen(),
                buildBottomButton(),
              ],
            ),
          ),
        ),
      ),
    );
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
