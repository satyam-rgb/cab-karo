import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../utils/colors.dart';
import '../utils/sizeconst.dart';
import '../utils/textstyles.dart';
import '../widgets/button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppPallete.background,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: PageView(
                controller: _controller,
                children: [
                  // onboarding image 1
                  buildPage(
                    image: 'assets/images/cab1.jpg',
                    title: 'Compare Prices of Cabs',
                    description:
                        'Provides you with the best prices for your cab rides in town',
                  ),
                  // onboarding image 2
                  buildPage(
                    image: 'assets/images/cab2.jpg',
                    title: 'Seamless Comparisons',
                    description:
                        'Compare prices of cabs from different companies in one place',
                  ),
                  // onboarding image 3
                  buildPage(
                    image: 'assets/images/cab3.jpg',
                    title: 'Integration with Maps',
                    description:
                        'Get the best prices and navigate to your destination with ease',
                  ),
                ],
              ),
            ),
          ),

          // smooth page indicator
          SmoothPageIndicator(
            controller: _controller,
            count: 3,
            effect: const WormEffect(
              dotColor: AppPallete.greyPrimary,
              activeDotColor: AppPallete.primaryColor,
              dotHeight: 10,
              dotWidth: 10,
            ),
          ),
          buildHeight(deviceHeight(context) * 0.04),

          // next button
          SizedBox(
            width: deviceWidth(context) * 0.85,
            child: CustomButton.buildCustomButton(
              context: context,
              isArrowVisible: true,
              onPressed: () {
                if (_controller.page == 2) {
                  Navigator.pushNamed(context, '/loginScreen');
                  // Navigator.pushNamed(context, '/homeScreen');
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeIn,
                  );
                }
              },
              text: 'Next',
            ),
          ),
          buildHeight(deviceHeight(context) * 0.04),
        ],
      ),
    );
  }

  // custom onboarding page
  Widget buildPage(
      {required String image,
      required String title,
      required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: deviceHeight(context) * 0.28,
          ),
          buildHeight(deviceHeight(context) * 0.08),
          Text(
            title,
            style:
                TextStyles.largeText.copyWith(color: AppPallete.secondaryColor),
          ),
          buildHeight(deviceHeight(context) * 0.02),
          Text(description,
              textAlign: TextAlign.center,
              style: TextStyles.smallText
                  .copyWith(color: AppPallete.greyTextcolor)),
        ],
      ),
    );
  }
}
