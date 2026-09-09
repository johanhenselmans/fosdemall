import 'package:flutter/material.dart';
import 'package:fosdem/models/person.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:fosdem/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

class PersonItem extends StatelessWidget {
  final Person person;
  final SettingsController settingsController;

  const PersonItem({
    super.key,
    required this.person,
    required this.settingsController,
  });

  void goHome(BuildContext context) {
    GoRouter.of(context).pushReplacement('/');
  }

  void goToPerson(BuildContext context, Person aPerson) {
    settingsController.updateSelectedPerson(aPerson);
    GoRouter.of(context).push('/personview');
  }

  @override
  Widget build(BuildContext context) {
    final hasPicture = person.picture != null && person.picture!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SimpleGestureDetector(
        onTap: () {
          goToPerson(context, person);
        },
        onHorizontalSwipe: (SwipeDirection direction) {
          if (direction == SwipeDirection.right) {
            goHome(context);
          } else {
            goToPerson(context, person);
          }
        },
        swipeConfig: const SimpleSwipeConfig(
          verticalThreshold: 40.0,
          horizontalThreshold: 40.0,
          swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: fosdemBlue.withAlpha(50),
                backgroundImage: hasPicture ? MemoryImage(person.picture!) : null,
                onBackgroundImageError: hasPicture ? (exception, stackTrace) {} : null,
                child: !hasPicture
                    ? const Icon(Icons.person, size: 30, color: fosdemBlue)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name ?? 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (person.description != null &&
                        person.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        person.description!.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
