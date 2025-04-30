import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'guest_book_message.dart';

enum Attending { yes, no, unknown }

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  List<GuestBookMessage> _guestBookMessages = [];
  List<GuestBookMessage> get guestBookMessages => _guestBookMessages;

  int _attendees = 0;
  int get attendees => _attendees;

  Attending _attending = Attending.unknown;
  Attending get attending => _attending;

  StreamSubscription<QuerySnapshot>? _guestBookSubscription;
  StreamSubscription<QuerySnapshot>? _attendeesSubscription;
  StreamSubscription<DocumentSnapshot>? _attendingSubscription;

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseUIAuth.configureProviders([EmailAuthProvider()]);

   
    _attendeesSubscription = FirebaseFirestore.instance
        .collection('attendees')
        .where('attending', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      _attendees = snap.docs.length;
      notifyListeners();
    });

  
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;

        
        _guestBookSubscription = FirebaseFirestore.instance
            .collection('guestbook')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          _guestBookMessages = snapshot.docs
              .map((doc) => GuestBookMessage(
                    name: doc.data()['name'] as String,
                    message: doc.data()['text'] as String,
                  ))
              .toList();
          notifyListeners();
        });

       
        _attendingSubscription = FirebaseFirestore.instance
            .collection('attendees')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.data()?['attending'] == true) {
            _attending = Attending.yes;
          } else {
            _attending = Attending.no;
          }
          notifyListeners();
        });
      } else {
     
        _loggedIn = false;
        _guestBookMessages = [];
        _attendeesSubscription?.cancel();
        _guestBookSubscription?.cancel();
        _attendingSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  set attending(Attending newValue) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('attendees')
        .doc(uid)
        .set(<String, dynamic>{'attending': newValue == Attending.yes});
  }

  Future<DocumentReference> addMessageToGuestBook(String message) {
    if (!_loggedIn) throw Exception('Must be logged in');
    return FirebaseFirestore.instance.collection('guestbook').add({
      'text': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'name': FirebaseAuth.instance.currentUser!.displayName,
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  @override
  void dispose() {
    _attendeesSubscription?.cancel();
    _guestBookSubscription?.cancel();
    _attendingSubscription?.cancel();
    super.dispose();
  }
}
