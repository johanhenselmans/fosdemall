import 'package:flutter/material.dart';
import 'package:fosdem/utils/utils.dart';
import 'package:go_router/go_router.dart';

import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/models/conference.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

/// Displays a list of SampleItems.
class ConferenceList extends StatelessWidget with ChangeNotifier {
  ConferenceList({super.key, required this.settingsController, required});

  static const routeName = '/conferencelist';
  final SettingsController? settingsController;
  final DatabaseHelper databaseHelper = DatabaseHelper();

  void _displayAlert(String aText, BuildContext context) {
    var alert = AlertDialog(
      title: const Text("Error"),
      content: Text(aText),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
  }

  Future<List<Conference>> getConferenceList() async {
    List<Conference> conferenceList =
        await databaseHelper.getConferencesFromDb();
    return conferenceList;
  }

// To work with lists that may contain a large number of items, it’s best
// to use the ListView.builder constructor.
//
// In contrast to the default ListView constructor, which requires
// building all Widgets up front, the ListView.builder constructor lazily
// builds Widgets as they’re scrolled into view.
  List<Conference>? conferenceList = [];

  goHome(BuildContext context) {
    GoRouter.of(context).pushReplacement('/');
  }

  goToEventList(context, int? year) {
    settingsController?.updateSelectedYear(year.toString());
    settingsController?.updateSelectedTrack('');
    GoRouter.of(context).pushReplacement('/eventlist');
  }

//void _handleSettingsChanged()  {
//}

  @override
  Widget build(BuildContext context) {
    databaseHelper.addListener(getConferenceList);
//databaseHelper.addListener(_handleSettingsChanged);
    return SafeArea(
      child: FutureBuilder<List<Conference>>(
          future: getConferenceList(),
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
/*                                    Text('org: ${conferenceList![index].venue!}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        )),
*/
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
