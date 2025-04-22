import 'package:flutter_skeleton/commons.dart';

class DotsPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final double dotSize;
  final Color activeColor;
  final Color inactiveColor;

  const DotsPageIndicator(
      {Key? key,
      required this.pageCount,
      required this.currentPage,
      this.dotSize = 8.0,
      this.activeColor = AppColors.primary,
      this.inactiveColor = AppColors.secondary})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}
