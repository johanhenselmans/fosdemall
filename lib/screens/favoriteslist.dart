import 'package:flutter/material.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/widgets/empty_view.dart';
import 'package:fosdem/widgets/event_item.dart';
import 'package:searchable_listview/searchable_listview.dart';
import 'package:fosdem/models/event.dart';

/// Displays a list of Events.
class FavoritesList extends StatefulWidget with ChangeNotifier {
  final SettingsController settingsController;

  FavoritesList({
    super.key,
    required this.settingsController,
  });

  static const routeName = '/favoriteslist';

  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Event>? eventList = [];

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

  Future<List<Event>> getFavoritesList() async {
    List<Event> eventList = await databaseHelper.getFavoritesFromDb(
        int.parse(widget.settingsController.fosdemSelectedYear), widget.settingsController);
    return eventList;
  }

// To work with lists that may contain a large number of items, it’s best
// to use the ListView.builder constructor.
//
// In contrast to the default ListView constructor, which requires
// building all Widgets up front, the ListView.builder constructor lazily
// builds Widgets as they’re scrolled into view.

  Widget showSearchableList(eventList) {
    return SearchableList<Event>.async(
      //initialList: eventList,
      itemBuilder: ( Event aEvent)  {
        return EventItem(settingsController: widget.settingsController, event: aEvent);
      },
      loadingWidget: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(
            height: 20,
          ),
          Text('Loading favorites...')
        ],
      ),asyncListCallback: () async {
        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );
        return eventList;
      },asyncListFilter: (q, aList) {
        return aList
            .where((element) => element.title.contains(q))
            .toList();
      },
//      filter: (value) => eventList
//          .swhere(
//            (element) => element.title.toLowerCase().contains(value),
//          )
//          .toList(),
      onItemSelected: (Event item) {},
      emptyWidget: const EmptyView(),

      inputDecoration: const InputDecoration(
        labelText: "Search Events",
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blue,
            width: 1.0,
          ),
          //borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Event>>(
          future: getFavoritesList(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Event>> snapshot) {
            if (snapshot.hasData) {
              eventList = snapshot.data;
              return showSearchableList(eventList!);
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

