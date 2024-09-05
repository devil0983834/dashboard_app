import 'package:dashboard/consts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import '../widgets/rounded_circular_button.dart';
import '../widgets/rounded_text_form_field.dart';
import '../widgets/navigation.dart';
import './home.dart';
import '../widgets/fun.dart';

String messError = '';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  _LoginPageState();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
      caseSensitive: false, multiLine: false);
  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
      if (_user != null) {
        NavigationPanel(user: _user!);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardHome(user: _user!)),
        );
      }
    });
  }

  void _changeText() {
    setState(() {});
  }

  @override
  void dispose() {
    // Hủy bỏ các TextEditingController khi không sử dụng nữa
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1E2026),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _header(),
          _loginForm(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.25,
      color: const Color(0xFF252F52),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
              "Sign In",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 30,
              ),
            ),
          ),
          Image.asset(
            "assets/images/sign.png",
            width: MediaQuery.of(context).size.width * 0.62,
            fit: BoxFit.fill,
          )
        ],
      ),
    );
  }

  Widget _loginForm() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Container(
        color: Color(0xFF1E2026),
        child: Form(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _formFields(),
                _bottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formFields() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.20,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoundedTextFormField(
            hintText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
          ),
          RoundedTextFormField(
            hintText: "Password",
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            controller: _passwordController,
          ),
          Container(
            child: Text(
              messError,
              style: TextStyle(
                  color: const Color.fromARGB(255, 147, 147, 147),
                  fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.80,
          height: MediaQuery.of(context).size.height * 0.06,
          child: RoundedCircularButton(
            text: "Sign In",
            onPressed: _handleSignIn, // Truyền hàm onPressed
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 30,
          ),
          child: _googleSignUpButton(),
        )
      ],
    );
  }

  Widget _googleSignUpButton() {
    return Center(
      child: SizedBox(
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.blue, width: 1), // Đặt màu và độ rộng của border
            borderRadius: BorderRadius.circular(0), // Bo tròn góc nếu cần
          ),
          width: MediaQuery.of(context).size.width * 0.80,
          child: SignInButton(
            Buttons.googleDark,
            text: "Sign up with Google",
            onPressed: () async {
              User? user = await _handleGoogleSignUp();
              if (user != null) {
                print('User signed in: ${user.displayName}');
                var url = Uri.parse('http://$IP:3000/users');
                var response = await http.post(
                  url,
                  headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode({
                    'email': user.email,
                    'displayName': user.displayName,
                    'phoneNumber': user.phoneNumber,
                    'city': '',
                    'age': '',
                    'code': '',
                    'apiRead': '',
                    'apiWrite': ''
                  }),
                );
                setState(() {
                  _user = user;
                });

                if (response.statusCode == 200) {
                } else {
                  print('Failed to send user data: ${response.statusCode}');
                }
              } else {
                print('User sign in failed');
              }
            },
          ),
        ),
      ),
    );
  }

  Future<User?> _handleGoogleSignUp() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(googleCredential);

      User? user = userCredential.user;

      // Send mail reset password
      if (user != null && userCredential.additionalUserInfo!.isNewUser) {
        // Kiểm tra xem đây có phải là lần đăng nhập đầu tiên không
        final emailCredential = EmailAuthProvider.credential(
          email: user.email!,
          password: generateRandomPassword(length: 12),
        );
        // Liên kết tài khoản Google với email và mật khẩu
        await user.linkWithCredential(emailCredential);
        await _sendPasswordResetEmail(user.email);
        print('Email đặt lại mật khẩu đã được gửi đến ${user.email}');
      }

      return user;
    } catch (e) {
      print('Lỗi khi liên kết tài khoản: $e');
      return null;
    }
  }

  void _handleSignIn() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (!emailRegex.hasMatch(email)) {
      // _showErrorDialog('Invalid email format');
      messError = 'Invalid email format';
      _changeText();
      return;
    }
    if (password.length < 6) {
      messError = 'Password must be at least 6 characters long';
      _changeText();
      return;
    }
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      print("Login successful: ${userCredential.user!.email}");
      // Navigate to another page or show success message
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        messError = 'No user found for that email.';
        _changeText();
        return;
      } else if (e.code == 'wrong-password') {
        messError = 'Wrong password provided.';
        _changeText();
        return;
      } else {
        print('Login failed: $e');
      }
    }
  }

  String generateRandomPassword({int length = 12}) {
    const String characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    Random random = Random();

    return List.generate(
            length, (index) => characters[random.nextInt(characters.length)])
        .join();
  }
}

Future<void> _sendPasswordResetEmail(email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  } catch (e) {
    print('loi $e');
  }
}
