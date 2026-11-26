# BioBlast — Phase 2: online sync proof of concept

**This is a local-network prototype, not a production student-record service.** The Flutter application still works offline. The new cloud-sync feature sends students' complete eight-lesson snapshots after the student joins a class. The teacher can read synchronized records from their own device with separate server credentials. The server must be running and reachable. The Teacher Dashboard now reads the server directly after one teacher sign-in when BIOBLAST_API_URL is configured. Without that URL it remains a local-only preview.

## 1. Start the demo backend on a computer with Node.js 18+

Open PowerShell in the `bioblast/server` folder and set your own **new** private values (do not commit them to Git):

```powershell
$env:TEACHER_EMAIL="teacher@example.com"
$env:TEACHER_PASSWORD="REPLACE_WITH_LONG_RANDOM_PASSWORD"
$env:CLASS_JOIN_CODE="REPLACE_WITH_LONG_RANDOM_CLASS_CODE"
$env:TOKEN_SECRET="REPLACE_WITH_AT_LEAST_32_RANDOM_CHARACTERS"
$env:CORS_ORIGIN="local"
node server.js
```

The teacher email and password here are the **single** Teacher Login credentials when the app is launched with BIOBLAST_API_URL. The join code is only for enrolling students, not for reading teacher data.

This server uses a local `student_records.json` file and Node standard library (no `npm install` needed). Protect this computer and file. It is not suitable for deploying real students' personal records over the internet.

## 2. Run Flutter (Microsoft Edge on same computer)

In another terminal, from `bioblast`:

```powershell
flutter create .
flutter pub get
flutter run -d edge --dart-define=BIOBLAST_API_URL=http://localhost:8080
```

For testing with Android on the **same trusted Wi-Fi network**, replace localhost with your computer's LAN IPv4 address, e.g. `http://192.168.1.10:8080`. The Android app may block plaintext HTTP unless debug-only network configuration allows it. Production **requires HTTPS**, a managed identity system, a proper database, server-side validation, secure token storage, and school-approved privacy policies. Never use an open/public port forwarding link to expose this demo server.

## 3. Student experience

Student → register with **Full Name only** → Student Dashboard → enter the class join code **once** → JOIN CLASS. Student ID and Section fields are still hidden. The app saves progress locally. On a change it attempts upload after a short delay; if the network is unavailable, progress remains local and can be uploaded with **SYNC NOW** when online. The student can keep studying without internet.

## 4. Teacher experience

Teacher → **Teacher Login once with the server email/password** → Teacher Dashboard. Online student records are fetched automatically; pull down or tap Refresh to fetch again. Sign Out clears the saved server session. Use Refresh to fetch synchronized student lessons and scores. The current demo setup supports separate teacher/student devices if both can reach the same server. Cross-device cloud hosting is **not** included or configured.

## 5. What is and is not complete

- Included: class enrollment with shared code, scoped student tokens, offline pending flag, queued-by-snapshot retry, lesson score snapshots, teacher server sign-in, server role checks, cross-device record retrieval when both devices can reach the backend.
- Not included: production-grade privacy, HTTPS deployment, password recovery, multi-class teacher accounts, automatic sync while app is fully closed, conflict merging of concurrent devices, background scheduling, real cloud hosting, a production database, or Cell Café score sync. Cell Café session progress remains local.
- This phase uses the original eight lesson progress fields from `Store`. Cell Café integration will need its own progress fields in a later phase.
- The server token expires after 7 days; students will have to rejoin once expired (future work: refresh tokens).
- No production deployment until security and privacy review.

## Single-login change

When `BIOBLAST_API_URL` is set, the teacher login authenticates against `/api/teacher/login`, stores only the returned token (not the password) and directly displays `/api/teacher/students` data on the teacher dashboard. There is no second CONNECT TO SERVER screen. The demo token is still saved in SharedPreferences and lasts up to seven days on the Node server, so **this is not secure storage suitable for real student data**. The online mode does not fall back to the insecure local account if server login fails. When the API URL is absent, the old device-only Teacher Preview remains available for development.

To run on your Android emulator, keep Node running in one terminal and use:

```powershell
flutter run -d emulator-5554 --dart-define=BIOBLAST_API_URL=http://10.0.2.2:8080
```

Replace the example emulator ID with the value from `flutter devices`. Cleartext HTTP is for local demo only.
