# BioBlast Session 1–8 update

The source project replaces the eight old lesson paths with the revised Session 1–8 content. The existing app shell, login, teacher and student dashboards, accounts, shared visual design, progress storage, synchronization, café engine, and server source are retained. This ZIP contains source code, not an APK or a certified device-tested build.

## Revised sessions

| Session | Lesson | Learn cards | Play rounds | Maximum coins |
| --- | --- | ---: | --- | ---: |
| 1 | Introduction to Cellular Respiration | 22 | Scrambled Words; Picture Analysis; True or False | 850 |
| 2 | Raw Materials and Site of Cellular Respiration | 8 | Matching Type; Who Am I?; Multiple Choice | 1,000 |
| 3 | Glycolysis: The Sugar Split | 8 | Match-Up Mixer; Pathway Builder; ATP Energy Bank | 850 |
| 4 | Preparing for the Krebs Cycle | 10 | Scrambled Words; Prep Match Up; Krebs Prep Master Challenge | 850 |
| 5 | Krebs Cycle: The Energy Wheel | 8 | Carbon Catch; Wheel Sorter; Energy Vault | 850 |
| 6 | Electron Transport Chain: The Power Relay | 8 | Pin the Part; Relay Fix-It; Chain Reaction Quiz | 850 |
| 7 | ATP Formation: Powering the Cell | 3 | Phosphorylation Sorter; Missing Piece Puzzle; Case Files | 850 |
| 8 | Cellular Respiration: Connecting the Stages | 8 | Phosphorylation Sorter; Missing Piece Puzzle; Case Files | 850 |

## Implemented behavior

- Learn uses one animated flip card at a time, Previous/Next, read aloud, progress indicators, and an Explore button that requires every card to be flipped. Source illustrations are used where supplied. Sessions 6–8 use picture-first cards; Session 4 shows the source preparation diagram with a focused concept title.
- Explore uses locally scripted 120-second animated scenes, device text-to-speech narration, captions, play/pause, replay, volume, a visible timer, and an end-of-animation comprehension prompt. A quiet original instrumental loop is bundled locally. Session 4's comprehension prompt includes the four specified choices and incorrect-answer guidance.
- Session 1 follows glucose through glycolysis, pyruvate preparation, Krebs, and oxidative phosphorylation. Removing oxygen returns the simulation to the glycolysis-level ATP output.
- Session 2 replaces mitochondrion anatomy with an eight-label respiration map. Labels can be placed in any order using drag-and-drop or tap then tap. Incorrect placements stay unplaced; completing all eight unlocks Play.
- Session 3 reuses the existing glycolysis mechanics in the correct revised position. It tracks 2 ATP spent, 4 made, net 2, 2 NADH, and 2 pyruvate.
- Session 4 requires two repetitions of pyruvate + CoA + NAD⁺. Its counters end at 2 acetyl-CoA, 2 CO₂, 2 NADH, and no ATP.
- Session 5 retains the requested wheel, catching, sorting, and numeric vault mechanics. The wheel output panel counts the Krebs turn separately from the preceding preparation CO₂ animation.
- Session 6 retains the chain, pin matching, relay swaps, and quiz mechanics. Complex II is explicitly shown as not pumping protons; its H⁺ gauge is an illustrative learning gauge, not a stoichiometric proton count.
- Sessions 7–8 offer With Oxygen and Without Oxygen muscle/yeast variants. Both an oxygen run and one no-oxygen run are required before Play unlocks. Fermentation regenerates NAD⁺ and adds no ATP. Session 8 includes the six-carbon CO₂ trace. Session 7's puzzle separates substrate-level and oxidative paths; Session 8 follows a single glucose-to-ATP path.
- Games retain 45-second rounds, four hero skills, 50 coins per correct item, round breakdowns, café purchases, item bags, and finish badges. Scramble rounds now show one word at a time. The lesson library and session titles read the revised data.

## Preservation checks

The comparison against the uploaded project found 190 original files byte-identical and no omitted source files. Sixteen original files changed, all within the session implementation plus asset/dependency registration. New lesson files, assets, tests, and documentation are added. See `docs/preservation_check.json` for the file list.

