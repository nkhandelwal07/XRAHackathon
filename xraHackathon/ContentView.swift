//test comment
//  ContentView.swift
//  PKDraw
import SwiftUI
import PencilKit
internal import Combine

// MARK: - Pre-existing Word Sets
struct WordSet: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let color: Color
    let words: [String]
}

let prebuiltSets: [WordSet] = [
    WordSet(name: "Spanish", emoji: "🇪🇸", color: Color(hue: 0.04, saturation: 0.8, brightness: 0.9),
            words: ["casa", "perro", "gato", "árbol", "sol", "luna", "agua", "fuego", "montaña", "río"]),
    WordSet(name: "French", emoji: "🇫🇷", color: Color(hue: 0.60, saturation: 0.7, brightness: 0.75),
            words: ["maison", "chien", "chat", "arbre", "soleil", "lune", "eau", "feu", "montagne", "rivière"]),
    WordSet(name: "Japanese", emoji: "🇯🇵", color: Color(hue: 0.97, saturation: 0.7, brightness: 0.85),
            words: ["山", "川", "海", "空", "木", "花", "犬", "猫", "魚", "鳥"]),
    WordSet(name: "German", emoji: "🇩🇪", color: Color(hue: 0.13, saturation: 0.7, brightness: 0.85),
            words: ["Haus", "Hund", "Katze", "Baum", "Sonne", "Mond", "Wasser", "Feuer", "Berg", "Fluss"]),
    WordSet(name: "Italian", emoji: "🇮🇹", color: Color(hue: 0.35, saturation: 0.65, brightness: 0.65),
            words: ["casa", "cane", "gatto", "albero", "sole", "luna", "acqua", "fuoco", "montagna", "fiume"]),
    WordSet(name: "Mandarin", emoji: "🇨🇳", color: Color(hue: 0.02, saturation: 0.85, brightness: 0.80),
            words: ["山", "河", "海", "天", "树", "花", "狗", "猫", "鱼", "鸟"]),
    WordSet(name: "Portuguese", emoji: "🇧🇷", color: Color(hue: 0.38, saturation: 0.70, brightness: 0.60),
            words: ["casa", "cachorro", "gato", "árvore", "sol", "lua", "água", "fogo", "montanha", "rio"]),
    WordSet(name: "Korean", emoji: "🇰🇷", color: Color(hue: 0.55, saturation: 0.60, brightness: 0.70),
            words: ["산", "강", "바다", "하늘", "나무", "꽃", "개", "고양이", "물고기", "새"]),
    WordSet(name: "Arabic", emoji: "🇸🇦", color: Color(hue: 0.25, saturation: 0.70, brightness: 0.55),
            words: ["بيت", "كلب", "قطة", "شجرة", "شمس", "قمر", "ماء", "نار", "جبل", "نهر"]),
    WordSet(name: "Animals", emoji: "🐾", color: Color(hue: 0.08, saturation: 0.60, brightness: 0.80),
            words: ["elephant", "giraffe", "penguin", "dolphin", "tiger", "kangaroo", "owl", "fox", "bear", "shark"]),
    WordSet(name: "Food", emoji: "🍕", color: Color(hue: 0.07, saturation: 0.75, brightness: 0.90),
            words: ["pizza", "sushi", "taco", "ramen", "burger", "pasta", "croissant", "dumpling", "curry", "ice cream"]),
    WordSet(name: "Nature", emoji: "🌿", color: Color(hue: 0.33, saturation: 0.55, brightness: 0.55),
            words: ["volcano", "waterfall", "glacier", "desert", "rainforest", "coral reef", "canyon", "tundra", "savanna", "marsh"]),
]

struct FreeFormDrawingView: View {
    
    @State private var canvas = PKCanvasView()
    @State private var isDrawing = true
    @State private var color: Color = .black
    @State private var bgHue: Double = 0.0
    @State private var pencilType: PKInkingTool.InkType = .pencil
    @State private var colorPicker = false
    @State private var lineThickness: CGFloat = 5.0
    @Environment(\.undoManager) private var undoManager
    
    @State private var isMessaging = false
    @State private var isVideoCalling = false
    @State private var isScreenSharing = false
    @State private var isRecording = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var showNewGamePopup = false
    @State private var gameTopic = ""
    @State private var questionCount = 5
    
