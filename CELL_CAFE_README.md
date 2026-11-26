# BioBlast: Cell Café — Phase 1 Flutter integration

This update adds a **Cell Café** entry inside the existing student-side BioBlast menu.

## Implemented
- Client 2D cream/brown science café theme and landscape presentation on mobile
- Session Select with Session 1 enabled; future sessions visibly locked
- Session 1 (Glycolysis): five customer orders, Prepare/Choose orders, ingredients, immediate explanation, free hints, preparation, a three-step biological process screen, Serve
- Results with 1–3 stars, client-specified coin reward rules (10/5/2 plus 10 for three stars), local per-student best result
- Student Registration does **not** expose teacher dashboard preview
- Session 1 content stored in assets/cell_cafe/session1.json

## Not yet implemented
- The complete designs/animations for all 10 screens, Sessions 2–5, Helper Select, actual Shop, My Café decor editor, My Items, settings, sound/animation assets
- Teacher login authentication and progress synchronization across devices. Existing teacher code remains a local prototype.
- Automated Flutter build/visual testing (Flutter SDK unavailable in this execution environment).

## Run
Open the `bioblast` folder in VS Code (the one containing pubspec.yaml) and run:

```powershell
flutter pub get
flutter run -d edge
```

On Android test in landscape orientation, where the client specifies 16:9.

Open the student account, open the menu, then choose CELL CAFÉ.

The original student lessons remain available. Do not use this as the completed client release.
