import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:retrieva/screens/browse_screen.dart';
import 'package:retrieva/screens/chat_list_screen.dart';
import 'package:retrieva/screens/chat_screen.dart';
import 'package:retrieva/screens/map_screen.dart';
import 'package:retrieva/screens/post_item_screen.dart';
import '../../screens/home_screen.dart';

import '../theme/app_theme.dart';


class MainScreen extends StatefulWidget {
 const  MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Widget _getScreen(int index){
    switch(index){
      case 0:
        return HomeScreen();
      case 1:
        return ChatsListScreen();
      case 2:
        return PostItemScreen();
      case 3:
        return BrowseScreen();
      case 4:
        return  MapScreen();
        default:
         return HomeScreen();

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_currentIndex),

      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor:AppColors.teal,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        items:  const [
         BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label:  ''
          ),
        BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label:  ''
          ),
          BottomNavigationBarItem(
            icon:
                SizedBox.shrink() ,
              label:  ''


          ),
         BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label:  ''
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
          label:  ''
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _currentIndex = 2),
        backgroundColor: AppColors.teal,
        child:  Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
