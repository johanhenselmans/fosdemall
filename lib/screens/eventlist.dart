import 'package:flutter/material.dart';
import 'package:fosdem/data/database_helper.dart';

import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/widgets/empty_view.dart';
import 'package:fosdem/widgets/event_item.dart';
import 'package:searchable_listview/searchable_listview.dart';
import 'package:fosdem/models/event.dart';

/// Displays a list of Events.
class EventList extends StatefulWidget {
  final SettingsController settingsController;

  const EventList({
    super.key,
    required this.settingsController,
  });
  static const routeName = '/eventlist';

  @override
  State<EventList> createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Event>? eventList = [];
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = getEventList();
    widget.settingsController.addListener(_handleSettingsChanged);
    databaseHelper.addListener(_handleDbChanged);
  }

  @override
  void dispose() {
    widget.settingsController.removeListener(_handleSettingsChanged);
    databaseHelper.removeListener(_handleDbChanged);
    super.dispose();
  }

  void _handleSettingsChanged() {
    if (mounted) {
      setState(() {
        _eventsFuture = getEventList();
      });
    }
  }

  void _handleDbChanged() {
    if (mounted) {
      setState(() {
        _eventsFuture = getEventList();
      });
    }
  }


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

  Future<List<Event>> getEventList() async {
    List<Event> eventList = [];
    if(widget.settingsController.SelectedTrack != ""){
      eventList = await databaseHelper.getEventsFromDb(
          int.parse(widget.settingsController.fosdemSelectedYear),
          widget.settingsController.selectedNow,
          track: widget.settingsController.SelectedTrack,
          settingsController: widget.settingsController);
    } else {
      eventList = await databaseHelper.getEventsFromDb(
          int.parse(widget.settingsController.fosdemSelectedYear),
          widget.settingsController.selectedNow,
          track: "",
          settingsController: widget.settingsController);
    }
    return eventList;
  }

// To work with lists that may contain a large number of items, it’s best
// to use the ListView.builder constructor.
//
// In contrast to the default ListView constructor, which requires
// building all Widgets up front, the ListView.builder constructor lazily
// builds Widgets as they’re scrolled into view.

  Widget showSearchableList(List<Event> eventList) {
    return SearchableList<Event>.async(
      //initialList: eventList,
      itemBuilder: (Event anEvent) {
        return   EventItem(settingsController: widget.settingsController, event: anEvent);
      },
      loadingWidget: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(
            height: 20,
          ),
          Text('Loading events...')
        ],
      ),asyncListCallback: () async {
        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );
        return eventList;
      }, asyncListFilter: (query, list) async {
        final q = query.toLowerCase();
        return list.where((element) {
          final title = element.title.toLowerCase();
          final track = element.track?.toLowerCase() ?? '';
          final yearStr = element.year?.toString() ?? '';
          final room = element.room?.toLowerCase() ?? '';
          return title.contains(q) ||
              track.contains(q) ||
              yearStr.contains(q) ||
              room.contains(q);
        }).toList();
      },
//      filter: (value) => eventList
//          .swhere(
//            (element) => element.title.toLowerCase().contains(value),
//          )
//          .toList(),
      emptyWidget: const EmptyView(),
      //searchTextController: _controller,

      inputDecoration: const InputDecoration(
        labelText: "Search Events",
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blue,
            width: 1.0,
          ),
          //borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Event>>(
          future: _eventsFuture,
          builder:
              (BuildContext context, AsyncSnapshot<List<Event>> snapshot) {
            if (snapshot.hasData) {
              eventList = snapshot.data;
              return showSearchableList(eventList!);
            } else {
              return const Column(children: <Widget>[
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(),
                ),
              ]);
            }
          }),
    );
  }
}