    @State private var generatedWords: [String] = []
    @State private var isGeneratingWords = false
    @State private var generationError: String?
    
    @State private var currentWordIndex = 0
    @State private var wordStartTime: Date?
    @State private var currentWordElapsed: TimeInterval = 0
    @State private var overallStartTime: Date?
    @State private var overallElapsed: TimeInterval = 0
    @State private var completedTimes: [TimeInterval] = []
    @State private var showCongratsPanel = false
    
    @State private var completedDrawings: [DrawingResult] = []
    let gameTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @State private var gradientPhase: Double = 0
    let bgAnimTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    // MARK: - New game setup state
    @State private var gameSetupMode: GameSetupMode = .choose   // which screen we're on
    enum GameSetupMode { case choose, prebuilt, ai }
    
    @State private var difficulty: Difficulty = .medium
    enum Difficulty: String, CaseIterable { case easy = "Easy", medium = "Medium", hard = "Hard" }

    let titleColor = Color(hue: 0.70, saturation: 0.6, brightness: 0.25)

    var dynamicBGColors: [Color] {
        if bgHue > 1.0 {
            return [.white, Color(hue: 0.0, saturation: 0.0, brightness: 0.97)]
        }
        let h1 = bgHue
        let h2 = (bgHue + 0.12).truncatingRemainder(dividingBy: 1.0)
        let h3 = (bgHue + 0.25 + gradientPhase * 0.003).truncatingRemainder(dividingBy: 1.0)
        return [
            Color(hue: h1, saturation: 0.35, brightness: 0.98),
            Color(hue: h2, saturation: 0.25, brightness: 0.95),
            Color(hue: h3, saturation: 0.20, brightness: 0.92),
        ]
    }
    
