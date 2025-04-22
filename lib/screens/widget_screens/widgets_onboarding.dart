import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_skeleton/widgets/border_text_field.dart';
import 'package:flutter_skeleton/widgets/buttons/glowing_button.dart';
import 'package:flutter_skeleton/widgets/buttons/google_buttons/google_import_button.dart';
import 'package:flutter_skeleton/widgets/buttons/google_buttons/google_login_button.dart';
import 'package:flutter_skeleton/widgets/dots_page_indicator.dart';
import 'package:flutter_skeleton/widgets/tags/tag_map.dart';

class WidgetTestScreen extends StatelessWidget {
  const WidgetTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BorderTextField(label: 'Enter your text here'),
          SizedBox(
            height: 32,
          ),
          GlowingButton(onPressed: () {}, text: 'Get Started'),
          SizedBox(
            height: 32,
          ),
          TagMap(tags: ['aaaa', 'bbbb', 'cccc']),
          SizedBox(
            height: 32,
          ),
          GoogleLoginButton(),
          GoogleImportButton(),
          SizedBox(
            height: 32,
          ),
          LinearProgressIndicator(
            value: 0.5, // 70% progress (0.0 to 1.0)
          ),
          SizedBox(
            height: 32,
          ),
          DotsPageIndicator(pageCount: 5, currentPage: 4)
        ],
      ),
    )));
  }
}
