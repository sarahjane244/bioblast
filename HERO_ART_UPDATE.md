# BioBlast Hero Artwork Update

The four science-themed characters from the approved BioBlast concept art replace the old code-painted hero faces.

- Mito the Mighty — mitochondria-themed superhero.
- Gluco the Genius — glucose-themed scientist.
- Oxy the Observer — oxygen-themed explorer.
- ATP the Lucky — ATP-themed energy mascot.

The art is stored in `assets/images/heroes/`. `lib/play.dart` provides the shared `HeroAvatar` component and four full-body hero assets for the Choose Your Hero cards. Small avatar artwork appears in the profile, game rounds, results and shop.

Existing powers, stored hero indexes, student/teacher features, Cell Cafe and sync code are preserved. All sessions use the same four names and artwork; their powers are unchanged.

To test in Android Studio: `flutter pub get`, then run `main.dart` on your Android emulator. To see the new artwork, enter Play and open Choose Your Hero.

**Note:** Art has been integrated into source; the full Flutter Android build has not been tested here.
