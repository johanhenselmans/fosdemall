import 'package:flutter/material.dart';
import 'package:fosdem/utils/utils.dart';
import 'package:go_router/go_router.dart';

import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/models/conference.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

/// Displays a list of Conferences.
class ConferenceList extends StatefulWidget {
  const ConferenceList({super.key, required this.settingsController});

  static const routeName = '/conferencelist';
  final SettingsController? settingsController;

  @override
  State<ConferenceList> createState() => _ConferenceListState();
}

class _ConferenceListState extends State<ConferenceList> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  List<Conference>? conferenceList = [];
  late Future<List<Conference>> _conferenceFuture;

  @override
  void initState() {
    super.initState();
    _conferenceFuture = databaseHelper.getConferencesFromDb();
    databaseHelper.addListener(_handleDatabaseChanged);
  }

  @override
  void dispose() {
    databaseHelper.removeListener(_handleDatabaseChanged);
    super.dispose();
  }

  void _handleDatabaseChanged() {
    if (mounted) {
      setState(() {
        _conferenceFuture = databaseHelper.getConferencesFromDb();
      });
    }
  }

  void goHome(BuildContext context) {
    GoRouter.of(context).pushReplacement('/');
  }

  void goToEventList(BuildContext context, int? year) {
    widget.settingsController?.updateSelectedYear(year.toString());
    widget.settingsController?.updateSelectedTrack('');
    GoRouter.of(context).pushReplacement('/eventlist');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Conference>>(
          future: _conferenceFuture,
          builder:
              (BuildContext context, AsyncSnapshot<List<Conference>> snapshot) {
            if (snapshot.hasData) {
              conferenceList = snapshot.data;
              return ListView.builder(
                  itemCount: conferenceList!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SimpleGestureDetector(
                      onTap: () {
                        goToEventList(context, conferenceList![index].year);
                      },
                      onHorizontalSwipe: (SwipeDirection direction) {
                        if (direction == SwipeDirection.right) {
                          goHome(context);
                        } else {
                          goToEventList(context, conferenceList![index].year);
                        }
                      },
                      swipeConfig: const SimpleSwipeConfig(
                        verticalThreshold: 40.0,
                        horizontalThreshold: 40.0,
                        swipeDetectionBehavior:
                            SwipeDetectionBehavior.continuousDistinct,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            replaceLatin1(conferenceList![index].title),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${conferenceList![index].start} ${conferenceList![index].end}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ]),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const Text('Where: ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              )),
                                          makeitUTF8(
                                              conferenceList![index].venue!),
                                        ]),
                                      Text(
                                      'City: ${conferenceList![index].city}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
            } else {
              return const Column(children: <Widget>[
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
              ]);
            }
          }),
    );
  }
}
