import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, PhoneAuthProvider;
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'guest_book.dart';
import 'yes_no_selection.dart';       
import 'src/authentication.dart';
import 'src/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Meetup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
         Image.asset('assets/codelab.png'),
          const SizedBox(height: 8),
          const IconAndDetail(Icons.calendar_today, 'October 30'),
          const IconAndDetail(Icons.location_city, 'San Francisco'),
          Consumer<ApplicationState>(
            builder: (context, appState, _) => AuthFunc(
              loggedIn: appState.loggedIn,
              signOut: () => FirebaseAuth.instance.signOut(),
            ),
          ),
          const Divider(thickness: 1, color: Colors.grey),
          const Header("What we'll be doing"),
          const Paragraph('Join us for a day full of Firebase Workshops and Pizza!'),
          Consumer<ApplicationState>(
            builder: (context, appState, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appState.attendees >= 2)
                  Paragraph('${appState.attendees} people going')
                else if (appState.attendees == 1)
                  const Paragraph('1 person going')
                else
                  const Paragraph('No one going'),
                if (appState.loggedIn) ...[
                  YesNoSelection(            
                    state: appState.attending,
                    onSelection: (att) => appState.attending = att,
                  ),
                  const Header('Discussion'),
                  GuestBook(
                    addMessage: (msg) => appState.addMessageToGuestBook(msg),
                    messages: appState.guestBookMessages,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
