# Artcellerate

A **visionOS** app built for a spatial volumetric window (`WindowGroup` + `.windowStyle(.volumetric)`). Players practice vocabulary by **drawing prompts** with **PencilKit**—either from curated word sets or from an **AI-generated** list for a custom topic.

## Requirements

- **Xcode** compatible with the project (created with Xcode 26.4; Swift tools in the bundled package use Swift 6.2).
- **visionOS** device or simulator (`xros` / `xrsimulator`).

## Open the project

1. Clone this repository.
2. Open `xraHackathon.xcodeproj` in Xcode.
3. Select a **visionOS** run destination and build (**⌘B**) / run (**⌘R**).

## What it does

- **Drawing**: `PencilKit` canvas wrapped in SwiftUI (`DrawingView`), with pen styles, eraser, ruler, line width, color picker, and optional split layouts for multiple canvases.
- **Games**:
  - **Prebuilt sets**: vocabulary in several languages (Spanish, French, Japanese, and others) plus themed lists (animals, food, nature).
  - **Custom topic**: requests short, drawable words from the **OpenAI Chat Completions** API (`gpt-4o-mini`) based on your topic, difficulty, and round count.
- **Flow**: timed rounds per word, “finish word” advances the game, and a completion panel summarizes results (including captured drawing images).

## Configuration (AI mode)

AI word generation calls `https://api.openai.com/v1/chat/completions`. In `ContentView.swift`, the API key is currently set to an empty string in `generateWordsFromTopic`. **Set a valid key** (or refactor to read from Xcode configuration / the Keychain) before expecting custom-topic games to work.

Do not commit real API keys to git.

## Project layout

| Path | Purpose |
|------|--------|
| `xraHackathon/` | SwiftUI app sources (`xraHackathonApp.swift`, `ContentView.swift`), assets, `Info.plist` |
| `xraHackathon.xcodeproj/` | Xcode project |
| `Packages/RealityKitContent/` | Local Swift package (Reality Composer / `.rkassets` scaffold); linked to the app target for future spatial content |

`GameView.swift` is present but empty; the main experience lives in `FreeFormDrawingView` inside `ContentView.swift`.

## Optional: saving drawings

`saveDrawing()` uses `UIImageWriteToSavedPhotosAlbum`. For App Store or strict privacy flows you may need the appropriate **Photo Library** usage description in `Info.plist` and user-facing copy explaining why saves are requested.

## License

No license file is included in the repository. Add one if you plan to distribute or open-source the project.
