import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/get_started.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/screens/profile/profile.dart';
import 'package:chefoo/widgets/buttons/glowing_button.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_import_button.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_login_button.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'get_started_controller.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreen();
}

class _GetStartedScreen extends GetStartedController {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GetStartedProvider>();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (provider.state == 0) {
          await Future.delayed(const Duration(milliseconds: 300));
          context.read<GetStartedProvider>().setState(1);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              buildBackground(),
              if (provider.state < 2) buildWelcomeContent(),
              if (provider.state >= 1 && provider.state <= 7) buildAuthCard(),
              if (provider.state == 7) buildFinalScreen(),
              buildBottomButton(),
            ],
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
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          width: state >= 1 ? width : 119,
          height: state >= 1 ? height : 33,
          decoration: ShapeDecoration(
            color: color.withOpacity(state >= 1 ? 1 : 0),
            shape: const OvalBorder(),
          ),
        ),
      ),
    );
  }
}

// class GetStartedScreen extends StatefulWidget {
//   const GetStartedScreen({super.key});

//   @override
//   State<GetStartedScreen> createState() => _GetStartedScreenState();
// }

// class _GetStartedScreenState extends GetStartedController {
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: () async {
//         if (state == 0) {
//           await Future.delayed(Duration(milliseconds: 300));
//           setState(() {
//             state = 1;
//           });
//         }
//       },
//       child: Scaffold(
//         body: SafeArea(
//           child: Stack(
//             children: [
//               buildBackground(),
//               if (state < 2) buildWelcomeContent(),
//               if (state >= 1 && state <= 7) buildAuthCard(),
//               if (state == 7) buildFinalScreen(),
//               buildBottomButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class AnimatedOval extends StatelessWidget {
//   final double width;
//   final double height;
//   final Color color;
//   final int state;
//   final double paddingTop;

//   const AnimatedOval({
//     super.key,
//     required this.width,
//     required this.height,
//     required this.color,
//     required this.state,
//     required this.paddingTop,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.topCenter,
//       child: Padding(
//         padding: EdgeInsets.only(top: paddingTop),
//         child: AnimatedContainer(
//           duration: Duration(milliseconds: 600), // Increased duration
//           curve: Curves.easeOutCubic, // Smoother curve
//           width: state >= 1 ? width : 119,
//           height: state >= 1 ? height : 33,
//           decoration: ShapeDecoration(
//             color: color.withOpacity(state >= 1 ? 1 : 0),
//             shape: OvalBorder(),
//           ),
//         ),
//       ),
//     );
//   }
// }

