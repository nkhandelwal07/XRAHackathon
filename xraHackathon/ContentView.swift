//test comment
//  ContentView.swift
//  PKDraw
import SwiftUI
import PencilKit
internal import Combine



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
    
    @State private var splitCount: Int = 1
    
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
    
    @State private var completedDrawings: [UIImage] = []

    let gameTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
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
                        .cornerRadius(12)
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

                            ForEach(Array(generatedWords.enumerated()), id: \.offset) { index, word in
                                HStack(spacing: 8) {
                                    Text("\(index + 1). \(word)")
                                        .fontWeight(index == currentWordIndex && !showCongratsPanel ? .bold : .regular)

                                    if index < completedTimes.count {
                                        Text("• \(formatTime(completedTimes[index]))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
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
                        .padding()
                    }
                }
                .overlay(alignment: .top) {
                    if !generatedWords.isEmpty && !showCongratsPanel && currentWordIndex < generatedWords.count {
                        VStack(spacing: 12) {
                            Text("Draw:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(generatedWords[currentWordIndex])
                                .font(.largeTitle)
                                .bold()

                            Text("Word Time: \(formatTime(currentWordElapsed))")
                                .font(.headline)

                            Text("Total Time: \(formatTime(overallElapsed))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Done") {
                                finishCurrentWord()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.top, 40)
                    }
                }
                .overlay {
                    if showCongratsPanel {
                        VStack(spacing: 16) {
                            Text("Congratulations!")
                                .font(.largeTitle)
                                .bold()

                            Text("You finished all the words for \(gameTopic)")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(generatedWords.enumerated()), id: \.offset) { index, word in
                                    if index < completedTimes.count {
                                        Text("\(index + 1). \(word): \(formatTime(completedTimes[index]))")
                                    }
                                }
                            }
                            .frame(maxWidth: 300, alignment: .leading)

                            Divider()

                            Text("Overall Time: \(formatTime(overallElapsed))")
                                .font(.title3)
                                .bold()

                            Button("Close") {
                                resetGame()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
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
                .sheet(isPresented: $showNewGamePopup) {
                    VStack(spacing: 20) {
                        Text("Start New Game")
                            .font(.title2)
                            .bold()

                        TextField("Enter a topic", text: $gameTopic)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        Stepper("Number of Questions: \(questionCount)", value: $questionCount, in: 1...20)
                            .padding(.horizontal)

                        HStack(spacing: 16) {
                            Button("Cancel") {
                                showNewGamePopup = false
                            }
                            .buttonStyle(.bordered)

                            Button("Start") {
                                Task {
                                    await startNewGame()
                                    showNewGamePopup = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(gameTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGeneratingWords)
                        }
                    }
                    .padding()
                    .frame(width: 400)
                }
                .navigationBarTitleDisplayMode(.inline)
                // Top ornament: Start
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
                        
                        // Screen sharing
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
                        // Screen recording
                        Button {
                            isRecording.toggle()
                        } label: {
                            //Image(systemName: "rectangle.dashed.badge.record")
                            VStack(spacing: 8) {
                                Image(systemName: isRecording ? "rectangle.inset.filled.badge.record" : "rectangle.dashed.badge.record")
                                withAnimation {
                                    Text(isRecording ? "Stop" : "Record")
                                        .font(.caption2)
                                }
                            }
                        }
                        Button {
                            splitCount *= 2
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.rectangle.on.rectangle")
                                Text("Split")
                                    .font(.caption2)
                            }
                        }
                    }.padding(.horizontal)
                    .padding(12)
                    .glassBackgroundEffect()
                    .buttonStyle(.plain)
                } // Top ornament: End
                // Leading ornament: Start
                .ornament(attachmentAnchor: .scene(.leading)) {
                    // Modify Tools
                    VStack(spacing: 32) {
                        Button {
                            // Clear the canvas. Reset the drawing
                            canvas.drawing = PKDrawing()
                        } label: {
                            Image(systemName: "scissors")
                        }
                        
                        Button {
                            // Undo drawing
                            undoManager?.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        
                        Button {
                            // Redo drawing
                            undoManager?.redo()
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                        }
                        
                        Button {
                            // Erase tool
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
                    } // Modify tools
                    .padding(12)
                    .buttonStyle(.plain)
                    .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32))
                } // Leading ornament: End
                .toolbar {  // Bottom Ornament: Start
                    ToolbarItemGroup(placement: .bottomOrnament) {
                        HStack { // Drawing Tools
                            Button {
                                // Pencil
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
                                // Pen
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
                                // Monoline
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
                                // Fountain: Variable scribbling
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
                                // Marker
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
                                // Crayon
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
                                // Water Color
                                isDrawing = true
                                pencilType = .watercolor
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "eyedropper.halffull")
                                    Text("Watercolor")
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            // Color picker
                            Button {
                                // Pick a color
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
                            
                        } // Drawing Tools
                        .padding(.horizontal)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [.green, .yellow]), startPoint: .leading, endPoint: .bottom)
                        )
                    }
                } // Bottom Ornament: End
                // Trailing Ornament: Start
                .ornament(attachmentAnchor: .scene(.trailing)) {
                    VStack(spacing: 32) {
                        Button {
                            // Set ruler as active
                            canvas.isRulerActive.toggle()
                        } label: {
                            Image(systemName: "pencil.and.ruler.fill")
                        }
                        Button {
                            // Tool picker
                            //let toolPicker = PKToolPicker.init()
                            let toolPicker = PKToolPicker()
                            toolPicker.setVisible(true, forFirstResponder: canvas)
                            toolPicker.addObserver(canvas)
                            canvas.becomeFirstResponder()
                        } label: {
                            Image(systemName: "pencil.tip.crop.circle.badge.plus")
                        }
                        
                        // Menu for pencil types and color
                        Menu {
                            Button {
                                // Menu: Pick a color
                                colorPicker.toggle()
                            } label: {
                                Label("Color", systemImage: "paintpalette")
                            }
                            
                            Button {
                                // Menu: Pencil
                                isDrawing = true
                                pencilType = .pencil
                            } label: {
                                Label("Pencil", systemImage: "pencil")
                            }
                            
                            Button {
                                // Menu: pen
                                isDrawing = true
                                pencilType = .pen
                            } label: {
                                Label("Pen", systemImage: "pencil.tip")
                            }
                            
                            Button {
                                // Menu: Marker
                                isDrawing = true
                                pencilType = .marker
                            } label: {
                                Label("Marker", systemImage: "paintbrush.pointed")
                            }
                            
                            Button {
                                // Menu: Monoline
                                isDrawing = true
                                pencilType = .monoline
                            } label: {
                                Label("Monoline", systemImage: "pencil.line")
                            }
                            
                            Button {
                                // Menu: pen
                                isDrawing = true
                                pencilType = .fountainPen
                            } label: {
                                Label("Fountain", systemImage: "paintbrush.pointed.fill")
                            }
                            
                            Button {
                                // Menu: Watercolor
                                isDrawing = true
                                pencilType = .watercolor
                            } label: {
                                Label("Watercolor", systemImage: "eyedropper.halffull")
                            }
                            
                            Button {
                                // Menu: Crayon
                                isDrawing = true
                                pencilType = .crayon
                            } label: {
                                Label("Crayon", systemImage: "pencil.tip")
                            }
                            
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
        
    }
    
    func resetGame() {
        canvas.drawing = PKDrawing()

        generatedWords = []
        currentWordIndex = 0
        completedTimes = []

        wordStartTime = nil
        overallStartTime = nil

        currentWordElapsed = 0
        overallElapsed = 0

        showCongratsPanel = false
        generationError = nil
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

        let prompt = """
        Generate exactly \(count) simple, concrete, drawable vocabulary words that help someone learn the topic "\(topic)".
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
        // Get the drawing image from the canvas
        let drawingImage = canvas.drawing.image(from: canvas.drawing.bounds, scale: 1.0)
        
        // Save drawings to the Photos Album
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
    // Capture drawings for saving in the photos library
    @Binding var canvas: PKCanvasView
    @Binding var isDrawing: Bool
    // Ability to switch a pencil
    @Binding var pencilType: PKInkingTool.InkType
    // Ability to change a pencil color
    @Binding var color: Color
    @Binding var bgHue: Double   // <-- ADD (line ~215)
    
    
    //let ink = PKInkingTool(.pencil, color: .black)
    // Update ink type
    var ink: PKInkingTool {
        PKInkingTool(pencilType, color: UIColor(color))
    }
    
    let eraser = PKEraserTool(.bitmap)
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Allow finger and pencil drawing
        canvas.drawingPolicy = .anyInput
        
        canvas.tool = isDrawing ? ink : eraser
        canvas.isRulerActive = true
        canvas.backgroundColor = UIColor(
            bgHue > 1.0
                ? Color.white
                : Color(hue: bgHue, saturation: 0.3, brightness: 1.0).opacity(0.3)
        )
        canvas.overrideUserInterfaceStyle = .light
        
        // From Brian Advent: Show the default toolpicker
        canvas.alwaysBounceVertical = true
        canvas.isScrollEnabled = true
        
        let toolPicker = PKToolPicker.init()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas) // Notify when the picker configuration changes
        canvas.becomeFirstResponder()
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        
        // Update tool whenever the main view updates
        uiView.tool = isDrawing ? ink : eraser
        canvas.backgroundColor = UIColor(
            bgHue > 1.0
                ? Color.white
                : Color(hue: bgHue, saturation: 0.3, brightness: 1.0).opacity(0.3)
        )
    }
}
#Preview {
    FreeFormDrawingView()
}