    var body: some View {
        NavigationStack {
//            DrawingView(
//                canvas: $canvas,
//                isDrawing: $isDrawing,
//                pencilType: $pencilType,
//                color: $color,
//                bgHue: $bgHue
//            )
//            let columns = splitCount == 1 ? 1 : 2
//
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 4) {
//                ForEach(0..<splitCount, id: \.self) { _ in
//                    DrawingView(
//                        canvas: .constant(PKCanvasView()),
//                        isDrawing: $isDrawing,
//                        pencilType: $pencilType,
//                        color: $color,
//                        bgHue: .constant(0.0)
//                    )
//                    .frame(maxWidth: .infinity, minHeight: 300)
//                    .cornerRadius(12)
//                }
//            }
            GeometryReader { geo in
                let columns = splitCount == 1 ? 1 : 2
                let itemHeight = splitCount <= 2 ? geo.size.height : geo.size.height / 2

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns), spacing: 4) {
                    ForEach(0..<splitCount, id: \.self) { _ in
                        DrawingView(
                            canvas: .constant(PKCanvasView()),
                            isDrawing: $isDrawing,
                            pencilType: $pencilType,
                            color: $color,
                            bgHue: .constant(0.0)
                        )
                        .frame(width: geo.size.width / CGFloat(columns) - 4, height: itemHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    if isGeneratingWords {
                        ProgressView("Generating words...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding()
                    } else if !generatedWords.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Words for \(gameTopic)")
                                .font(.headline)
                                .foregroundStyle(titleColor)
                            ForEach(Array(generatedWords.enumerated()), id: \.offset) { index, word in
                                HStack(spacing: 8) {
                                    Text("\(index + 1). \(word)")
                                        .fontWeight(index == currentWordIndex && !showCongratsPanel ? .bold : .regular)
                                        .foregroundStyle(titleColor)
                                    if index < completedTimes.count {
                                        Text("• \(formatTime(completedTimes[index]))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    }
                                }
                            }
                            if let generationError {
                                Text(generationError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 10)
                        .padding()
                    }
                }
                .overlay(alignment: .top) {
                    if !generatedWords.isEmpty && !showCongratsPanel && currentWordIndex < generatedWords.count {
                        VStack(spacing: 12) {
                            Label("Draw", systemImage: "pencil.and.outline")
                                .font(.caption)
                                .foregroundStyle(titleColor)
                            Text(generatedWords[currentWordIndex])
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)

                            Text("Word Time: \(formatTime(currentWordElapsed))")
                                .font(.headline)
                                .monospacedDigit()

                            Text("Total Time: \(formatTime(overallElapsed))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()

                            Button("Done") {
                                finishCurrentWord()
                            }
                            .buttonStyle(.borderedProminent)
                            .foregroundStyle(titleColor)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
                        .padding(.top, 40)
                    }
                }
                .overlay {
                    if showCongratsPanel {
                        ZStack {
                            Color.black.opacity(0.35)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        resetGame()
                                    }
                                }

                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "sparkles")
                                            .font(.title2)
                                            .foregroundStyle(.yellow)
                                        Text("Congratulations!")
                                            .font(.system(size: 34, weight: .bold, design: .rounded))
                                    }

                                    Text("You finished all the words for \(gameTopic).")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }

                                HStack(spacing: 12) {
                                    Label("\(generatedWords.count) words", systemImage: "checkmark.seal.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text("•")
                                        .foregroundStyle(.secondary)

                                    Label(formatTime(overallElapsed), systemImage: "timer")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }

                                Divider().opacity(0.65)

                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(Array(generatedWords.enumerated()), id: \.offset) { index, word in
                                            if index < completedTimes.count {
                                                HStack(alignment: .firstTextBaseline) {
                                                    Text("\(index + 1).")
                                                        .foregroundStyle(.secondary)
                                                        .frame(width: 28, alignment: .trailing)

                                                    Text(word)
                                                        .font(.body.weight(.semibold))
                                                        .lineLimit(1)

                                                    Spacer(minLength: 12)

                                                    Text(formatTime(completedTimes[index]))
                                                        .font(.body)
                                                        .foregroundStyle(.secondary)
                                                        .monospacedDigit()
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(.thinMaterial)
                                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            }
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                                .frame(maxHeight: 260)

                                HStack(spacing: 12) {
                                    Button("Play again") {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                            resetGame()
                                            showNewGamePopup = true
                                        }
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Close") {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                            resetGame()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(22)
                            .frame(maxWidth: 520)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.30), radius: 30, x: 0, y: 18)
                            .padding()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .onReceive(gameTimer) { _ in
                    if let start = wordStartTime, !showCongratsPanel {
                        currentWordElapsed = Date().timeIntervalSince(start)
                    }
                    if let overallStart = overallStartTime, !showCongratsPanel {
                        overallElapsed = Date().timeIntervalSince(overallStart)
                    }
                }
                .onReceive(bgAnimTimer) { _ in
                    if bgHue <= 1.0 {
                        gradientPhase += 1
                        if gradientPhase > 1000 { gradientPhase = 0 }
                    }
                }
                // MARK: - Game Setup Sheet
                .sheet(isPresented: $showNewGamePopup, onDismiss: { gameSetupMode = .choose }) {
                    Group {
                        switch gameSetupMode {

                        // ── Screen 1: Choose mode ──────────────────────────────
                        case .choose:
                            VStack(spacing: 20) {
                                Text("Start New Game")
                                    .font(.title3).bold()

                                HStack(spacing: 16) {
                                    Button {
                                        gameSetupMode = .prebuilt
                                    } label: {
                                        VStack(spacing: 8) {
                                            Text("Pre-built Sets")
                                                .font(.headline)
                                            Text("Language &\ntopic collections")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(titleColor.opacity(0.4), lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        gameSetupMode = .ai
                                    } label: {
                                        VStack(spacing: 8) {
                                            Text("AI Generated")
                                                .font(.headline)
                                            Text("Enter any topic,\nAI picks the words")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(titleColor.opacity(0.4), lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button("Cancel") { showNewGamePopup = false }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                            .padding(20)
                            .frame(width: 380)

                        // ── Screen 2: Pre-built set picker ────────────────────
                        case .prebuilt:
                            VStack(spacing: 12) {
                                HStack {
                                    Button {
                                        gameSetupMode = .choose
                                    } label: {
                                        Label("Back", systemImage: "chevron.left")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(titleColor)
                                    Spacer()
                                    Text("Choose a Set")
                                        .font(.title3).bold()
                                    Spacer()
                                    Color.clear.frame(width: 60)
                                }

                                Stepper("Words: \(questionCount)", value: $questionCount, in: 1...10)
                                    .font(.subheadline)

                                ScrollView {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                                        ForEach(prebuiltSets) { set in
                                            Button {
                                                Task {
                                                    gameTopic = set.name
                                                    let count = min(questionCount, set.words.count)
                                                    let words = Array(set.words.shuffled().prefix(count))
                                                    await startPrebuiltGame(topic: set.name, words: words)
                                                    showNewGamePopup = false
                                                }
                                            } label: {
                                                VStack(spacing: 8) {
                                                    Text(set.emoji)
                                                        .font(.system(size: 32))
                                                        .frame(width: 56, height: 56)
                                                        .background(set.color.opacity(0.15))
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(set.color.opacity(0.4), lineWidth: 1)
                                                        )
                                                    Text(set.name)
                                                        .font(.caption)
                                                        .bold()
                                                        .foregroundStyle(titleColor)
                                                    Text("\(min(questionCount, set.words.count)) words")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(.ultraThinMaterial)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(set.color.opacity(0.3), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .frame(width: 420, height: 380)
                            }
                            .padding(16)
                            .fixedSize()

                        // ── Screen 3: AI topic entry ───────────────────────────
                        case .ai:
                            VStack(spacing: 16) {
                                HStack {
                                    Button {
                                        gameSetupMode = .choose
                                    } label: {
                                        Label("Back", systemImage: "chevron.left")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(titleColor)
                                    Spacer()
                                    Text("AI Generated")
                                        .font(.title3).bold()
                                    Spacer()
                                    Color.clear.frame(width: 60)
                                }

                                TextField("Enter any topic (e.g. Space, Animals…)", text: $gameTopic)
                                    .textFieldStyle(.roundedBorder)

                                Stepper("Number of Words: \(questionCount)", value: $questionCount, in: 1...20)
                                    .font(.subheadline)

                                VStack(spacing: 6) {
                                    Text("Difficulty")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Picker("Difficulty", selection: $difficulty) {
                                        ForEach(Difficulty.allCases, id: \.self) { level in
                                            Text(level.rawValue).tag(level)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                HStack(spacing: 12) {
                                    Button("Cancel") { showNewGamePopup = false }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    Button("Generate & Start") {
                                        Task {
                                            await startNewGame()
                                            showNewGamePopup = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(gameTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGeneratingWords)
                                }
                            }
                            .padding(20)
                            .fixedSize()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .ornament(attachmentAnchor: .scene(.top)) {
                    HStack(spacing: 64) {
                        Button {
                            showNewGamePopup = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text("Start New Game")
                                    .font(.caption2)
                            }
                        }
                        Button {
                            //
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "message")
                                Text("Chat")
                                    .font(.caption2)
                            }
                        }
                        Button {
                            //
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "video")
                                Text("Call")
                                    .font(.caption2)
                            }
                        }
                        Button {
                            //
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: isScreenSharing ? "shared.with.you.slash" : "shared.with.you")
                                withAnimation {
                                    Text(isScreenSharing ? "Stop" : "Share")
                                        .font(.caption2)
                                }
                            }
                        }
                        Button {
                            isRecording.toggle()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: isRecording ? "rectangle.inset.filled.badge.record" : "rectangle.dashed.badge.record")
                                withAnimation {
                                    Text(isRecording ? "Stop" : "Record")
                                        .font(.caption2)
                                }
                            }
                        }
                    }.padding(.horizontal)
                    .padding(12)
                    .glassBackgroundEffect()
                    .buttonStyle(.plain)
                }
                .ornament(attachmentAnchor: .scene(.leading)) {
                    VStack(spacing: 32) {
                        Button {
                            canvas.drawing = PKDrawing()
                        } label: {
                            Image(systemName: "scissors")
                        }
                        Button {
                            undoManager?.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        Button {
                            undoManager?.redo()
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                        }
                        Button {
                            isDrawing = false
                        } label: {
                            Image(systemName: "eraser.line.dashed")
                        }
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [.white, .yellow]), startPoint: .leading, endPoint: .top)
                        )
                        VStack {
                            Slider(value: $bgHue, in: 0...1.2)
                                .frame(width: 120)
                            Text("Background")
                                .font(.caption2)
                        }
                    }
                    .padding(12)
                    .buttonStyle(.plain)
                    .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32))
                }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomOrnament) {
                        HStack {
                            Button {
                                isDrawing = true
                                pencilType = .pencil
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "pencil.and.scribble")
                                    Text("Pencil")
                                        .foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            Button {
                                isDrawing = true
                                pencilType = .pen
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "applepencil.tip")
                                    Text("Pen")
                                        .foregroundStyle(.white)
                                }
                            }
                            Button {
                                isDrawing = true
                                pencilType = .monoline
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "pencil.line")
                                    Text("Monoline")
                                        .foregroundStyle(.white)
                                }
                            }
                            Button {
                                isDrawing = true
                                pencilType = .fountainPen
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "scribble.variable")
                                    Text("Fountain")
                                        .foregroundStyle(.white)
                                }
                            }
                            Button {
                                isDrawing = true
                                pencilType = .marker
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "paintbrush.pointed")
                                    Text("Marker")
                                        .foregroundStyle(.white)
                                }
                            }
                            Button {
                                isDrawing = true
                                pencilType = .crayon
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "paintbrush")
                                    Text("Crayon")
                                        .foregroundStyle(.white)
                                }
                            }
                            Button {
                                isDrawing = true
                                pencilType = .watercolor
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "eyedropper.halffull")
                                    Text("Watercolor")
                                        .foregroundStyle(.white)
                                }
                            }
                            Button {
                                colorPicker.toggle()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "paintpalette")
                                    Text("Colorpicker")
                                        .foregroundStyle(.white)
                                }
                            }
                            VStack(spacing: 8) {
                                Image(systemName: "lineweight")
                                Slider(value: $lineThickness, in: 1...20, step: 1)
                                    .frame(width: 100)
                                Text("\(Int(lineThickness))pt")
                                    .foregroundStyle(.white)
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [.green, .yellow]), startPoint: .leading, endPoint: .bottom)
                        )
                    }
                }
                .ornament(attachmentAnchor: .scene(.trailing)) {
                    VStack(spacing: 32) {
                        Button {
                            canvas.isRulerActive.toggle()
                        } label: {
                            Image(systemName: "pencil.and.ruler.fill")
                        }
                        Button {
                            let toolPicker = PKToolPicker()
                            toolPicker.setVisible(true, forFirstResponder: canvas)
                            toolPicker.addObserver(canvas)
                            canvas.becomeFirstResponder()
                        } label: {
                            Image(systemName: "pencil.tip.crop.circle.badge.plus")
                        }
                        Menu {
                            Button { colorPicker.toggle() } label: { Label("Color", systemImage: "paintpalette") }
                            Button { isDrawing = true; pencilType = .pencil } label: { Label("Pencil", systemImage: "pencil") }
                            Button { isDrawing = true; pencilType = .pen } label: { Label("Pen", systemImage: "pencil.tip") }
                            Button { isDrawing = true; pencilType = .marker } label: { Label("Marker", systemImage: "paintbrush.pointed") }
                            Button { isDrawing = true; pencilType = .monoline } label: { Label("Monoline", systemImage: "pencil.line") }
                            Button { isDrawing = true; pencilType = .fountainPen } label: { Label("Fountain", systemImage: "paintbrush.pointed.fill") }
                            Button { isDrawing = true; pencilType = .watercolor } label: { Label("Watercolor", systemImage: "eyedropper.halffull") }
                            Button { isDrawing = true; pencilType = .crayon } label: { Label("Crayon", systemImage: "pencil.tip") }
                        } label: {
                            Image(systemName: "hand.draw")
                        }
                        .sheet(isPresented: $colorPicker) {
                            VStack(spacing: 20) {
                                ColorPicker("Pick color", selection: $color)
                                    .padding()
                                Button("Done") {
                                    colorPicker = false
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    }.padding(12)
                        .buttonStyle(.plain)
                        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32))
                } // Trailing Ornament: End
            
        }
        .background {
            LinearGradient(
                colors: [
                    Color(hue: bgHue > 1.0 ? 0.58 : bgHue, saturation: 0.30, brightness: 0.25),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        
    }
    
    // MARK: - Game Logic
    
    func resetGame() {
        canvas.drawing = PKDrawing()
        generatedWords = []
        currentWordIndex = 0
        completedTimes = []
        completedDrawings = []
        wordStartTime = nil
        overallStartTime = nil
        currentWordElapsed = 0
        overallElapsed = 0
        showCongratsPanel = false
        generationError = nil
    }

    func startPrebuiltGame(topic: String, words: [String]) async {
        canvas.drawing = PKDrawing()
        generatedWords = []
        generationError = nil
        showCongratsPanel = false
        currentWordIndex = 0
        completedTimes = []
        completedDrawings = []
        currentWordElapsed = 0
        overallElapsed = 0
        wordStartTime = nil
        overallStartTime = nil
        generatedWords = words
        if !words.isEmpty {
            let now = Date()
            wordStartTime = now
            overallStartTime = now
        }
    }
    
    struct DrawingResult: Identifiable {
        let id = UUID()
        let word: String
        let image: UIImage
        let time: TimeInterval
    }
    
    struct ChatRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
    }
    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }
    struct ChatResponse: Decodable {
        let choices: [Choice]
        struct Choice: Decodable {
            let message: Message
        }
        struct Message: Decodable {
            let content: String
        }
    }

    func generateWordsFromTopic(topic: String, count: Int) async throws -> [String] {
        let apiKey = ""
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        let difficultyDescription: String
        switch difficulty {
        case .easy:   difficultyDescription = "very simple and common, suitable for beginners or young children"
        case .medium: difficultyDescription = "moderately challenging, suitable for intermediate learners"
        case .hard:   difficultyDescription = "advanced and specific, suitable for expert learners"
        }

        let prompt = """
        Generate exactly \(count) simple, concrete, drawable vocabulary words that help someone learn the topic "\(topic)".
        The difficulty level should be \(difficultyDescription).
        Return only a comma-separated list.
        Keep each item short, ideally 1 to 3 words.
        """
        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatMessage(role: "system", content: "You generate educational drawing prompts."),
                ChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.7
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: errorText
            ])
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        let rawText = decoded.choices.first?.message.content ?? ""
        let words = rawText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(words.prefix(count))
    }
    
    func saveDrawing() {
        let drawingImage = canvas.drawing.image(from: canvas.drawing.bounds, scale: 1.0)
        UIImageWriteToSavedPhotosAlbum(drawingImage, nil, nil, nil)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
    }
    
    func finishCurrentWord() {
        guard currentWordIndex < generatedWords.count,
              let start = wordStartTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        if completedTimes.count > currentWordIndex {
            completedTimes[currentWordIndex] = elapsed
        } else {
            completedTimes.append(elapsed)
        }
        let image = canvas.drawing.image(from: canvas.drawing.bounds, scale: 2.0)
        let result = DrawingResult(
            word: generatedWords[currentWordIndex],
            image: image,
            time: elapsed
        )
        completedDrawings.append(result)
        if currentWordIndex < generatedWords.count - 1 {
            currentWordIndex += 1
            canvas.drawing = PKDrawing()
            wordStartTime = Date()
            currentWordElapsed = 0
        } else {
            overallElapsed = Date().timeIntervalSince(overallStartTime ?? Date())
            showCongratsPanel = true
            wordStartTime = nil
        }
    }
    
    func startNewGame() async {
        canvas.drawing = PKDrawing()
        generatedWords = []
        generationError = nil
        isGeneratingWords = true
        showCongratsPanel = false
        currentWordIndex = 0
        completedTimes = []
        completedDrawings = []
        currentWordElapsed = 0
        overallElapsed = 0
        wordStartTime = nil
        overallStartTime = nil
        do {
            let words = try await generateWordsFromTopic(topic: gameTopic, count: questionCount)
            generatedWords = words
            if !words.isEmpty {
                currentWordIndex = 0
                let now = Date()
                wordStartTime = now
                overallStartTime = now
            }
            print("Generated words: \(words)")
        } catch {
            generationError = error.localizedDescription
            print("Failed to generate words: \(error)")
        }
        isGeneratingWords = false
    }
}

struct DrawingView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var isDrawing: Bool
    @Binding var pencilType: PKInkingTool.InkType
    @Binding var color: Color
    @Binding var bgHue: Double
    var ink: PKInkingTool {
        PKInkingTool(pencilType, color: UIColor(color))
    }
    let eraser = PKEraserTool(.bitmap)
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = isDrawing ? ink : eraser
        canvas.isRulerActive = true
        canvas.backgroundColor = .clear
        canvas.overrideUserInterfaceStyle = .light
        canvas.alwaysBounceVertical = true
        canvas.isScrollEnabled = true
        let toolPicker = PKToolPicker.init()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = isDrawing ? ink : eraser
        uiView.backgroundColor = .clear
    }
}

#Preview {
    FreeFormDrawingView()
}
