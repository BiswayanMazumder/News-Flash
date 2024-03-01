import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:stockine/main.dart';
class NavBar extends StatefulWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final _pageController = PageController(initialPage: 0);
  int _index = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  final List screens=[
    MyApp()
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      backgroundColor: Colors.black,

      bottomNavigationBar: GNav(
          haptic: true,
          curve: Curves.bounceInOut,
          rippleColor: Colors.yellow,
          tabActiveBorder: Border.all(color: Colors.green,
              style: BorderStyle.solid),
          hoverColor: Colors.white,
          activeColor: Colors.black,
          color: Colors.deepPurpleAccent,
          // rippleColor: Colors.green,
          tabBackgroundColor: Colors.green,
          selectedIndex: _index,
          // tabBorder: Border.all(color: Colors.red),
          gap: 1,
          onTabChange: (value){
            setState(() {
              _index=value;
            });
          },
          tabs: [
            GButton(icon: Icons.home,
              backgroundGradient: LinearGradient(colors: [Colors.yellow,Colors.red]),
              rippleColor: Colors.green,
              backgroundColor: Colors.red,
            ),
            GButton(icon: Icons.add_box_outlined,
              backgroundGradient: LinearGradient(colors: [Colors.blueAccent,Colors.red]),
              backgroundColor: Colors.lightGreenAccent,
            ),
            GButton(icon: Icons.subscriptions,
              backgroundGradient: LinearGradient(colors: [Colors.white,Colors.pink]),
              backgroundColor: Colors.pink,
            ),
            GButton(icon: Icons.person,
              backgroundGradient: LinearGradient(colors: [Colors.orange,Colors.blue]),
              backgroundColor: Colors.blue,
              haptic: true,
              debug: true,
            ),
          ]
      ),
    );
  }
}
