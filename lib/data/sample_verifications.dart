import '../models/verification.dart';

// Each quest has an activity-specific evidence prompt. New generated quests
// can supply the same simple Verification object in the Quest constructor.
Verification sampleVerification(int id) {
  const movement = {
    1: 100.0,
    3: 100.0,
    6: 150.0,
    14: 100.0,
    17: 100.0,
    18: 250.0,
    22: 150.0,
    23: 200.0,
    24: 150.0,
  };
  if (movement.containsKey(id)) {
    final route = {1, 14, 18, 23, 24}.contains(id);
    return Verification(
      method: VerificationMethod.location,
      minimumDistance: movement[id]!,
      tracksRoute: route,
      prompt: route
          ? 'Track at least ${movement[id]!.round()} m of walking or running, then finish tracking. Keep this task open.'
          : 'Save your starting location, then check in again after your activity at least ${movement[id]!.round()} m away.',
    );
  }
  const photos = {
    2: 'Attach the interesting photograph you took.',
    3: 'Share a photo of something you noticed in the park.',
    5: 'Attach a photo of the dish you made.',
    7: 'Attach a photo of your sketch.',
    10: 'Attach a photo of the sunset you watched.',
    12: 'Attach a photo of your finished recipe.',
    13: 'Share the detail in nature you photographed.',
    15: 'Attach a photo of the dish you prepared from another culture.',
    16: 'Attach a photo of the sunrise you watched.',
    19: 'Attach a photo of what you created.',
    20: 'Share a photo of your experiment with a new art medium.',
    25: 'Attach a photo of the new ingredient or the dish you used it in.',
    26: 'Attach a photo or collage showing the patterns you found in nature.',
  };
  const reflections = {
    4: 'What did you learn, and what surprised you?',
    6: 'Where did your detour take you? Describe something new you noticed.',
    8: 'What did you read? Share one idea that stayed with you.',
    17: 'Describe the three plants or birds you identified.',
    18: 'Describe your outdoor adventure and a moment you enjoyed.',
    21: 'Share three things you learned about your topic.',
    22: 'Where did you go, and what made this place new to you?',
    23: 'Describe the outdoor route you explored and what you discovered.',
  };
  const checklists = {
    1: [
      'I spent at least 20 minutes walking outside.',
      'I noticed something in my surroundings.',
    ],
    9: [
      'I spent 10 minutes stretching and moving.',
      'I took a moment to notice how I felt afterward.',
    ],
    11: [
      'I started my day earlier than usual.',
      'I used the extra time for something intentional.',
    ],
    14: [
      'I went for a morning walk.',
      'I completed a short stretching session.',
    ],
    24: [
      'I completed a gentle workout outdoors.',
      'I moved at a pace that felt comfortable for me.',
    ],
  };
  if (photos.containsKey(id)) {
    return Verification(method: VerificationMethod.photo, prompt: photos[id]!);
  }
  if (reflections.containsKey(id)) {
    return Verification(
      method: VerificationMethod.reflection,
      prompt: reflections[id]!,
    );
  }
  if (checklists.containsKey(id)) {
    return Verification(
      method: VerificationMethod.checklist,
      prompt: 'Check off what you experienced.',
      steps: checklists[id]!,
    );
  }
  throw ArgumentError('Missing verification for sample quest $id');
}
