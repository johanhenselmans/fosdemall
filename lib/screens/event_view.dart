
import 'package:flutter/material.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/models/person.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:fosdem/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fosdem/utils/constants.dart';
/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
//class SettingsView extends StatelessWidget {

class EventView extends StatefulWidget with ChangeNotifier {
  SettingsController controller;
  Event event;

  EventView({super.key, required this.controller, required this.event});
  static const routeName = 'eventview';

  @override
  _EventViewState createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  String currentYear = "";
  String selectedYear = "";
  bool enabled = true;
  DatabaseHelper databaseHelper = DatabaseHelper();
  final List<bool> _selections = [false, false];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleSettingsChanged);
    selectedYear = widget.controller.fosdemSelectedYear;
    if(widget.event.favorite == 1){
      _selections[1]=true;
      _selections[0]=false;
    } else {
      _selections[1]=false;
      _selections[0]=true;

    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSettingsChanged);
    //widget.controller.removeListener(_handleFosdemChanged);
    super.dispose();
  }

  void _handleSettingsChanged() {
    if (widget.controller.fosdemCurrentYear != "") {
      currentYear = widget.controller.fosdemCurrentYear;
      selectedYear = widget.controller.fosdemSelectedYear;
      setState(() {});
    }
  }

/*
  void _handleFosdemChanged() {
    ServerAddress? anAddress;
    anAddress = fosdemServers.getCurrentFosdem();
    //fosdemServers.getCurrentFosdem().then((value) => anAddress = value);
    if (!anAddress.serverIP!.isEmpty) {
      if (this.mounted) {
        setState(() {
          serverName = anAddress?.serverName;
          serverIP = anAddress?.serverIP;
        });
      }
    }
  }
*/
  Future<PackageInfo> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }

  void _gohome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go('/eventlist');
    }
  }

  List getLinkList() {
    final List linklist = widget.event.links;
    return linklist;
  }

  Widget getVideo() {
    final List linklist = widget.event.links;
    for (Map item in linklist) {
      if (item['href'].toString().contains('video.fosdem')) {}
    }
    return Container();
  }

  List getPersonList() {
    final List personlist = widget.event.persons;
    return personlist;
  }

  Future<void> _goToPerson(Map item) async {
    int? id;
    if (item['id'] != null) {
      id = int.tryParse(item['id'].toString());
    }
    String? name = item[r'$t']?.toString();
    Person? person;
    if (name != null && name.trim().isNotEmpty) {
      person = await databaseHelper.getPersonById(id ?? 0, personName: name.trim());
    } else if (id != null) {
      person = await databaseHelper.getPersonById(id);
    }
    person ??= Person(
      id,
      name ?? '',
    );
    widget.controller.updateSelectedPerson(person);
    if (mounted) {
      GoRouter.of(context).push('/personview');
    }
  }

  List getAttachmentList() {
    final List attachmentlist = widget.event.attachments;
    return attachmentlist;
  }

  Future<void> _launchUrl(String anUrl) async {
    if (anUrl.contains('video')) {
      widget.controller.updateSelectedVideo(anUrl);
      GoRouter.of(context).push('/viewvideo');
      // GoRouter.of(context).go('/viewvideo');
    } else {
      if (!await launchUrl(Uri.parse(anUrl))) {
        throw Exception('Could not launch $anUrl');
      }
    }
  }

  Widget itemContents(Map item){
    if (item['type'] != null ) {
      return Text("${item['\$t']} (${item['type']})",
        style: const TextStyle(color: fosdemColorButtonTekst));
  } else {
    return Text("${item['\$t']}",
    style: const TextStyle(color: fosdemColorButtonTekst));
    }
  }


  void _goToLocation() {
    widget.controller.updateSelectedEvent(widget.event);
    GoRouter.of(context).push('/locationview');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SimpleGestureDetector(
          onHorizontalSwipe: (SwipeDirection direction) {
            if (direction == SwipeDirection.right) {
              _gohome();
            }
          },
          swipeConfig: const SimpleSwipeConfig(
            verticalThreshold: 40.0,
            horizontalThreshold: 40.0,
            swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
          ),
//          child: Container(
//            padding: const EdgeInsets.all(24),
            child:
          Column(children:[
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            ElevatedButton(
            style: fosdemElevatedButtonStyle,
            child: const Row(
              children: [
                Icon(Icons.arrow_back_outlined, color: Colors.white),
                Text(
                  "Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fosdemColorButtonTekst),
                ),
              ],
            ),
            onPressed: () => _gohome(),
          ),
            Center(child: ToggleButtons(

                onPressed: (int index) {
                  widget.event.favorite = index;
                  databaseHelper.updateEvent(widget.event);
                  var snackBar = const SnackBar(content: Text(""),);
                  if (index == 1) {
                    snackBar = SnackBar(
                    content: Text('Added "${widget.event
                        .title}" to favorites'),
                    duration: const Duration(seconds: 2));
                      } else {
                  snackBar = SnackBar(
                  content: Text('Removed "${widget.event
                      .title}" from favorites'),
                    duration: const Duration(seconds: 2));
                  }
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  //
                  //  displayAlert("Added", "Added ${widget.event
                  //      .title} to favorites", context);
                  setState(() {
                    // The button that is tapped is set to true, and the others to false.
                    for (int i = 0; i < _selections.length; i++) {
                      _selections[i] = i == index;
                    }
                  });
                },
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: fosdemBlue,
                selectedColor: Colors.white,
                fillColor: fosdemBlue,
                color: fosdemBlue,
                isSelected: _selections,
                children: const <Widget>[
                  Icon(Icons.thumbs_up_down),
                  Icon(Icons.thumb_up),
                ]),
            ),
          ]),

          Expanded(child:
          ListView(
            //padding: const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 38),
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${widget.event.eventdate} ${widget.event.start}",
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Where: ${widget.event.room}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (widget.event.room != null &&
                        widget.event.room!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton.icon(
                          style: fosdemElevatedButtonStyle,
                          icon: const Icon(Icons.location_on_outlined,
                              color: Colors.white, size: 18),
                          label: const Text(
                            "Show The Location",
                            style: TextStyle(
                                color: fosdemColorButtonTekst, fontSize: 13),
                          ),
                          onPressed: () => _goToLocation(),
                        ),
                      ),
                  ]),

              const SizedBox(
                height: 20,
              ),
              Text(widget.event.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 20,
              ),
              Text(
                '${widget.event.track}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(widget.event.subtitle ?? '', textAlign: TextAlign.center),
//Text("${widget.event.persons} ", textAlign: TextAlign.center),


              ListView.builder(
                  itemCount: getPersonList().length,
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final item = getPersonList()[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Center(
                        child: ActionChip(
                          avatar: const CircleAvatar(
                            backgroundColor: fosdemBlue,
                            child: Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                          label: Text(cleanPersonName(item[r'$t'])),
                          onPressed: () => _goToPerson(item),
                        ),
                      ),
                    );
                  }),
              checkHTMLContent(widget.event.abstract),
              checkHTMLContent(widget.event.description),

              //Text("${widget.event.links}", textAlign: TextAlign.center),
              ListView.builder(
                  itemCount: getLinkList().length,
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final item = getLinkList()[index];
                    return Column(children: [
                      ElevatedButton(
                        onPressed: () {
                          _launchUrl(item['href']);
                        },
                        style: fosdemElevatedButtonStyle,
                        child: Text("${item['\$t']}", style: const TextStyle(color: fosdemColorButtonTekst),),
                      )
                      //Text("${item['href']}"),
                      //Text("${item['\$t']}"),
                    ]);
                  }),
              //Text("${widget.event.attachments} ", textAlign: TextAlign.center),
              ListView.builder(
                  itemCount: getAttachmentList().length,
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final item = getLinkList()[index];
                    return Column(children: [
                      ElevatedButton(
                        style: fosdemElevatedButtonStyle,
                        onPressed: () {
                          _launchUrl(item['href']);
                        },
                        child: itemContents(item),
//                        child: Text("${item['\$t']} (${item['type']})", style: TextStyle(color: fosdemColorButtonTekst),),
//                        child: Text("${item['\$t']}", style: TextStyle(color: fosdemColorButtonTekst),),
                      ),
                      //Text("${item['type']}"),
                      //Text("${item['href']}"),
                      //Text("${item['\$t']}"),
                    ]);
                  }),
            ],
          ),
          )
        ]),

      )

//    ),
    ),
    );
  }
}
