import Foundation
import ScreenSaver
import AppKit

// MARK: - Models

struct Particle {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var alpha: CGFloat
    var color: NSColor
    var size: CGFloat
    var decay: CGFloat
}

struct Rocket {
    var x: CGFloat
    var y: CGFloat
    var vy: CGFloat
    var targetY: CGFloat
    var color: NSColor
    var exploded: Bool
}

// MARK: - Preferences Manager

public final class PreferencesManager {
    public static let shared = PreferencesManager()
    
    private let defaults: UserDefaults
    
    private init() {
        let identifier = Bundle(for: FireworksView.self).bundleIdentifier ?? "com.tissot.fireworks"
        self.defaults = ScreenSaverDefaults(forModuleWithName: identifier) ?? UserDefaults.standard
        registerDefaults()
    }
    
    private func registerDefaults() {
        defaults.register(defaults: [
            "frequency": 4,          // 1..10
            "rocketSpeed": 2,        // 1=Lenta, 2=Normal, 3=Rápida, 4=Turbo
            "particleCount": 80,     // 50, 80, 140, 220
            "particleSize": 3.5,     // 2.5, 3.5, 5.0
            "gravity": 2,            // 1=Flutuante (Lua), 2=Normal (Terra), 3=Pesada
            "colorPalette": 0,       // 0..4
            "showTrails": true       // true/false
        ])
    }
    
    public var frequency: Int {
        get {
            let val = defaults.integer(forKey: "frequency")
            return val > 0 ? val : 4
        }
        set {
            defaults.set(newValue, forKey: "frequency")
            defaults.synchronize()
        }
    }
    
    public var rocketSpeed: Int {
        get {
            let val = defaults.integer(forKey: "rocketSpeed")
            return val > 0 ? val : 2
        }
        set {
            defaults.set(newValue, forKey: "rocketSpeed")
            defaults.synchronize()
        }
    }
    
    public var particleCount: Int {
        get {
            let val = defaults.integer(forKey: "particleCount")
            return val > 0 ? val : 80
        }
        set {
            defaults.set(newValue, forKey: "particleCount")
            defaults.synchronize()
        }
    }
    
    public var particleSize: CGFloat {
        get {
            let val = CGFloat(defaults.double(forKey: "particleSize"))
            return val > 0 ? val : 3.5
        }
        set {
            defaults.set(Double(newValue), forKey: "particleSize")
            defaults.synchronize()
        }
    }
    
    public var gravity: Int {
        get {
            let val = defaults.integer(forKey: "gravity")
            return val > 0 ? val : 2
        }
        set {
            defaults.set(newValue, forKey: "gravity")
            defaults.synchronize()
        }
    }
    
    public var colorPalette: Int {
        get { defaults.integer(forKey: "colorPalette") }
        set {
            defaults.set(newValue, forKey: "colorPalette")
            defaults.synchronize()
        }
    }
    
    public var showTrails: Bool {
        get {
            if defaults.object(forKey: "showTrails") == nil { return true }
            return defaults.bool(forKey: "showTrails")
        }
        set {
            defaults.set(newValue, forKey: "showTrails")
            defaults.synchronize()
        }
    }
}

// MARK: - Configuration Sheet Controller

public class ConfigureSheetController: NSWindowController {
    public var onSettingsChanged: (() -> Void)?
    
    private var frequencySlider: NSSlider!
    private var frequencyValueLabel: NSTextField!
    private var rocketSpeedPopup: NSPopUpButton!
    private var particleCountPopup: NSPopUpButton!
    private var particleSizePopup: NSPopUpButton!
    private var gravityPopup: NSPopUpButton!
    private var palettePopup: NSPopUpButton!
    private var trailsCheckbox: NSButton!
    
