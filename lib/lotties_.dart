import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Lottiepage extends StatefulWidget {
  const Lottiepage({super.key});

  @override
  State<Lottiepage> createState() => _LottiepageState();
}

class _LottiepageState extends State<Lottiepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40,),
            Lottie.asset("assets/lotties/Chat_typing_indicator.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Error_404.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Loading_Animation.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Multiple_circles.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/paperplane.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/rocket_launch.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/rocket.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Sandy_Loading.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Loading_Animation_blue.json"),
              SizedBox(height: 40,),
            Lottie.asset("assets/lotties/Typing_Indicator.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Typing_status_1.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Typing_status.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Typing.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Welcome__1.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Welcome__2.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Welcome_2.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Welcome_Sticker.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Astronaut.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/welcome.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Typing_new.json"),
              SizedBox(height: 40,),
              Lottie.asset("assets/lotties/Dots.json"),
              SizedBox(height: 40,),
            ],
          ),
        ),
      ),
    );
  }
}