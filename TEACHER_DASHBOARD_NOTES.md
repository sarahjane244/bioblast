# BioBlast Teacher Dashboard — local prototype

- Open the app and use the **OPEN TEACHER DASHBOARD (LOCAL PREVIEW)** button on the student registration screen.
- Shows student profiles saved in this same app installation, their progress across eight lessons, and stored game results.
- Game score recording starts after students finish new games in this version. Earlier attempts have no stored scores.
- Student progress remains offline on each device. A remote teacher phone will NOT see another student's phone data without a proper authenticated sync backend.
- Teacher dashboard access is a prototype only and is NOT password protected. Do not use for real deployment with student information until teacher authentication and data access controls are added.
- To test: `flutter pub get`, then `flutter run -d edge` or connect an Android device.