    public init() {
        let sheetWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 470, height: 410),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        sheetWindow.title = "Opções do Protetor de Tela"
        super.init(window: sheetWindow)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        guard let window = self.window, let contentView = window.contentView else { return }
        
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])
        
        // Header
        let titleLabel = NSTextField(labelWithString: "Fogos de Artifício")
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        
        let subtitleLabel = NSTextField(labelWithString: "Personalize partículas, cores, velocidade e gravidade.")
        subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        
        let headerStack = NSStackView(views: [titleLabel, subtitleLabel])
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 2
        container.addArrangedSubview(headerStack)
        
        // Divider
        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(divider)
        divider.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        
        let labelColumnWidth: CGFloat = 160
        let controlWidth: CGFloat = 220
        
        // 1. Frequência
        frequencySlider = NSSlider(value: 4, minValue: 1, maxValue: 10, target: self, action: #selector(sliderChanged(_:)))
        frequencySlider.isContinuous = true
        frequencySlider.numberOfTickMarks = 10
        frequencySlider.allowsTickMarkValuesOnly = true
        frequencySlider.widthAnchor.constraint(equalToConstant: 130).isActive = true
        
        frequencyValueLabel = NSTextField(labelWithString: "Normal (4/10)")
        frequencyValueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        frequencyValueLabel.textColor = .secondaryLabelColor
        
        let freqStack = NSStackView(views: [frequencySlider, frequencyValueLabel])
        freqStack.orientation = .horizontal
        freqStack.spacing = 8
        freqStack.alignment = .centerY
        
        // 2. Velocidade dos Foguetes
        rocketSpeedPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        rocketSpeedPopup.addItem(withTitle: "Lenta")
        rocketSpeedPopup.lastItem?.tag = 1
        rocketSpeedPopup.addItem(withTitle: "Normal [Padrão]")
        rocketSpeedPopup.lastItem?.tag = 2
        rocketSpeedPopup.addItem(withTitle: "Rápida")
        rocketSpeedPopup.lastItem?.tag = 3
        rocketSpeedPopup.addItem(withTitle: "Turbo")
        rocketSpeedPopup.lastItem?.tag = 4
        rocketSpeedPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        // 3. Partículas
        particleCountPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        particleCountPopup.addItem(withTitle: "Leve (~50 partículas)")
        particleCountPopup.lastItem?.tag = 50
        particleCountPopup.addItem(withTitle: "Equilibrado (~80 partículas)")
        particleCountPopup.lastItem?.tag = 80
        particleCountPopup.addItem(withTitle: "Intenso (~140 partículas)")
        particleCountPopup.lastItem?.tag = 140
        particleCountPopup.addItem(withTitle: "Espetacular (~220 partículas)")
        particleCountPopup.lastItem?.tag = 220
        particleCountPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        // 4. Tamanho das partículas
        particleSizePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        particleSizePopup.addItem(withTitle: "Pequenas (2.5 px)")
        particleSizePopup.lastItem?.tag = 25
        particleSizePopup.addItem(withTitle: "Médias (3.5 px)")
        particleSizePopup.lastItem?.tag = 35
        particleSizePopup.addItem(withTitle: "Grandes (5.0 px)")
        particleSizePopup.lastItem?.tag = 50
        particleSizePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        // 5. Gravidade
        gravityPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        gravityPopup.addItem(withTitle: "Flutuante / Suave (Lua)")
        gravityPopup.lastItem?.tag = 1
        gravityPopup.addItem(withTitle: "Normal [Terra]")
        gravityPopup.lastItem?.tag = 2
        gravityPopup.addItem(withTitle: "Pesada / Rápida")
        gravityPopup.lastItem?.tag = 3
        gravityPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        // 6. Paleta de Cores
        palettePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        palettePopup.addItem(withTitle: "Multicolorido (Padrão)")
        palettePopup.lastItem?.tag = 0
        palettePopup.addItem(withTitle: "Dourado & Réveillon")
        palettePopup.lastItem?.tag = 1
        palettePopup.addItem(withTitle: "Neon / Cyberpunk")
        palettePopup.lastItem?.tag = 2
        palettePopup.addItem(withTitle: "Fogo & Brasas")
        palettePopup.lastItem?.tag = 3
        palettePopup.addItem(withTitle: "Gelo & Aurora")
        palettePopup.lastItem?.tag = 4
        palettePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        // 7. Rastro
        trailsCheckbox = NSButton(checkboxWithTitle: "Exibir rastro cintilante na subida", target: nil, action: nil)
        
        func makeLabel(_ text: String) -> NSTextField {
            let lbl = NSTextField(labelWithString: text)
            lbl.alignment = .right
            lbl.widthAnchor.constraint(equalToConstant: labelColumnWidth).isActive = true
            return lbl
        }
        
        let emptyLeadingView = NSView()
        emptyLeadingView.widthAnchor.constraint(equalToConstant: labelColumnWidth).isActive = true
        
        let row1 = NSStackView(views: [makeLabel("Frequência de Foguetes:"), freqStack])
        let row2 = NSStackView(views: [makeLabel("Velocidade dos Foguetes:"), rocketSpeedPopup])
        let row3 = NSStackView(views: [makeLabel("Qtd. de Partículas:"), particleCountPopup])
        let row4 = NSStackView(views: [makeLabel("Tamanho das Partículas:"), particleSizePopup])
        let row5 = NSStackView(views: [makeLabel("Gravidade:"), gravityPopup])
        let row6 = NSStackView(views: [makeLabel("Paleta de Cores:"), palettePopup])
        let row7 = NSStackView(views: [emptyLeadingView, trailsCheckbox])
        
        for row in [row1, row2, row3, row4, row5, row6, row7] {
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 10
            container.addArrangedSubview(row)
        }
        
        // Spacer
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        container.addArrangedSubview(spacer)
        
        // Bottom Divider
        let bottomDivider = NSBox()
        bottomDivider.boxType = .separator
        bottomDivider.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(bottomDivider)
        bottomDivider.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        
        // Buttons
        let cancelButton = NSButton(title: "Cancelar", target: self, action: #selector(cancelClicked(_:)))
        cancelButton.keyEquivalent = "\u{1b}" // Escape
        
        let okButton = NSButton(title: "OK", target: self, action: #selector(okClicked(_:)))
        okButton.keyEquivalent = "\r" // Enter
        okButton.bezelStyle = .rounded
        okButton.isHighlighted = true
        
        let buttonSpacer = NSView()
        buttonSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let buttonRow = NSStackView(views: [buttonSpacer, cancelButton, okButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 12
        buttonRow.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        container.addArrangedSubview(buttonRow)
    }
    
    @objc private func sliderChanged(_ sender: NSSlider) {
        updateFrequencyText(sender.integerValue)
    }
    
    private func updateFrequencyText(_ value: Int) {
        let label: String
        switch value {
        case 1...2:
            label = "Calmo (\(value)/10)"
        case 3...5:
            label = "Normal (\(value)/10)"
        case 6...8:
            label = "Intenso (\(value)/10)"
        default:
            label = "Festa (\(value)/10)"
        }
        frequencyValueLabel.stringValue = label
    }
    
    public func loadValues() {
        let prefs = PreferencesManager.shared
        frequencySlider.integerValue = prefs.frequency
        updateFrequencyText(prefs.frequency)
        
        rocketSpeedPopup.selectItem(withTag: prefs.rocketSpeed)
        if rocketSpeedPopup.selectedItem == nil {
            rocketSpeedPopup.selectItem(withTag: 2)
        }
        
        particleCountPopup.selectItem(withTag: prefs.particleCount)
        if particleCountPopup.selectedItem == nil {
            particleCountPopup.selectItem(withTag: 80)
        }
        
        let sizeTag = Int(round(prefs.particleSize * 10))
        particleSizePopup.selectItem(withTag: sizeTag)
        if particleSizePopup.selectedItem == nil {
            particleSizePopup.selectItem(withTag: 35)
        }
        
        gravityPopup.selectItem(withTag: prefs.gravity)
        if gravityPopup.selectedItem == nil {
            gravityPopup.selectItem(withTag: 2)
        }
        
        palettePopup.selectItem(withTag: prefs.colorPalette)
        if palettePopup.selectedItem == nil {
            palettePopup.selectItem(withTag: 0)
        }
        
        trailsCheckbox.state = prefs.showTrails ? .on : .off
    }
    
    public func saveValues() {
        let prefs = PreferencesManager.shared
        prefs.frequency = frequencySlider.integerValue
        
        if let selectedSpeed = rocketSpeedPopup.selectedItem?.tag {
            prefs.rocketSpeed = selectedSpeed
        }
        
        if let selectedCount = particleCountPopup.selectedItem?.tag {
            prefs.particleCount = selectedCount
        }
        
        if let selectedSizeTag = particleSizePopup.selectedItem?.tag {
            prefs.particleSize = CGFloat(selectedSizeTag) / 10.0
        }
        
        if let selectedGravity = gravityPopup.selectedItem?.tag {
            prefs.gravity = selectedGravity
        }
        
        if let selectedPalette = palettePopup.selectedItem?.tag {
            prefs.colorPalette = selectedPalette
        }
        
        prefs.showTrails = (trailsCheckbox.state == .on)
    }
    
    @objc private func okClicked(_ sender: Any?) {
        saveValues()
        onSettingsChanged?()
        dismiss(returnCode: .OK)
    }
    
    @objc private func cancelClicked(_ sender: Any?) {
        dismiss(returnCode: .cancel)
    }
    
    private func dismiss(returnCode: NSApplication.ModalResponse) {
        guard let window = self.window else { return }
        if let parent = window.sheetParent {
            parent.endSheet(window, returnCode: returnCode)
        } else {
            window.orderOut(nil)
            window.close()
        }
    }
}

// MARK: - Fireworks ScreenSaver View

@objc(FireworksView)
public class FireworksView: ScreenSaverView {
    private var particles: [Particle] = []
    private var rockets: [Rocket] = []
    
    private var configSheetController: ConfigureSheetController?
    
    // Configurable parameters
    private var frequency: Int = 4
    private var rocketSpeedTag: Int = 2
    private var particleCount: Int = 80
    private var baseParticleSize: CGFloat = 3.5
    private var gravityValue: CGFloat = 0.12
    private var colorPalette: Int = 0
    private var showTrails: Bool = true
    private var activeColors: [NSColor] = []
    
    // Enable "Opções..." button in macOS System Settings
    public override var hasConfigureSheet: Bool {
        return true
    }
    
    public override var configureSheet: NSWindow? {
        if configSheetController == nil {
            configSheetController = ConfigureSheetController()
        }
        configSheetController?.loadValues()
        configSheetController?.onSettingsChanged = { [weak self] in
            self?.reloadSettings()
        }
        return configSheetController?.window
    }

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
        reloadSettings()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 60.0
        reloadSettings()
    }
    
    public func reloadSettings() {
        let prefs = PreferencesManager.shared
        self.frequency = prefs.frequency
        self.rocketSpeedTag = prefs.rocketSpeed
        self.particleCount = prefs.particleCount
        self.baseParticleSize = prefs.particleSize
        self.colorPalette = prefs.colorPalette
        self.showTrails = prefs.showTrails
        self.activeColors = paletteColors(for: prefs.colorPalette)
        
        switch prefs.gravity {
        case 1:
            self.gravityValue = 0.05 // Flutuante / Lua
        case 3:
            self.gravityValue = 0.22 // Pesada
        default:
            self.gravityValue = 0.12 // Normal / Terra
        }
    }
    
    private var rocketSpeedRange: ClosedRange<CGFloat> {
        switch rocketSpeedTag {
        case 1:
            return 7.0 ... 11.0  // Lenta
        case 3:
            return 14.0 ... 20.0 // Rápida
        case 4:
            return 18.0 ... 26.0 // Turbo
        default:
            return 10.0 ... 16.0 // Normal
        }
    }

    private func paletteColors(for palette: Int) -> [NSColor] {
        switch palette {
        case 1: // Dourado & Réveillon
            return [
                NSColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                NSColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 1.0),
                NSColor(red: 0.95, green: 0.77, blue: 0.2, alpha: 1.0),
                NSColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0),
                .white
            ]
        case 2: // Neon / Cyberpunk
            return [
                NSColor(red: 0.0, green: 1.0, blue: 0.95, alpha: 1.0),
                NSColor(red: 1.0, green: 0.05, blue: 0.65, alpha: 1.0),
                NSColor(red: 0.65, green: 0.1, blue: 1.0, alpha: 1.0),
                NSColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 1.0),
                NSColor(red: 1.0, green: 0.95, blue: 0.0, alpha: 1.0)
            ]
        case 3: // Fogo & Brasas
            return [
                NSColor.systemRed,
                NSColor.systemOrange,
                NSColor.systemYellow,
                NSColor(red: 1.0, green: 0.25, blue: 0.0, alpha: 1.0),
                NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
            ]
        case 4: // Gelo & Aurora
            return [
                NSColor.cyan,
                NSColor.systemTeal,
                NSColor(red: 0.1, green: 0.8, blue: 1.0, alpha: 1.0),
                NSColor(red: 0.4, green: 0.95, blue: 0.7, alpha: 1.0),
                NSColor(white: 0.95, alpha: 1.0)
            ]
        default: // Multicolorido
            return [
                .systemRed, .systemGreen, .systemBlue, .systemOrange,
                .systemYellow, .systemPurple, .systemPink, .cyan, .white
            ]
        }
    }

    public override func startAnimation() {
        super.startAnimation()
        reloadSettings()
    }

    public override func stopAnimation() {
        super.stopAnimation()
    }

    public override func animateOneFrame() {
        // Spawn rockets randomly based on frequency
        let spawnChance = UInt32(max(1, frequency))
        let maxRockets = max(2, frequency + 2)
        
        if arc4random_uniform(100) < spawnChance && rockets.count < maxRockets {
            let startX = CGFloat.random(in: bounds.width * 0.1 ... bounds.width * 0.9)
            let targetY = CGFloat.random(in: bounds.height * 0.45 ... bounds.height * 0.85)
            let color = activeColors.randomElement() ?? .systemYellow
            let vy = CGFloat.random(in: rocketSpeedRange)
            rockets.append(Rocket(x: startX, y: 0, vy: vy, targetY: targetY, color: color, exploded: false))
        }

        // Update rockets
        for i in (0 ..< rockets.count).reversed() {
            rockets[i].y += rockets[i].vy
            
            // Spark trail
            if showTrails {
                let spark = Particle(
                    x: rockets[i].x + CGFloat.random(in: -1 ... 1),
                    y: rockets[i].y - 3,
                    vx: CGFloat.random(in: -0.3 ... 0.3),
                    vy: CGFloat.random(in: -2.0 ... -0.6),
                    alpha: 0.75,
                    color: NSColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 0.8),
                    size: 2.0,
                    decay: 0.04
                )
                particles.append(spark)
            }
            
            if rockets[i].y >= rockets[i].targetY {
                explode(rocket: rockets[i])
                rockets.remove(at: i)
            }
        }

        // Update particles
        let g = gravityValue
        for i in (0 ..< particles.count).reversed() {
            particles[i].x += particles[i].vx
            particles[i].y += particles[i].vy
            particles[i].vy -= g
            particles[i].alpha -= particles[i].decay
            if particles[i].alpha <= 0 {
                particles.remove(at: i)
            }
        }

        needsDisplay = true
    }

    private func explode(rocket: Rocket) {
        let minCount = max(20, Int(Double(particleCount) * 0.75))
        let maxCount = max(minCount + 10, Int(Double(particleCount) * 1.25))
        let count = Int.random(in: minCount ... maxCount)
        let baseColor = rocket.color
        for _ in 0 ..< count {
            let angle = CGFloat.random(in: 0 ... 2 * .pi)
            let speed = CGFloat.random(in: 2 ... 7.5)
            let sizeVariation = CGFloat.random(in: 0.8 ... 1.25)
            let p = Particle(
                x: rocket.x,
                y: rocket.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                alpha: 1.0,
                color: baseColor,
                size: baseParticleSize * sizeVariation,
                decay: CGFloat.random(in: 0.012 ... 0.025)
            )
            particles.append(p)
        }
    }

    public override func draw(_ rect: NSRect) {
        // Black background
        NSColor.black.setFill()
        rect.fill()

        // Draw rockets
        for rocket in rockets {
            let rRect = NSRect(x: rocket.x - 2, y: rocket.y - 4, width: 4, height: 8)
            rocket.color.setFill()
            let path = NSBezierPath(ovalIn: rRect)
            path.fill()
        }

        // Draw particles
        for p in particles {
            let pRect = NSRect(x: p.x - p.size / 2, y: p.y - p.size / 2, width: p.size, height: p.size)
            p.color.withAlphaComponent(p.alpha).setFill()
            let path = NSBezierPath(ovalIn: pRect)
            path.fill()
        }
    }
}
