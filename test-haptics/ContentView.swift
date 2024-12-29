//
//  ContentView.swift
//  test-haptics
//
//  Created by Ryan Du on 6/19/24.
//

import SwiftUI
import CoreHaptics



struct ContentView: View {
    @State var engine: CHHapticEngine?
    @State var continuousPlayer: CHHapticAdvancedPatternPlayer?
    @State var value = 0.1
    
    private let initialIntensity: Float = 1.0
    private let initialSharpness: Float = 0.1
    @State private var engineNeedsStart = true

    func createAndStartHapticEngine() {
        
        // Create and configure a haptic engine.
        do {
            engine = try CHHapticEngine()
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }
        
        
        // Mute audio to reduce latency for collision haptics.
        engine?.playsHapticsOnly = true
        
        // The stopped handler alerts you of engine stoppage.
        engine?.stoppedHandler = { reason in
            print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
                case .audioSessionInterrupt:
                    print("Audio session interrupt")
                case .applicationSuspended:
                    print("Application suspended")
                case .idleTimeout:
                    print("Idle timeout")
                case .systemError:
                    print("System error")
                case .notifyWhenFinished:
                    print("Playback finished")
                case .gameControllerDisconnect:
                    print("Controller disconnected.")
                case .engineDestroyed:
                    print("Engine destroyed.")
                @unknown default:
                    print("Unknown error")
            }
        }
        
        
        // The reset handler provides an opportunity to restart the engine.
        engine?.resetHandler = {
            
            print("Reset Handler: Restarting the engine.")
            
            do {
                // Try restarting the engine.
                try self.engine?.start()
                
                // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                self.engineNeedsStart = false
                // Recreate the continuous player.
                self.createContinuousHapticPlayer()
                
            } catch {
                print("Failed to start the engine")
            }
        }
        
        // Start the haptic engine for the first time.
        do {
            try self.engine?.start()
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
            
        } catch {
            print("Failed to start the engine: \(error)")
        }
        
        
    }
    
    /// - Tag: CreateContinuousPattern
    func createContinuousHapticPlayer() {
        // Create an intensity parameter:
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                               value: initialIntensity)
        
        // Create a sharpness parameter:
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                               value: initialSharpness)
        
        // Create a continuous event with a long duration from the parameters.
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous,
                                            parameters: [intensity, sharpness],
                                            relativeTime: 0,
                                            duration: 100)
        
        do {
            // Create a pattern from the continuous haptic event.
            let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
            
            // Create a player from the continuous haptic pattern.
            continuousPlayer = try engine?.makeAdvancedPlayer(with: pattern)
            print("made continuous Player: \(continuousPlayer)")
            
        } catch let error {
            print("Pattern Player Creation Error: \(error)")
        }
        
        continuousPlayer?.completionHandler = { _ in
            DispatchQueue.main.async {
                print("continuous event completed")
                // Restore original color.
//                self.continuousPalette.backgroundColor = self.padColor
            }
        }
    }
    
    func updateHapticIntensity(value: Double) {
        // Create dynamic parameters for the updated intensity & sharpness.
        let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                          value: Float(value),
                                                          relativeTime: 0)
        
        let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                          value: 0.2,
                                                          relativeTime: 0)
        
        
        // Send dynamic parameters to the haptic player.
        do {
            guard let uContinuousPlayer = continuousPlayer else {
                print("No continuous player when updating values")
                return
            }
            try uContinuousPlayer.sendParameters([intensityParameter, sharpnessParameter],
                                                atTime: 0)
        } catch let error {
            print("Dynamic Parameter Error: \(error)")
        }
        
        
    }
    
    private func sliderChanged(to newValue: Double) {
        updateHapticIntensity(value: newValue)
        print("updating value")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Button(action: {
                createContinuousHapticPlayer()
            }) {
                Text("Start Continuous Haptic")
            }
            
            Slider(value: $value, in: 0...1, onEditingChanged: ({ started in
                if started {
                    do {
                        // Begin playing continuous pattern.
                        try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
                    } catch let error {
                        print("Error starting the continuous haptic player: \(error)")
                    }
                } else {
                    do {
                        try continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
                    } catch let error {
                        print("Error stopping the continuous haptic player: \(error)")
                    }
                }
                
            })).onChange(of: value, perform: sliderChanged)

            Button(action: {
                do {
                    
                    let hapticDict = [
                        CHHapticPattern.Key.pattern: [
                            [CHHapticPattern.Key.event: [
                                CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                                CHHapticPattern.Key.time: CHHapticTimeImmediate,
                                CHHapticPattern.Key.eventDuration: 1.0]
                            ]
                        ]
                    ]
                    let pattern = try CHHapticPattern(dictionary: hapticDict)
                    let player = try engine?.makePlayer(with: pattern)
                    
                    engine?.notifyWhenPlayersFinished { error in
                        return .stopEngine
                    }
                    
                    
                    try engine?.start()
                    try player?.start(atTime: 0)
                } catch {
                    print(error)
                }

            }, label: {
                Text("Tactile Haptic")
                    .padding()
            })
        }
        .padding()
        .onAppear {
            do {
                engine = try CHHapticEngine()
                try self.engine?.start()
            } catch let error {
                fatalError("Engine Creation Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
