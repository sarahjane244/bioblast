# Teacher login (local demo only)

Open **TEACHER LOGIN** on the initial role screen. On first use, create a local preview profile with teacher email and an 8+ character password. On later launches, sign in with the same credentials. Use **Sign out** to return to teacher login. Students no longer have a teacher dashboard button on registration.

**Security limitation:** This is only a UI/prototype gate. `shared_preferences` stores the password hash and salt locally and can be modified by someone with device/browser storage access. The first user of the device could set up the preview profile. **Do not use for real student data.** Production requires server-verified teacher login and teacher-only authorization rules on a hosted database.

**Sync limitation:** The teacher dashboard still displays only profiles and progress saved on this same installation. Student devices cannot sync to it yet. A cloud database, offline queue, and synchronization API remain to be developed.

This project ZIP includes source and assets only. Open the `bioblast` folder in an existing valid Flutter project or run `flutter create .` within this folder to generate platform files. Then run `flutter pub get` and `flutter run -d edge`.
