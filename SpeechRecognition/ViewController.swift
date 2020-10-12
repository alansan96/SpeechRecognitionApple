//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Alan Santoso on 03/09/20.
//  Copyright © 2020 Alan Santoso. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {
    
    // MARK: - PROPERTIES
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var recordingBtn: UIButton!
    
    
    var isRecording = false
    
    var audioSession : AVAudioSession? = AVAudioSession.sharedInstance()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    let audioEngine = AVAudioEngine()
    var inputNode: AVAudioInputNode?
    
    var second:Int = 0
    var minute:Int = 0
    var hour:Int = 0
    
    var timer: Timer?
    var recordingTimer:Timer?
    
    
    var completeSpeechString = [String]()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textView.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkPermissions()
    }
    
    @IBAction func recordingButtonTapped(_ sender: UIButton) {
        
        if isRecording {
            stopRecording()
            timer?.invalidate()

        } else {
            stopRecording()
            startRecording()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                self.updateTimer()
                if self.second == 58 {
                    print("sec10")
                    self.stopRecording()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.startRecording()
                    }
                }
            })
        }
        isRecording.toggle()
        sender.setTitle((isRecording ? "Stop" : "Start") + " recording", for: .normal)
        print("WHATTEFAK")
    }
    
    func updateTimer() -> String{
        second += 1
        if second == 60 {
            minute += 1
            second = 0
        }
        if minute == 60{
            hour += 1
            minute = 0
        }
        
        var secondString = "\(second)"
        var minuteString = "0\(minute)"
        var hourString = "0\(hour)"
        
       
        if secondString.count < 2 {
            secondString.insert("0", at: secondString.startIndex)
        }
        if minuteString.count < 2 {
            minuteString.insert("0", at: minuteString.startIndex)
        }
        if hourString.count < 2 {
            hourString.insert("0", at: hourString.startIndex)
        }
        
        
        print(hourString,minuteString,secondString)

        
        return "\(hourString) : \(minuteString) : \(secondString)"
    }
    
    func resetTimer() {
        second = 0
        minute = 0
        hour = 0
    }
    
    
    // MARK: - PERMISSION HANDLING
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    // TODO: Implement.
                    break
                case .denied:
                    // TODO: Implement.
                    break
                case .restricted:
                    // TODO: Implement.
                    break
                case .notDetermined:
                    // TODO: Implement.
                    break
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    private func handlePermissionFailed() {
        // Present an alert asking the user to change their settings.
        let ac = UIAlertController(title: "This app must have access to speech recognition to work.",
                                   message: "Please consider updating your settings.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Open settings", style: .default) { _ in
            let url = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(url)
        })
        ac.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(ac, animated: true)
        
        
        // Disable the record button.
        recordingBtn.isEnabled = false
        recordingBtn.setTitle("Speech recognition not available.", for: .normal)
    }
}

extension ViewController : SFSpeechRecognitionTaskDelegate{
    
    func startRecording(){
        
        do {
            try audioSession?.setCategory(.record, mode: .spokenAudio, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch let error {
            print(error)
        }
        
        let indoLocale = Locale(identifier: "id_ID")
        guard let recognizer = SFSpeechRecognizer(locale: indoLocale), recognizer.isAvailable else {
            return
        }
        
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        recognizer.recognitionTask(with: recognitionRequest!) { (result, error) in
            guard let result = result else { return }
//            print("got a new result: \(result.bestTranscription.formattedString), final : \(result.isFinal)")
            if result.isFinal{
                self.completeSpeechString.append(result.bestTranscription.formattedString)
                self.completeSpeechString.append("\n\n")
            }else {
                self.textView.text =  self.completeSpeechString.joined(separator: "") + result.bestTranscription.formattedString
            }
            
        }
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            
        } catch let error {
            print(error)
        }

    }
    
    func stopRecording(){
        // End the recognition request.
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Stop recording.
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0) // Call after audio engine is stopped as it modifies the graph.
        
        // Stop our session.
        try? audioSession?.setActive(false)
        audioSession = nil
    }
    
    
}