The byte-identical modules include `main.dart`, `home.dart`, `common.dart`, `teacher_login.dart`, `teacher_dashboard.dart`, `online_teacher.dart`, `student_account.dart`, `cloud_sync.dart`, `role_entry.dart`, `cell_cafe.dart`, `shop.dart`, `ui_kit.dart`, `visuals.dart`, and `art.dart`. Original server and platform source files are retained.

Generated build outputs, browser/tool caches, and machine-specific generated settings are excluded from this source ZIP. No account or stored student data is reset. Existing completion flags and scores retain their original meaning/storage; an already completed learner profile can therefore show previously unlocked steps. Use a new test learner when checking the new prerequisite flow.

## Source interpretation and review notes

The eight DOCX documents and their embedded pictures were inspected. Some specifications contain mockup-only information, conflicting labels, or unspecified details:

- Session 4 requests “Term 1 of 10” but supplies one main preparation diagram rather than ten distinct figures. The implementation provides ten focused concept cards using that source diagram. Ten separate newly illustrated diagrams are not included.
- The revised Glycolysis document still mentions a “Week 4” finish badge. It is implemented as Session/Week 3 to match the supplied revised session order.
- Session 2 alternates between “Mito Lab Shop” and “My Cafe.” The revised route uses My Cafe, matching its final results instruction and the common café flow.
- The Session 4 combo display retains the existing streak feedback. It does not add coins beyond 50 per item, preserving the document's stated 850-coin maximum.
- Source illustrations and layouts guide the revised lessons. Code-drawn diagrams and existing scientific icons fill gaps where standalone artwork is not supplied. Mockups are not reproduced pixel for pixel. Small text already embedded in source images may require client review on a phone.
- Where the documents specify a question count/mechanic without every item, the remaining clues/questions and café details are written from the stated lesson content and shown examples. These authored details should receive the client's pedagogical review.
- Explore is an offline, runtime-animated presentation using the existing TTS approach, not a newly rendered MP4. Narration quality and timing depend on the device's installed English voice. Audio behavior needs device verification.

## Validation performed here

Passed:

- Uploaded ZIP integrity check and successful extraction.
- Static parsing of all 36 Dart source/test files using the Dart tree-sitter grammar.
- Actual session-data checks: lesson order, 22/8/8/10/8/8/3/8 card counts, three rounds per session, exact round item counts, correct answer indices, scramble letter multisets, unique café IDs, simulation tray/zone references, repeated-input rules, ATP/carbon/electron-carrier totals, required mode groups, source image paths, and declared asset folders.
- Byte comparison of preserved source files and source inclusion check.
- Final ZIP CRC/integrity check during packaging.

The static grammar check is not a Dart type analyzer. Passing these checks does not establish that Flutter builds or that the UI runs without layout errors.

## Features and checks not fully verified

This environment has no Flutter/Dart SDK, Android SDK/emulator, or connected phone. The following are **not executed or verified** here:

- `flutter pub get`, package resolution, and the new `audioplayers` dependency. The original lockfile is retained; Flutter must resolve and update it before building.
- `flutter analyze`, the Flutter unit/widget tests, and Android/iOS/web builds.
- Phone/tablet layout, orientation changes, touch target readability, drag-and-drop, timer behavior during app backgrounding, and hero powers during real play.
- Installed offline TTS voice availability, pronunciation, narration duration, music playback/volume, and platform audio lifecycle.
- Device persistence after restart and live teacher–student/server synchronization. Their source is unchanged, but this is not a runtime regression-test result.

Five data tests and two flip-card gate widget tests are included for execution on the Flutter workstation. Their presence is not a claim that they passed here.

## Open and validate in Android Studio

1. Extract the ZIP and open its `bioblast` folder, containing `pubspec.yaml`.
2. Use the existing Flutter installation that supports the project's unchanged Dart SDK constraint `^3.13.5`.
3. In the project terminal, run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

4. Test with a fresh learner. Complete Learn → Explore → Simulate → Play for all eight sessions. Confirm wrong answers and incorrect drops, replay/reset, both oxygen modes, hero skills, coin maximums, purchases, finish badges, app restart, and synchronization with the existing server.

The independent static data validator can also be rerun with:

```sh
python3 tools/validate_revised_content.py
```

Its optional Dart grammar check requires `tree-sitter` and `tree-sitter-dart`; its data checks use Python's standard library.
