import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'colors.dart';
import 'map_screen.dart';
import 'about_screen.dart';
import 'profile_screen.dart';
import 'public_space_properties.dart';
import 'user_provider.dart';
import 'username_input_screen.dart';

Future<void> initDynamicLinks(BuildContext context) async {
  print('Initializing dynamic links...');

  // Check for initial dynamic link
  final PendingDynamicLinkData? initialLink =
      await FirebaseDynamicLinks.instance.getInitialLink();

  if (initialLink?.link != null) {
    await _handleDynamicLink(initialLink!.link!, context);
  }

  // Listen for dynamic link while app is in the foreground
  FirebaseDynamicLinks.instance.onLink.listen(
    (PendingDynamicLinkData? dynamicLinkData) async {
      final Uri? deepLink = dynamicLinkData?.link;
      if (deepLink != null) {
        await _handleDynamicLink(deepLink, context);
      }
    },
    onError: (error) {
      print('Error processing dynamic link: $error');
    },
  );
}

Future<void> _handleDynamicLink(Uri deepLink, BuildContext context) async {
  print('Dynamic link received: $deepLink');

  if (FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString())) {
    try {
      // Retrieve the email from shared_preferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('sign_in_email');
      if (email == null) {
        throw Exception("No email found in local storage");
      }

      // Sign in the user
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailLink(
        email: email,
        emailLink: deepLink.toString(),
      );

      // Delete the email from shared_preferences
      await prefs.remove('sign_in_email');

      final String? emailAddress = userCredential.user?.email;

      print('Successfully signed in with email link!');
      print('Email Address: $emailAddress');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed in!')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);

      homeScreenKey.currentState?.switchToMapTab();
    } catch (error) {
      print('Error signing in with email link: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'We could not sign you in with that link. Try again.')),
      );
    }
  } else {
    print('Dynamic link received, but it is not a valid email sign-in link.');
  }
}

void main() {
  // ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // read the mapbox access token from environment variable
  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(accessToken);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional: allow upside-down portrait
  ]).then((_) async {
    // debugPaintSizeEnabled = true; // For debugging purposes

    await Firebase.initializeApp();
    firestore.FirebaseFirestore.instance.settings =
        const firestore.Settings(persistenceEnabled: false);
    runApp(
      ChangeNotifierProvider(
        create: (context) {
          final userProvider = UserProvider();
          userProvider.initializeAuth(context); // Initialize auth
          return userProvider;
        },
        child: const MyApp(),
      ),
    );
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Bottom Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: AppColors.gray), // Label text color
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: AppColors.green, width: 2.0), // Focused border color
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: AppColors.gray, width: 1.0), // Enabled border color
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.dark, // Set the cursor color globally
        ),
      ),
      home: HomeScreen(key: homeScreenKey),
      routes: {
        '/username_input': (context) => UsernameInputScreen(
              onUsernameCreated: (newUsername) {
                userProvider.setUsernameLocally(newUsername);
              },
            ),
      },
    );
  }
}

final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PublicSpaceFeature? _selectedFeature;

  int _selectedIndex = 0;

  // List of pages for the navigation
  static late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize dynamic links handling
    initDynamicLinks(context);

    // Initialize the list of pages with the feedback tap handler
    _pages = <Widget>[
      MapScreen(onReportAnIssue: _handleReportAnIssue),
      const AboutScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleFeedbackTap() {
    // Open the drawer using the scaffold key
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleReportAnIssue(selectedFeature) {
    // Open the drawer using the scaffold key
    _scaffoldKey.currentState?.openDrawer();
    setState(() {
      _selectedFeature = selectedFeature;
    });
  }

  void switchToMapTab() {
    print('switching to map tab');
    setState(() {
      _selectedIndex = 0; // Index of the Profile tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey, // Attach the key to the Scaffold
        // drawer: SideDrawer(
        //   selectedFeature: _selectedFeature,
        // ),
        body: IndexedStack(
          index: _selectedIndex, // Display the selected tab
          children: _pages, // Keep all pages mounted
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the BottomNavigationBar
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade300, // Subtle gray border
                width: 0.5, // Thickness of the border
              ),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                      top: 8.0, bottom: 4.0), // Add padding above the icon
                  child: Icon(FontAwesomeIcons.map),
                ),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                      top: 8.0, bottom: 4.0), // Add padding above the icon
                  child: Icon(FontAwesomeIcons.infoCircle),
                ),
                label: 'About',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                      top: 8.0, bottom: 4.0), // Add padding above the icon
                  child: Icon(FontAwesomeIcons.user),
                ),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.dark,
            selectedLabelStyle:
                const TextStyle(fontSize: 10), // Adjust font size
            unselectedItemColor: AppColors.gray,
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            iconSize: 20, // Set the desired size for the icons
            onTap: _onItemTapped,
          ),
        ));
  }
}
