import 'package:flutter/material.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/models/person.dart';
import 'package:fosdem/utils/constants.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:fosdem/widgets/event_item.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

class PersonView extends StatefulWidget {
  final Person? person;
  final int? personId;
  final SettingsController controller;

  const PersonView({
    super.key,
    this.person,
    this.personId,
    required this.controller,
  });

  static const routeName = '/personview';

  @override
  State<PersonView> createState() => _PersonViewState();
}

class _PersonViewState extends State<PersonView> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Person? _person;
  List<Event> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonData();
  }

  Future<void> _loadPersonData() async {
    Person? p = widget.person ?? widget.controller.selectedPerson;
    int? pid = p?.id ?? widget.personId;
    String? name = p?.name;

    final dbPerson = await _databaseHelper.getPersonById(pid ?? 0, personName: name);
    if (dbPerson != null) {
      p = dbPerson;
    }

    if (p != null) {
      _events = await _databaseHelper.getEventsForPerson(
        p.id ?? pid ?? 0,
        personName: p.name ?? name,
        allYears: true,
      );
    }

    if (mounted) {
      setState(() {
        _person = p;
        _loading = false;
      });
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go('/eventlist');
    }
  }

  Widget _buildPhotoWidget() {
    if (_person?.picture != null && _person!.picture!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipOval(
          child: Image.memory(
            _person!.picture!,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: 70,
      backgroundColor: fosdemBlue.withOpacity(0.15),
      child: const Icon(
        Icons.person,
        size: 80,
        color: fosdemBlue,
      ),
    );
  }

  Widget _buildDescriptionWidget() {
    final desc = _person?.description?.trim() ?? '';
    if (desc.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "No speaker biography available.",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Split biography by "Original description:" if historical entries exist
    final parts = desc.split(RegExp(r'\n\n(?=Original description:)'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        final isHistory = part.startsWith('Original description:');
        if (isHistory) {
          final lines = part.split('\n');
          final header = lines.first;
          final body = lines.skip(1).join('\n').trim();

          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      header,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(height: 1.4, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            part,
            style: const TextStyle(height: 1.45, fontSize: 15),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SimpleGestureDetector(
          onHorizontalSwipe: (SwipeDirection direction) {
            if (direction == SwipeDirection.right) {
              _goBack();
            }
          },
          swipeConfig: const SimpleSwipeConfig(
            verticalThreshold: 40.0,
            horizontalThreshold: 40.0,
            swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: fosdemElevatedButtonStyle,
                          onPressed: _goBack,
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_back_outlined, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                "Back",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: fosdemColorButtonTekst),
                              ),
                            ],
                          ),
                        ),
                        if (_person?.asciiName != null && _person!.asciiName!.isNotEmpty)
                          Chip(
                            label: Text(
                              _person!.asciiName!,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            backgroundColor: Colors.grey[200],
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(child: _buildPhotoWidget()),
                    const SizedBox(height: 16),
                    Text(
                      _person?.name ?? 'Speaker',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Biography",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: fosdemBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDescriptionWidget(),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Icon(Icons.event, color: fosdemBlue),
                        const SizedBox(width: 8),
                        Text(
                          "Events by this Speaker (${_events.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: fosdemBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: const Text(
                          "No events found for this speaker.",
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return EventItem(
                            settingsController: widget.controller,
                            event: event,
                          );
                        },
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
