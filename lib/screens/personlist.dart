import 'package:flutter/material.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/models/person.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/widgets/empty_view.dart';
import 'package:fosdem/widgets/person_item.dart';
import 'package:searchable_listview/searchable_listview.dart';

/// Displays a list of Persons.
class PersonList extends StatefulWidget {
  final SettingsController settingsController;

  const PersonList({
    super.key,
    required this.settingsController,
  });

  static const routeName = '/personlist';

  @override
  State<PersonList> createState() => _PersonListState();
}

class _PersonListState extends State<PersonList> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  List<Person>? personList = [];

  @override
  void initState() {
    super.initState();
    widget.settingsController.addListener(_handleSettingsChanged);
  }

  @override
  void dispose() {
    widget.settingsController.removeListener(_handleSettingsChanged);
    super.dispose();
  }

  void _handleSettingsChanged() {
    setState(() {});
  }

  Future<List<Person>> getPersonsList() async {
    final year = int.tryParse(widget.settingsController.fosdemSelectedYear) ?? 2025;
    final list = await databaseHelper.getPersonsFromDb(
      year,
      widget.settingsController,
    );
    return list;
  }

  Widget showSearchableList(List<Person> persons) {
    return SearchableList<Person>.async(
      itemBuilder: (Person aPerson) {
        return PersonItem(
          settingsController: widget.settingsController,
          person: aPerson,
        );
      },
      loadingWidget: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Loading persons...'),
        ],
      ),
      asyncListCallback: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return persons;
      },
      asyncListFilter: (q, aList) async {
        final query = q.toLowerCase();
        return aList.where((element) {
          final name = element.name?.toLowerCase() ?? '';
          final ascii = element.asciiName?.toLowerCase() ?? '';
          return name.contains(query) || ascii.contains(query);
        }).toList();
      },
      emptyWidget: const EmptyView(),
      inputDecoration: const InputDecoration(
        labelText: "Search Persons",
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blue,
            width: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Person>>(
        future: getPersonsList(),
        builder: (BuildContext context, AsyncSnapshot<List<Person>> snapshot) {
          if (snapshot.hasData) {
            personList = snapshot.data;
            return showSearchableList(personList!);
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading persons: ${snapshot.error}'),
            );
          } else {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
