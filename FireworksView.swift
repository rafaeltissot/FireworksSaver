import Foundation
import ScreenSaver
import AppKit
import QuartzCore

// MARK: - Models

public struct RGBColor {
    public var r: CGFloat
    public var g: CGFloat
    public var b: CGFloat
    
    public init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.r = r
        self.g = g
        self.b = b
    }
}

struct Particle {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var alpha: CGFloat
    var imageIndex: Int
    var size: CGFloat
    var decay: CGFloat
    var friction: CGFloat
}

struct Rocket {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var targetY: CGFloat
    var imageIndex: Int
    var trailTimer: CGFloat
}

struct PooledLayerState {
    var imageIndex: Int = -1
    var width: CGFloat = 0
    var height: CGFloat = 0
    var isHidden: Bool = true
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
            "showClock": true,       // Exibir relógio estilo Fliqlo
            "clockFormat24": true,   // true = 24h, false = 12h
            "clockScale": 2,         // 1=Pequeno (75%), 2=Médio (100%), 3=Grande (125%)
            "frequency": 3,          // 1..10 (3 = Equilibrado e econômico)
            "rocketSpeed": 2,        // 1=Lenta, 2=Normal, 3=Rápida, 4=Turbo
            "particleCount": 80,     // 50, 80, 140, 220
            "particleSize": 3.5,     // 2.5, 3.5, 5.0
            "gravity": 2,            // 1=Flutuante (Lua), 2=Normal (Terra), 3=Pesada
            "colorPalette": 0,       // 0..4
            "showTrails": true,      // true/false
            "fpsMode": 30            // 30=Eco/Silencioso (Padrão), 45=Equilibrado, 60=Máximo
        ])
    }
    
    public var showClock: Bool {
        get {
            if defaults.object(forKey: "showClock") == nil { return true }
            return defaults.bool(forKey: "showClock")
        }
        set {
            defaults.set(newValue, forKey: "showClock")
            defaults.synchronize()
        }
    }
    
    public var clockFormat24: Bool {
        get {
            if defaults.object(forKey: "clockFormat24") == nil { return true }
            return defaults.bool(forKey: "clockFormat24")
        }
        set {
            defaults.set(newValue, forKey: "clockFormat24")
            defaults.synchronize()
        }
    }
    
    public var clockScale: Int {
        get {
            let val = defaults.integer(forKey: "clockScale")
            return val > 0 ? val : 2
        }
        set {
            defaults.set(newValue, forKey: "clockScale")
            defaults.synchronize()
        }
    }
    
    public var frequency: Int {
        get {
            let val = defaults.integer(forKey: "frequency")
            return val > 0 ? val : 3
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
    
    public var fpsMode: Int {
        get {
            let val = defaults.integer(forKey: "fpsMode")
            return (val == 30 || val == 45 || val == 60) ? val : 30
        }
        set {
            defaults.set(newValue, forKey: "fpsMode")
            defaults.synchronize()
        }
    }
}

// MARK: - Configuration Sheet Controller

public class ConfigureSheetController: NSWindowController {
    public var onSettingsChanged: (() -> Void)?
    
    private var showClockCheckbox: NSButton!
    private var clockFormatPopup: NSPopUpButton!
    private var clockScalePopup: NSPopUpButton!
    
    private var frequencySlider: NSSlider!
    private var frequencyValueLabel: NSTextField!
    private var rocketSpeedPopup: NSPopUpButton!
    private var particleCountPopup: NSPopUpButton!
    private var particleSizePopup: NSPopUpButton!
    private var gravityPopup: NSPopUpButton!
    private var palettePopup: NSPopUpButton!
    private var fpsPopup: NSPopUpButton!
    private var trailsCheckbox: NSButton!
    
    public init() {
        let sheetWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 490, height: 545),
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
        container.spacing = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Header
        let titleLabel = NSTextField(labelWithString: "Fogos de Artifício & Relógio")
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        
        let subtitleLabel = NSTextField(labelWithString: "Protetor de tela leve com aceleração via GPU Core Animation.")
        subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        
        let headerStack = NSStackView(views: [titleLabel, subtitleLabel])
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 2
        container.addArrangedSubview(headerStack)
        
        func addSeparator() {
            let sep = NSBox()
            sep.boxType = .separator
            container.addArrangedSubview(sep)
            sep.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            sep.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        }
        
        addSeparator()
        
        let labelColumnWidth: CGFloat = 160
        let controlWidth: CGFloat = 230
        
        func makeLabel(_ text: String) -> NSTextField {
            let lbl = NSTextField(labelWithString: text)
            lbl.alignment = .right
            lbl.widthAnchor.constraint(equalToConstant: labelColumnWidth).isActive = true
            return lbl
        }
        
        let emptyLeadingView1 = NSView()
        emptyLeadingView1.widthAnchor.constraint(equalToConstant: labelColumnWidth).isActive = true
        
        // --- SEÇÃO RELÓGIO FLIQLO ---
        showClockCheckbox = NSButton(checkboxWithTitle: "Exibir relógio na tela (Estilo Fliqlo)", target: nil, action: nil)
        
        clockFormatPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        clockFormatPopup.addItem(withTitle: "24 horas (ex: 14:30)")
        clockFormatPopup.lastItem?.tag = 1
        clockFormatPopup.addItem(withTitle: "12 horas (ex: 02:30 PM)")
        clockFormatPopup.lastItem?.tag = 2
        clockFormatPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        clockScalePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        clockScalePopup.addItem(withTitle: "Pequeno (75%)")
        clockScalePopup.lastItem?.tag = 1
        clockScalePopup.addItem(withTitle: "Médio [Padrão]")
        clockScalePopup.lastItem?.tag = 2
        clockScalePopup.addItem(withTitle: "Grande (125%)")
        clockScalePopup.lastItem?.tag = 3
        clockScalePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        let clockRow1 = NSStackView(views: [emptyLeadingView1, showClockCheckbox])
        let clockRow2 = NSStackView(views: [makeLabel("Formato do Relógio:"), clockFormatPopup])
        let clockRow3 = NSStackView(views: [makeLabel("Tamanho do Relógio:"), clockScalePopup])
        
        for row in [clockRow1, clockRow2, clockRow3] {
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 10
            container.addArrangedSubview(row)
        }
        
        addSeparator()
        
        // --- SEÇÃO FOGOS DE ARTIFÍCIO ---
        frequencySlider = NSSlider(value: 3, minValue: 1, maxValue: 10, target: self, action: #selector(sliderChanged(_:)))
        frequencySlider.isContinuous = true
        frequencySlider.numberOfTickMarks = 10
        frequencySlider.allowsTickMarkValuesOnly = true
        frequencySlider.widthAnchor.constraint(equalToConstant: 130).isActive = true
        
        frequencyValueLabel = NSTextField(labelWithString: "Normal (3/10)")
        frequencyValueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        frequencyValueLabel.textColor = .secondaryLabelColor
        
        let freqStack = NSStackView(views: [frequencySlider, frequencyValueLabel])
        freqStack.orientation = .horizontal
        freqStack.spacing = 8
        freqStack.alignment = .centerY
        
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
        
        particleCountPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        particleCountPopup.addItem(withTitle: "Leve (~40 partículas)")
        particleCountPopup.lastItem?.tag = 50
        particleCountPopup.addItem(withTitle: "Equilibrado (~70 partículas)")
        particleCountPopup.lastItem?.tag = 80
        particleCountPopup.addItem(withTitle: "Intenso (~120 partículas)")
        particleCountPopup.lastItem?.tag = 140
        particleCountPopup.addItem(withTitle: "Espetacular (~180 partículas)")
        particleCountPopup.lastItem?.tag = 220
        particleCountPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        particleSizePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        particleSizePopup.addItem(withTitle: "Pequenas (2.5 px)")
        particleSizePopup.lastItem?.tag = 25
        particleSizePopup.addItem(withTitle: "Médias (3.5 px)")
        particleSizePopup.lastItem?.tag = 35
        particleSizePopup.addItem(withTitle: "Grandes (5.0 px)")
        particleSizePopup.lastItem?.tag = 50
        particleSizePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        gravityPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        gravityPopup.addItem(withTitle: "Flutuante / Suave (Lua)")
        gravityPopup.lastItem?.tag = 1
        gravityPopup.addItem(withTitle: "Normal [Terra]")
        gravityPopup.lastItem?.tag = 2
        gravityPopup.addItem(withTitle: "Pesada / Rápida")
        gravityPopup.lastItem?.tag = 3
        gravityPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        palettePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        palettePopup.addItem(withTitle: "Multicolorido Vibrante (20 cores)")
        palettePopup.lastItem?.tag = 0
        palettePopup.addItem(withTitle: "Dourado & Réveillon")
        palettePopup.lastItem?.tag = 1
        palettePopup.addItem(withTitle: "Neon / Cyberpunk")
        palettePopup.lastItem?.tag = 2
        palettePopup.addItem(withTitle: "Fogo & Brasas")
        palettePopup.lastItem?.tag = 3
        palettePopup.addItem(withTitle: "Gelo & Aurora Boreal")
        palettePopup.lastItem?.tag = 4
        palettePopup.addItem(withTitle: "Carnaval / Tropical")
        palettePopup.lastItem?.tag = 5
        palettePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        fpsPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        fpsPopup.addItem(withTitle: "Econômico / Silencioso (30 FPS)")
        fpsPopup.lastItem?.tag = 30
        fpsPopup.addItem(withTitle: "Equilibrado (45 FPS)")
        fpsPopup.lastItem?.tag = 45
        fpsPopup.addItem(withTitle: "Máximo (60 FPS)")
        fpsPopup.lastItem?.tag = 60
        fpsPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        
        trailsCheckbox = NSButton(checkboxWithTitle: "Exibir rastro cintilante na subida", target: nil, action: nil)
        
        let emptyLeadingView2 = NSView()
        emptyLeadingView2.widthAnchor.constraint(equalToConstant: labelColumnWidth).isActive = true
        
        let fwRow1 = NSStackView(views: [makeLabel("Frequência de Foguetes:"), freqStack])
        let fwRow2 = NSStackView(views: [makeLabel("Velocidade dos Foguetes:"), rocketSpeedPopup])
        let fwRow3 = NSStackView(views: [makeLabel("Qtd. de Partículas:"), particleCountPopup])
        let fwRow4 = NSStackView(views: [makeLabel("Tamanho das Partículas:"), particleSizePopup])
        let fwRow5 = NSStackView(views: [makeLabel("Gravidade:"), gravityPopup])
        let fwRow6 = NSStackView(views: [makeLabel("Paleta de Cores:"), palettePopup])
        let fwRow7 = NSStackView(views: [makeLabel("Modo de Energia:"), fpsPopup])
        let fwRow8 = NSStackView(views: [emptyLeadingView2, trailsCheckbox])
        
        for row in [fwRow1, fwRow2, fwRow3, fwRow4, fwRow5, fwRow6, fwRow7, fwRow8] {
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 10
            container.addArrangedSubview(row)
        }
        
        // Spacer
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        container.addArrangedSubview(spacer)
        
        addSeparator()
        
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
        container.addArrangedSubview(buttonRow)
        buttonRow.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        buttonRow.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
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
        
        showClockCheckbox.state = prefs.showClock ? .on : .off
        clockFormatPopup.selectItem(withTag: prefs.clockFormat24 ? 1 : 2)
        clockScalePopup.selectItem(withTag: prefs.clockScale)
        
        frequencySlider.integerValue = prefs.frequency
        updateFrequencyText(prefs.frequency)
        
        rocketSpeedPopup.selectItem(withTag: prefs.rocketSpeed)
        if rocketSpeedPopup.selectedItem == nil { rocketSpeedPopup.selectItem(withTag: 2) }
        
        particleCountPopup.selectItem(withTag: prefs.particleCount)
        if particleCountPopup.selectedItem == nil { particleCountPopup.selectItem(withTag: 80) }
        
        let sizeTag = Int(round(prefs.particleSize * 10))
        particleSizePopup.selectItem(withTag: sizeTag)
        if particleSizePopup.selectedItem == nil { particleSizePopup.selectItem(withTag: 35) }
        
        gravityPopup.selectItem(withTag: prefs.gravity)
        if gravityPopup.selectedItem == nil { gravityPopup.selectItem(withTag: 2) }
        
        palettePopup.selectItem(withTag: prefs.colorPalette)
        if palettePopup.selectedItem == nil { palettePopup.selectItem(withTag: 0) }
        
        fpsPopup.selectItem(withTag: prefs.fpsMode)
        if fpsPopup.selectedItem == nil { fpsPopup.selectItem(withTag: 30) }
        
        trailsCheckbox.state = prefs.showTrails ? .on : .off
    }
    
    public func saveValues() {
        let prefs = PreferencesManager.shared
        
        prefs.showClock = (showClockCheckbox.state == .on)
        prefs.clockFormat24 = (clockFormatPopup.selectedItem?.tag == 1)
        if let selScale = clockScalePopup.selectedItem?.tag { prefs.clockScale = selScale }
        
        prefs.frequency = frequencySlider.integerValue
        if let selectedSpeed = rocketSpeedPopup.selectedItem?.tag { prefs.rocketSpeed = selectedSpeed }
        if let selectedCount = particleCountPopup.selectedItem?.tag { prefs.particleCount = selectedCount }
        if let selectedSizeTag = particleSizePopup.selectedItem?.tag { prefs.particleSize = CGFloat(selectedSizeTag) / 10.0 }
        if let selectedGravity = gravityPopup.selectedItem?.tag { prefs.gravity = selectedGravity }
        if let selectedPalette = palettePopup.selectedItem?.tag { prefs.colorPalette = selectedPalette }
        if let selectedFps = fpsPopup.selectedItem?.tag { prefs.fpsMode = selectedFps }
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

// MARK: - Fireworks ScreenSaver View (Hardware CALayer Architecture)

@objc(FireworksView)
public class FireworksView: ScreenSaverView {
    private static let maxPoolSize = 380
    
    private var particles: [Particle] = []
    private var rockets: [Rocket] = []
    private var lastFrameTime: CFTimeInterval = 0
    private var lastClockCheckTime: CFTimeInterval = 0
    private var spawnAccumulator: CGFloat = 0
    
    private var configSheetController: ConfigureSheetController?
    
    // Hardware-composited layers (No draw(_ rect:) full-screen CPU bitmap!)
    private let hourCardLayer = CALayer()
    private let minuteCardLayer = CALayer()
    private let fireworksContainerLayer = CALayer()
    private var particleLayers: [CALayer] = []
    private var layerStates: [PooledLayerState] = []
    private var previousActiveLayerCount: Int = 0
    private var lastLayoutBounds: CGRect = .zero
    
    // Pre-rendered 16x16 circle textures for palette colors + spark + white flash
    private var dotImages: [CGImage] = []
    private var sparkImageIndex: Int = 0
    private var whiteImageIndex: Int = 0
    
    // Configurable parameters
    private var showClock: Bool = true
    private var clockFormat24: Bool = true
    private var clockScale: Int = 2
    
    private var frequency: Int = 3
    private var rocketSpeedTag: Int = 2
    private var particleCount: Int = 80
    private var baseParticleSize: CGFloat = 3.5
    private var gravityValue: CGFloat = 0.12
    private var colorPalette: Int = 0
    private var showTrails: Bool = true
    private var activeColors: [RGBColor] = []
    
    // Flip Clock state tracking
    private var currentHourStr: String = ""
    private var previousHourStr: String = ""
    private var hourFlipStartTime: CFTimeInterval = 0
    private var isHourFlipping: Bool = false
    
    private var currentMinuteStr: String = ""
    private var previousMinuteStr: String = ""
    private var minuteFlipStartTime: CFTimeInterval = 0
    private var isMinuteFlipping: Bool = false
    
    private var currentAmPmStr: String? = nil
    private var clockNeedsRedraw: Bool = true
    
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
    
    public override var isOpaque: Bool {
        return true
    }

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupEngine()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEngine()
    }
    
    private func setupEngine() {
        particles.reserveCapacity(Self.maxPoolSize)
        rockets.reserveCapacity(16)
        
        wantsLayer = true
        guard let rootLayer = self.layer else { return }
        rootLayer.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        rootLayer.isOpaque = true
        
        // Setup Clock Card Layers (cached in VRAM, redrawn only once per minute)
        hourCardLayer.contentsGravity = .resizeAspectFill
        minuteCardLayer.contentsGravity = .resizeAspectFill
        rootLayer.addSublayer(hourCardLayer)
        rootLayer.addSublayer(minuteCardLayer)
        
        // Setup Fireworks Layer Pool
        rootLayer.addSublayer(fireworksContainerLayer)
        particleLayers.reserveCapacity(Self.maxPoolSize)
        layerStates.reserveCapacity(Self.maxPoolSize)
        
        for _ in 0 ..< Self.maxPoolSize {
            let pLayer = CALayer()
            pLayer.isHidden = true
            fireworksContainerLayer.addSublayer(pLayer)
            particleLayers.append(pLayer)
            layerStates.append(PooledLayerState())
        }
        
        reloadSettings()
    }
    
    public override func layout() {
        super.layout()
        if bounds != lastLayoutBounds {
            lastLayoutBounds = bounds
            updateClockLayerFrames()
            clockNeedsRedraw = true
            renderClockLayersIfNeeded(now: CACurrentMediaTime(), force: true)
        }
    }
    
    public func reloadSettings() {
        let prefs = PreferencesManager.shared
        self.showClock = prefs.showClock
        self.clockFormat24 = prefs.clockFormat24
        self.clockScale = prefs.clockScale
        
        self.frequency = prefs.frequency
        self.rocketSpeedTag = prefs.rocketSpeed
        self.particleCount = prefs.particleCount
        self.baseParticleSize = prefs.particleSize
        self.colorPalette = prefs.colorPalette
        self.showTrails = prefs.showTrails
        self.activeColors = paletteColors(for: prefs.colorPalette)
        
        let fps = Double(prefs.fpsMode)
        self.animationTimeInterval = 1.0 / fps
        
        switch prefs.gravity {
        case 1:
            self.gravityValue = 0.05 // Flutuante / Lua
        case 3:
            self.gravityValue = 0.22 // Pesada
        default:
            self.gravityValue = 0.12 // Normal / Terra
        }
        
        rebuildDotTextures()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        hourCardLayer.isHidden = !showClock
        minuteCardLayer.isHidden = !showClock
        updateClockLayerFrames()
        CATransaction.commit()
        
        // Force clock refresh on format/scale change
        currentHourStr = ""
        currentMinuteStr = ""
        clockNeedsRedraw = true
        updateClockTime(now: CACurrentMediaTime(), force: true)
        renderClockLayersIfNeeded(now: CACurrentMediaTime(), force: true)
    }
    
    private func rebuildDotTextures() {
        dotImages.removeAll()
        for c in activeColors {
            if let img = Self.makeGlowingDotImage(r: c.r, g: c.g, b: c.b) {
                dotImages.append(img)
            }
        }
        // Append golden spark texture
        sparkImageIndex = dotImages.count
        if let sparkImg = Self.makeGlowingDotImage(r: 1.0, g: 0.82, b: 0.35) {
            dotImages.append(sparkImg)
        }
        // Append white-hot core texture
        whiteImageIndex = dotImages.count
        if let whiteImg = Self.makeGlowingDotImage(r: 1.0, g: 1.0, b: 1.0) {
            dotImages.append(whiteImg)
        }
        
        // Reset cached imageIndex in layerStates so layers pick up new palette textures
        for i in 0 ..< layerStates.count {
            layerStates[i].imageIndex = -1
        }
    }
    
    private static func makeGlowingDotImage(r: CGFloat, g: CGFloat, b: CGFloat) -> CGImage? {
        let size = 16
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        
        // Soft outer halo
        ctx.setFillColor(red: r, green: g, blue: b, alpha: 0.35)
        ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: 16, height: 16))
        
        // Bright inner core
        ctx.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
        ctx.fillEllipse(in: CGRect(x: 2.5, y: 2.5, width: 11, height: 11))
        
        return ctx.makeImage()
    }
    
    private var rocketSpeedRange: ClosedRange<CGFloat> {
        switch rocketSpeedTag {
        case 1:
            return 9.0 ... 13.0  // Lenta
        case 3:
            return 16.0 ... 22.0 // Rápida
        case 4:
            return 21.0 ... 28.0 // Turbo
        default:
            return 12.0 ... 17.0 // Normal
        }
    }

    private func paletteColors(for palette: Int) -> [RGBColor] {
        switch palette {
        case 1: // Dourado & Réveillon (8 tons de ouro, champanhe, âmbar e prata)
            return [
                RGBColor(r: 1.00, g: 0.84, b: 0.00), // Ouro Clássico
                RGBColor(r: 1.00, g: 0.93, b: 0.58), // Champanhe Brilhante
                RGBColor(r: 0.98, g: 0.72, b: 0.12), // Âmbar Imperial
                RGBColor(r: 1.00, g: 0.62, b: 0.18), // Bronze Quente
                RGBColor(r: 1.00, g: 0.88, b: 0.75), // Ouro Rosé
                RGBColor(r: 0.88, g: 0.92, b: 1.00), // Prata Estelar
                RGBColor(r: 0.96, g: 0.95, b: 0.82), // Pérola
                RGBColor(r: 1.00, g: 1.00, b: 1.00)  // Branco Diamante
            ]
        case 2: // Neon / Cyberpunk (10 tons elétricos de alta saturação)
            return [
                RGBColor(r: 0.00, g: 1.00, b: 0.96), // Ciano Laser
                RGBColor(r: 1.00, g: 0.05, b: 0.68), // Magenta Elétrico
                RGBColor(r: 0.68, g: 0.12, b: 1.00), // Roxo Ultravioleta
                RGBColor(r: 0.15, g: 1.00, b: 0.35), // Verde Matrix
                RGBColor(r: 1.00, g: 0.96, b: 0.00), // Amarelo Ácido
                RGBColor(r: 1.00, g: 0.20, b: 0.38), // Rosa Choque Neon
                RGBColor(r: 0.18, g: 0.50, b: 1.00), // Azul Elétrico
                RGBColor(r: 1.00, g: 0.45, b: 0.00), // Laranja Fluorescente
                RGBColor(r: 0.55, g: 1.00, b: 0.00), // Lima Radioativo
                RGBColor(r: 0.88, g: 0.40, b: 1.00)  // Orquídea Neon
            ]
        case 3: // Fogo & Brasas (8 tons vulcânicos e solares)
            return [
                RGBColor(r: 1.00, g: 0.14, b: 0.04), // Vermelho Vulcão
                RGBColor(r: 1.00, g: 0.32, b: 0.00), // Laranja Labareda
                RGBColor(r: 1.00, g: 0.52, b: 0.00), // Âmbar Solar
                RGBColor(r: 1.00, g: 0.74, b: 0.08), // Ouro de Forja
                RGBColor(r: 1.00, g: 0.90, b: 0.25), // Chama Amarela
                RGBColor(r: 0.92, g: 0.08, b: 0.18), // Carmesim Profundo
                RGBColor(r: 1.00, g: 0.42, b: 0.28), // Coral Brasa
                RGBColor(r: 1.00, g: 0.96, b: 0.75)  // Incandescente
            ]
        case 4: // Gelo & Aurora Boreal (8 tons polares e magnéticos)
            return [
                RGBColor(r: 0.00, g: 0.96, b: 1.00), // Ciano Ártico
                RGBColor(r: 0.12, g: 0.76, b: 0.98), // Azul Glacial
                RGBColor(r: 0.20, g: 1.00, b: 0.68), // Verde Aurora
                RGBColor(r: 0.48, g: 1.00, b: 0.85), // Menta Polar
                RGBColor(r: 0.52, g: 0.42, b: 1.00), // Índigo Magnético
                RGBColor(r: 0.78, g: 0.48, b: 1.00), // Violeta Boreal
                RGBColor(r: 0.65, g: 0.88, b: 1.00), // Gelo Cristalino
                RGBColor(r: 0.95, g: 0.99, b: 1.00)  // Neve Brilhante
            ]
        case 5: // Carnaval / Tropical (10 tons quentes e festivos)
            return [
                RGBColor(r: 1.00, g: 0.16, b: 0.52), // Rosa Tropical
                RGBColor(r: 0.00, g: 0.92, b: 0.76), // Turquesa Caribe
                RGBColor(r: 1.00, g: 0.82, b: 0.00), // Sol Dourado
                RGBColor(r: 0.52, g: 0.96, b: 0.12), // Verde Limão
                RGBColor(r: 1.00, g: 0.42, b: 0.10), // Tangerina
                RGBColor(r: 0.72, g: 0.24, b: 1.00), // Açaí / Púrpura
                RGBColor(r: 0.00, g: 0.68, b: 1.00), // Azul Oceano
                RGBColor(r: 1.00, g: 0.36, b: 0.38), // Goiaba / Coral
                RGBColor(r: 0.98, g: 0.94, b: 0.25), // Abacaxi
                RGBColor(r: 1.00, g: 0.55, b: 0.85)  // Hibisco
            ]
        default: // Multicolorido Vibrante (20 cores de espectro completo)
            return [
                RGBColor(r: 1.00, g: 0.18, b: 0.18), // 1. Vermelho Rubi
                RGBColor(r: 1.00, g: 0.38, b: 0.08), // 2. Laranja Fogo
                RGBColor(r: 1.00, g: 0.60, b: 0.00), // 3. Âmbar Vibrante
                RGBColor(r: 1.00, g: 0.84, b: 0.00), // 4. Ouro Real
                RGBColor(r: 0.96, g: 1.00, b: 0.15), // 5. Amarelo Limão
                RGBColor(r: 0.55, g: 1.00, b: 0.18), // 6. Verde Lima
                RGBColor(r: 0.15, g: 0.92, b: 0.32), // 7. Verde Esmeralda
                RGBColor(r: 0.00, g: 0.96, b: 0.68), // 8. Água-Marinha
                RGBColor(r: 0.00, g: 0.92, b: 0.98), // 9. Ciano Elétrico
                RGBColor(r: 0.12, g: 0.68, b: 1.00), // 10. Azul Celeste
                RGBColor(r: 0.18, g: 0.40, b: 1.00), // 11. Azul Safira
                RGBColor(r: 0.45, g: 0.28, b: 1.00), // 12. Índigo Profundo
                RGBColor(r: 0.72, g: 0.22, b: 1.00), // 13. Violeta Ametista
                RGBColor(r: 0.92, g: 0.25, b: 1.00), // 14. Fúcsia Brilhante
                RGBColor(r: 1.00, g: 0.15, b: 0.65), // 15. Pink Choque
                RGBColor(r: 1.00, g: 0.28, b: 0.45), // 16. Melancia
                RGBColor(r: 1.00, g: 0.52, b: 0.42), // 17. Salmão / Coral
                RGBColor(r: 1.00, g: 0.78, b: 0.88), // 18. Rosa Cerejeira
                RGBColor(r: 0.78, g: 0.92, b: 1.00), // 19. Azul Diamante
                RGBColor(r: 1.00, g: 1.00, b: 1.00)  // 20. Branco Estelar
            ]
        }
    }

    public override func startAnimation() {
        super.startAnimation()
        lastFrameTime = CACurrentMediaTime()
        reloadSettings()
    }

    public override func stopAnimation() {
        super.stopAnimation()
        rockets.removeAll()
        particles.removeAll()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for i in 0 ..< previousActiveLayerCount {
            particleLayers[i].isHidden = true
            layerStates[i].isHidden = true
        }
        previousActiveLayerCount = 0
        CATransaction.commit()
    }

    public override func animateOneFrame() {
        guard bounds.width > 10 && bounds.height > 10 else { return }
        
        let now = CACurrentMediaTime()
        let dt: CGFloat
        if lastFrameTime == 0 {
            dt = CGFloat(animationTimeInterval)
        } else {
            dt = min(max(CGFloat(now - lastFrameTime), 0.005), 0.1)
        }
        lastFrameTime = now
        
        // Factor normalized to 60Hz baseline so physics speed is identical at 30, 45, or 60 FPS
        let factor = dt * 60.0
        
        // 1. Update Clock (checks Date only every 0.5s or while flipping)
        if showClock {
            if isHourFlipping || isMinuteFlipping || (now - lastClockCheckTime >= 0.5) {
                lastClockCheckTime = now
                updateClockTime(now: now, force: false)
            }
            if clockNeedsRedraw || isHourFlipping || isMinuteFlipping {
                renderClockLayersIfNeeded(now: now, force: false)
            }
        }
        
        // 2. Spawn rockets with natural rhythm (frame-rate independent)
        // frequency 1..10 -> ~0.35 to 3.5 rockets per second
        let maxRockets = max(2, (frequency + 1) / 2 + 1)
        let rocketsPerSec = CGFloat(frequency) * 0.35
        spawnAccumulator += rocketsPerSec * dt
        
        if spawnAccumulator >= 1.0 {
            spawnAccumulator -= 1.0
            if rockets.count < maxRockets && particles.count < (Self.maxPoolSize - 40) {
                let startX = CGFloat.random(in: bounds.width * 0.12 ... bounds.width * 0.88)
                let targetY = CGFloat.random(in: bounds.height * 0.50 ... bounds.height * 0.86)
                let colorIdx = activeColors.isEmpty ? 0 : Int.random(in: 0 ..< activeColors.count)
                let vy = CGFloat.random(in: rocketSpeedRange)
                let vx = CGFloat.random(in: -0.5 ... 0.5)
                rockets.append(Rocket(x: startX, y: 0, vx: vx, vy: vy, targetY: targetY, imageIndex: colorIdx, trailTimer: 0))
            }
        } else if rockets.isEmpty && particles.isEmpty && CGFloat.random(in: 0...1) < (rocketsPerSec * dt) {
            let startX = CGFloat.random(in: bounds.width * 0.12 ... bounds.width * 0.88)
            let targetY = CGFloat.random(in: bounds.height * 0.50 ... bounds.height * 0.86)
            let colorIdx = activeColors.isEmpty ? 0 : Int.random(in: 0 ..< activeColors.count)
            let vy = CGFloat.random(in: rocketSpeedRange)
            let vx = CGFloat.random(in: -0.5 ... 0.5)
            rockets.append(Rocket(x: startX, y: 0, vx: vx, vy: vy, targetY: targetY, imageIndex: colorIdx, trailTimer: 0))
        }

        // Fast exit if nothing is moving on screen (0% CPU idle state)
        if rockets.isEmpty && particles.isEmpty && previousActiveLayerCount == 0 {
            return
        }

        // 3. Update rockets
        for i in (0 ..< rockets.count).reversed() {
            rockets[i].x += rockets[i].vx * factor
            rockets[i].y += rockets[i].vy * factor
            rockets[i].vy -= 0.12 * factor
            rockets[i].trailTimer += factor
            
            if showTrails && rockets[i].trailTimer >= 1.8 && particles.count < (Self.maxPoolSize - 10) {
                rockets[i].trailTimer = 0
                let spark = Particle(
                    x: rockets[i].x + CGFloat.random(in: -1.2 ... 1.2),
                    y: rockets[i].y - 3.5,
                    vx: CGFloat.random(in: -0.45 ... 0.45),
                    vy: CGFloat.random(in: -1.8 ... -0.5),
                    alpha: CGFloat.random(in: 0.70 ... 0.92),
                    imageIndex: sparkImageIndex,
                    size: 4.0,
                    decay: CGFloat.random(in: 0.032 ... 0.052),
                    friction: 0.94
                )
                particles.append(spark)
            }
            
            if rockets[i].vy <= 1.0 || rockets[i].y >= rockets[i].targetY {
                explode(rocket: rockets[i])
                rockets.remove(at: i)
            }
        }

        // 4. Update particles
        let g = gravityValue * factor
        for i in (0 ..< particles.count).reversed() {
            let f = pow(particles[i].friction, factor)
            particles[i].vx *= f
            particles[i].vy *= f
            particles[i].vy -= g
            particles[i].x += particles[i].vx * factor
            particles[i].y += particles[i].vy * factor
            particles[i].alpha -= particles[i].decay * factor
            
            if particles[i].alpha <= 0.02 {
                particles.remove(at: i)
            }
        }

        // 5. Commit positions to Hardware CALayer Pool (Zero bitmap rasterization)
        syncParticleLayers()
    }
    
    private func syncParticleLayers() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        var layerIdx = 0
        let totalImages = dotImages.count
        
        // Assign layers for active rockets
        for rocket in rockets {
            guard layerIdx < Self.maxPoolSize else { break }
            let layer = particleLayers[layerIdx]
            
            if layerStates[layerIdx].isHidden {
                layer.isHidden = false
                layerStates[layerIdx].isHidden = false
            }
            if layerStates[layerIdx].imageIndex != rocket.imageIndex && rocket.imageIndex < totalImages {
                layer.contents = dotImages[rocket.imageIndex]
                layerStates[layerIdx].imageIndex = rocket.imageIndex
            }
            if layerStates[layerIdx].width != 6.5 || layerStates[layerIdx].height != 11.0 {
                layer.bounds = CGRect(x: 0, y: 0, width: 6.5, height: 11.0)
                layerStates[layerIdx].width = 6.5
                layerStates[layerIdx].height = 11.0
            }
            layer.position = CGPoint(x: rocket.x, y: rocket.y)
            layer.opacity = 1.0
            layerIdx += 1
        }
        
        // Assign layers for active particles
        for p in particles {
            guard layerIdx < Self.maxPoolSize else { break }
            let layer = particleLayers[layerIdx]
            
            if layerStates[layerIdx].isHidden {
                layer.isHidden = false
                layerStates[layerIdx].isHidden = false
            }
            if layerStates[layerIdx].imageIndex != p.imageIndex && p.imageIndex < totalImages {
                layer.contents = dotImages[p.imageIndex]
                layerStates[layerIdx].imageIndex = p.imageIndex
            }
            let sz = p.size
            if abs(layerStates[layerIdx].width - sz) > 0.25 || abs(layerStates[layerIdx].height - sz) > 0.25 {
                layer.bounds = CGRect(x: 0, y: 0, width: sz, height: sz)
                layerStates[layerIdx].width = sz
                layerStates[layerIdx].height = sz
            }
            layer.position = CGPoint(x: p.x, y: p.y)
            layer.opacity = Float(p.alpha)
            layerIdx += 1
        }
        
        // Hide only layers that were active on the previous frame and are no longer active
        if layerIdx < previousActiveLayerCount {
            for i in layerIdx ..< previousActiveLayerCount {
                if !layerStates[i].isHidden {
                    particleLayers[i].isHidden = true
                    layerStates[i].isHidden = true
                }
            }
        }
        previousActiveLayerCount = layerIdx
        
        CATransaction.commit()
    }

    private func explode(rocket: Rocket) {
        let availableSlots = max(0, Self.maxPoolSize - particles.count - rockets.count)
        guard availableSlots > 10 else { return }
        
        let targetCount = min(availableSlots - 6, particleCount)
        let minCount = max(20, Int(Double(targetCount) * 0.85))
        let maxCount = max(minCount + 5, min(availableSlots - 6, Int(Double(targetCount) * 1.20)))
        let count = Int.random(in: minCount ... maxCount)
        
        // Scale burst velocity proportionally to screen height so explosions look grand on full-screen and balanced in preview
        let screenScale = max(0.80, min(1.35, bounds.height / 850.0))
        let visualBaseSize = baseParticleSize * 1.65
        let paletteCount = max(1, activeColors.count)
        
        // Choose secondary & tertiary colors for rich multi-color bursts
        let primaryColorIdx = rocket.imageIndex
        let secondaryColorIdx = (primaryColorIdx + Int.random(in: 1 ..< max(2, paletteCount))) % paletteCount
        let tertiaryColorIdx = (secondaryColorIdx + Int.random(in: 1 ..< max(2, paletteCount))) % paletteCount
        
        // Explosion style:
        // 0 = Bi-color concentric peony (inner + outer ring)
        // 1 = Tri-color chrysanthemum mix
        // 2 = Rainbow / multi-color bouquet
        // 3 = Classic single-color with golden/white-tipped outer crown
        let burstStyle = Int.random(in: 0 ... 3)
        
        for i in 0 ..< count {
            let angle = CGFloat.random(in: 0 ... 2 * .pi)
            let isOuterRing = (i % 3 != 0)
            
            // Larger speed range (3.8 ... 12.8) + higher retention (0.968) creates ~75% wider explosion canopy
            let rawSpeed: CGFloat = isOuterRing
                ? CGFloat.random(in: 7.2 ... 12.8)
                : CGFloat.random(in: 3.2 ... 7.5)
            let speed = rawSpeed * screenScale
            
            let chosenColorIdx: Int
            switch burstStyle {
            case 0:
                chosenColorIdx = isOuterRing ? primaryColorIdx : secondaryColorIdx
            case 1:
                let mod = i % 3
                chosenColorIdx = (mod == 0) ? primaryColorIdx : ((mod == 1) ? secondaryColorIdx : tertiaryColorIdx)
            case 2:
                chosenColorIdx = Int.random(in: 0 ..< paletteCount)
            default:
                chosenColorIdx = (i % 6 == 0) ? sparkImageIndex : primaryColorIdx
            }
            
            let sizeVariation = CGFloat.random(in: 0.90 ... 1.40)
            let decay = CGFloat.random(in: 0.009 ... 0.018)
            
            let p = Particle(
                x: rocket.x,
                y: rocket.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                alpha: 1.0,
                imageIndex: chosenColorIdx,
                size: visualBaseSize * sizeVariation,
                decay: decay,
                friction: 0.968
            )
            particles.append(p)
        }
        
        // White-hot center flash (larger & brighter core burst)
        for _ in 0 ..< 6 {
            let flashSpeed = CGFloat.random(in: 0.8 ... 3.2) * screenScale
            let angle = CGFloat.random(in: 0 ... 2 * .pi)
            particles.append(Particle(
                x: rocket.x,
                y: rocket.y,
                vx: cos(angle) * flashSpeed,
                vy: sin(angle) * flashSpeed,
                alpha: 1.0,
                imageIndex: whiteImageIndex,
                size: visualBaseSize * 1.5,
                decay: 0.05,
                friction: 0.91
            ))
        }
    }
    
    // MARK: - Cached Fliqlo Clock Layer Management
    
    private func computeClockMetrics() -> (hourRect: CGRect, minuteRect: CGRect) {
        let scaleMultiplier: CGFloat
        switch clockScale {
        case 1: scaleMultiplier = 0.75
        case 3: scaleMultiplier = 1.25
        default: scaleMultiplier = 1.0
        }
        
        let baseW = min(bounds.width * 0.175, 270.0) * scaleMultiplier
        let baseH = baseW * 1.15
        let cardW = round(max(60.0, baseW))
        let cardH = round(max(70.0, baseH))
        let gap = round(max(8.0, cardW * 0.08))
        let totalW = cardW * 2.0 + gap
        
        let startX = round((bounds.width - totalW) * 0.5)
        let startY = round((bounds.height - cardH) * 0.5)
        
        let hourRect = CGRect(x: startX, y: startY, width: cardW, height: cardH)
        let minuteRect = CGRect(x: startX + cardW + gap, y: startY, width: cardW, height: cardH)
        return (hourRect, minuteRect)
    }
    
    private func updateClockLayerFrames() {
        let metrics = computeClockMetrics()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        hourCardLayer.frame = metrics.hourRect
        minuteCardLayer.frame = metrics.minuteRect
        fireworksContainerLayer.frame = bounds
        CATransaction.commit()
    }
    
    private func updateClockTime(now: CFTimeInterval, force: Bool) {
        let date = Date()
        let cal = Calendar.current
        let rawHour = cal.component(.hour, from: date)
        let rawMinute = cal.component(.minute, from: date)
        
        let newHourStr: String
        if clockFormat24 {
            newHourStr = String(format: "%02d", rawHour)
            currentAmPmStr = nil
        } else {
            let h12 = (rawHour % 12 == 0) ? 12 : (rawHour % 12)
            newHourStr = String(format: "%02d", h12)
            currentAmPmStr = rawHour >= 12 ? "PM" : "AM"
        }
        let newMinuteStr = String(format: "%02d", rawMinute)
        
        if currentMinuteStr.isEmpty || force {
            currentMinuteStr = newMinuteStr
            previousMinuteStr = newMinuteStr
            clockNeedsRedraw = true
        } else if newMinuteStr != currentMinuteStr {
            previousMinuteStr = currentMinuteStr
            currentMinuteStr = newMinuteStr
            minuteFlipStartTime = now
            isMinuteFlipping = true
            clockNeedsRedraw = true
        }
        
        if currentHourStr.isEmpty || force {
            currentHourStr = newHourStr
            previousHourStr = newHourStr
            clockNeedsRedraw = true
        } else if newHourStr != currentHourStr {
            previousHourStr = currentHourStr
            currentHourStr = newHourStr
            hourFlipStartTime = now
            isHourFlipping = true
            clockNeedsRedraw = true
        }
        
        if isMinuteFlipping && (now - minuteFlipStartTime) >= 0.45 {
            isMinuteFlipping = false
            clockNeedsRedraw = true
        }
        if isHourFlipping && (now - hourFlipStartTime) >= 0.45 {
            isHourFlipping = false
            clockNeedsRedraw = true
        }
    }
    
    private func renderClockLayersIfNeeded(now: CFTimeInterval, force: Bool) {
        guard showClock else { return }
        let metrics = computeClockMetrics()
        let cardSize = metrics.hourRect.size
        guard cardSize.width > 10 && cardSize.height > 10 else { return }
        
        let backingScale = window?.backingScaleFactor ?? 2.0
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if force || clockNeedsRedraw || isHourFlipping {
            let hourProgress: CGFloat? = isHourFlipping ? min(1.0, CGFloat((now - hourFlipStartTime) / 0.45)) : nil
            if let img = createCardImage(size: cardSize, scale: backingScale, oldText: previousHourStr, newText: currentHourStr, progress: hourProgress, amPm: currentAmPmStr) {
                hourCardLayer.contents = img
            }
        }
        
        if force || clockNeedsRedraw || isMinuteFlipping {
            let minuteProgress: CGFloat? = isMinuteFlipping ? min(1.0, CGFloat((now - minuteFlipStartTime) / 0.45)) : nil
            if let img = createCardImage(size: cardSize, scale: backingScale, oldText: previousMinuteStr, newText: currentMinuteStr, progress: minuteProgress, amPm: nil) {
                minuteCardLayer.contents = img
            }
        }
        
        CATransaction.commit()
        clockNeedsRedraw = false
    }
    
    private func createCardImage(size: CGSize, scale: CGFloat, oldText: String, newText: String, progress: CGFloat?, amPm: String?) -> CGImage? {
        let pixelW = max(1, Int(ceil(size.width * scale)))
        let pixelH = max(1, Int(ceil(size.height * scale)))
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: pixelW,
            height: pixelH,
            bitsPerComponent: 8,
            bytesPerRow: pixelW * 4,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        
        ctx.scaleBy(x: scale, y: scale)
        
        let prevContext = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        defer { NSGraphicsContext.current = prevContext }
        
        let cardBounds = CGRect(origin: .zero, size: size)
        if let p = progress, p < 1.0 {
            renderFlippingCard(ctx: ctx, bounds: cardBounds, oldText: oldText, newText: newText, progress: p, amPm: amPm)
        } else {
            renderCard(ctx: ctx, bounds: cardBounds, text: newText, amPm: amPm)
        }
        
        return ctx.makeImage()
    }
    
    private func renderCard(ctx: CGContext, bounds: CGRect, text: String, amPm: String?) {
        let radius = bounds.width * 0.075
        let path = CGPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerWidth: radius, cornerHeight: radius, transform: nil)
        let midY = bounds.midY
        
        // 1. Dark charcoal plate background
        ctx.addPath(path)
        ctx.setFillColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 0.94)
        ctx.fillPath()
        
        // 2. Subtle outer border
        ctx.addPath(path)
        ctx.setStrokeColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 0.85)
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        
        // 3. Draw Numerals
        let font = NSFont.systemFont(ofSize: bounds.height * 0.65, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(white: 0.90, alpha: 1.0)
        ]
        let str = text as NSString
        let textSize = str.size(withAttributes: attrs)
        let textRect = CGRect(
            x: bounds.midX - textSize.width * 0.5,
            y: midY - textSize.height * 0.5,
            width: textSize.width,
            height: textSize.height
        )
        
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        str.draw(in: textRect, withAttributes: attrs)
        
        // Draw AM / PM if present
        if let amPm = amPm {
            let amPmFont = NSFont.systemFont(ofSize: bounds.height * 0.08, weight: .bold)
            let amPmAttrs: [NSAttributedString.Key: Any] = [
                .font: amPmFont,
                .foregroundColor: NSColor(white: 0.65, alpha: 1.0)
            ]
            let amPmStr = amPm as NSString
            let amPmRect = CGRect(x: bounds.minX + bounds.width * 0.08, y: bounds.minY + bounds.height * 0.08, width: 40, height: 20)
            amPmStr.draw(in: amPmRect, withAttributes: amPmAttrs)
        }
        ctx.restoreGState()
        
        // 4. Middle slit / flip card separation
        drawCardHingesAndSeparation(ctx: ctx, bounds: bounds, midY: midY)
    }
    
    private func renderFlippingCard(ctx: CGContext, bounds: CGRect, oldText: String, newText: String, progress: CGFloat, amPm: String?) {
        let radius = bounds.width * 0.075
        let path = CGPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerWidth: radius, cornerHeight: radius, transform: nil)
        let midY = bounds.midY
        let halfH = bounds.height * 0.5
        
        let font = NSFont.systemFont(ofSize: bounds.height * 0.65, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(white: 0.90, alpha: 1.0)
        ]
        let oldStr = oldText as NSString
        let newStr = newText as NSString
        let oldSize = oldStr.size(withAttributes: attrs)
        let newSize = newStr.size(withAttributes: attrs)
        
        let oldTextRect = CGRect(x: bounds.midX - oldSize.width * 0.5, y: midY - oldSize.height * 0.5, width: oldSize.width, height: oldSize.height)
        let newTextRect = CGRect(x: bounds.midX - newSize.width * 0.5, y: midY - newSize.height * 0.5, width: newSize.width, height: newSize.height)
        
        // 1. Background
        ctx.addPath(path)
        ctx.setFillColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 0.94)
        ctx.fillPath()
        
        // 2. Static top half (shows new incoming number)
        let topHalfRect = CGRect(x: bounds.minX, y: midY, width: bounds.width, height: halfH)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.clip(to: topHalfRect)
        newStr.draw(in: newTextRect, withAttributes: attrs)
        ctx.restoreGState()
        
        // 3. Static bottom half (shows old number)
        let bottomHalfRect = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: halfH)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.clip(to: bottomHalfRect)
        oldStr.draw(in: oldTextRect, withAttributes: attrs)
        ctx.restoreGState()
        
        // 4. Moving flap
        let p = max(0.0, min(1.0, progress))
        if p < 0.5 {
            let scale = max(0.001, cos(p * .pi))
            let flapH = halfH * scale
            let flapRect = CGRect(x: bounds.minX, y: midY, width: bounds.width, height: flapH)
            
            ctx.saveGState()
            ctx.addPath(path)
            ctx.clip()
            ctx.clip(to: flapRect)
            
            ctx.setFillColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            ctx.fill(flapRect)
            
            ctx.translateBy(x: 0, y: midY)
            ctx.scaleBy(x: 1.0, y: scale)
            ctx.translateBy(x: 0, y: -midY)
            oldStr.draw(in: oldTextRect, withAttributes: attrs)
            
            ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: (p / 0.5) * 0.65)
            ctx.fill(flapRect)
            ctx.restoreGState()
        } else {
            let scale = max(0.001, -cos(p * .pi))
            let flapH = halfH * scale
            let flapRect = CGRect(x: bounds.minX, y: midY - flapH, width: bounds.width, height: flapH)
            
            ctx.saveGState()
            ctx.addPath(path)
            ctx.clip()
            ctx.clip(to: flapRect)
            
            ctx.setFillColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            ctx.fill(flapRect)
            
            ctx.translateBy(x: 0, y: midY)
            ctx.scaleBy(x: 1.0, y: scale)
            ctx.translateBy(x: 0, y: -midY)
            newStr.draw(in: newTextRect, withAttributes: attrs)
            
            ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: ((1.0 - p) / 0.5) * 0.65)
            ctx.fill(flapRect)
            ctx.restoreGState()
        }
        
        // 5. Border
        ctx.addPath(path)
        ctx.setStrokeColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 0.85)
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        
        // 6. Draw Hinges & Separation
        drawCardHingesAndSeparation(ctx: ctx, bounds: bounds, midY: midY)
    }
    
    private func drawCardHingesAndSeparation(ctx: CGContext, bounds: CGRect, midY: CGFloat) {
        // Middle slit
        ctx.setFillColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        ctx.fill(CGRect(x: bounds.minX, y: midY - 1.0, width: bounds.width, height: 2.0))
        
        // Specular highlight on top half bottom edge
        ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.10)
        ctx.fill(CGRect(x: bounds.minX, y: midY + 1.0, width: bounds.width, height: 0.8))
        
        // Shadow on bottom half top edge
        ctx.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.40)
        ctx.fill(CGRect(x: bounds.minX, y: midY - 2.0, width: bounds.width, height: 1.0))
        
        // Side axle notches
        let notchW: CGFloat = max(3.0, bounds.width * 0.015)
        let notchH: CGFloat = max(6.0, bounds.height * 0.03)
        ctx.setFillColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)
        ctx.fill(CGRect(x: bounds.minX, y: midY - notchH * 0.5, width: notchW, height: notchH))
        ctx.fill(CGRect(x: bounds.maxX - notchW, y: midY - notchH * 0.5, width: notchW, height: notchH))
    }
}
