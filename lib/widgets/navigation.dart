import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/my_home.dart';
import '../pages/setting.dart';
import '../pages/about.dart';
import '../pages/home.dart';
import '../pages/login_page.dart';

class NavigationPanel extends StatefulWidget {
  final User user;

  const NavigationPanel({Key? key, required this.user}) : super(key: key);
  @override
  _NavigationPanel createState() => _NavigationPanel();
}

class _NavigationPanel extends State<NavigationPanel> {
  @override
  Widget build(BuildContext context) {
    final HeightScreen = MediaQuery.of(context).size.height;
    final WidthScreen = MediaQuery.of(context).size.width;
    return Container(
      width: 200,
      height: HeightScreen,
      color: Colors.black54,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          UserHeader(),
          NavigationItem(
              icon: Icons.cloud,
              label: 'Weather',
              page: DashboardHome(
                user: FirebaseAuth.instance.currentUser!,
              )),
          NavigationItem(icon: Icons.eco, label: 'My Home', page: MyHome()),
          Spacer(),
          NavigationItem(
              icon: Icons.settings,
              label: 'Settings',
              page: SettingPage(
                user: FirebaseAuth.instance.currentUser!,
              )),
          NavigationItem(
              icon: Icons.info_outline,
              label: 'About',
              page: DisplayDataScreen()),
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 26.0,
            ),
            leading: Icon(Icons.logout, color: Colors.white),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          SizedBox(
            height: 0,
          )
        ],
      ),
    );
  }
}

// class NavigationItem extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   NavigationItem({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.white),
//       title: Text(label, style: TextStyle(color: Colors.white)),
//     );
//   }
// }

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget page;

  NavigationItem({required this.icon, required this.label, required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            // Chuyển hướng sang trang thứ hai
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 20),
              Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 18),
              )
            ],
          ),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.black54),
            overlayColor: MaterialStateProperty.all(Color(0xFF252F52)),
            minimumSize: MaterialStateProperty.all(const Size(200, 45)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Image.asset(
            "assets/images/icon.jpg",
            height: 100,
            width: 200,
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}
