import 'package:flutter/material.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

class EventItem extends StatelessWidget {
  final Event event;
  final SettingsController settingsController;

  const EventItem({
    super.key,
    required this.event,
    required this.settingsController,
  });

  goHome(BuildContext context) {
    GoRouter.of(context).pushReplacement('/');
  }

  goToEvent(context, Event anEvent) {
    settingsController.updateSelectedEvent(anEvent);
      GoRouter.of(context).push('/eventview');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SimpleGestureDetector(
        onTap: () {
          goToEvent(context, event);
        },
        onHorizontalSwipe: (SwipeDirection direction) {
          if (direction == SwipeDirection.right) {
            goHome(context);
          } else {
            goToEvent(context, event);
          }
        },
        swipeConfig: const SimpleSwipeConfig(
          verticalThreshold: 40.0,
          horizontalThreshold: 40.0,
          swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
        ),
        child: Container(
          //height: 60,
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
                    //makeitUTF8Bold(event.title),
                  Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Where: ${event.room}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${event.eventdate} ${event.start}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                    Text(
                      'Track: ${event.track}',
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Type: ${event.type ?? ''}',
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
