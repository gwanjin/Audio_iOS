//
//  ViewController.swift
//  AudioApp
//
//  Created by jeong gwanjin on 2020/06/27.
//  Copyright © 2020 jeong gwanjin. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    @IBOutlet weak var mProgressPlay: UIProgressView!
    @IBOutlet weak var mLbCurrentTime: UILabel!
    @IBOutlet weak var mLbEndTime: UILabel!
    @IBOutlet weak var mBtnPlay: UIButton!
    @IBOutlet weak var mBtnPause: UIButton!
    @IBOutlet weak var mBtnStop: UIButton!
    @IBOutlet weak var mSlVolume: UISlider!
    @IBOutlet weak var mBtnRecord: UIButton!
    @IBOutlet weak var mLbRecordTime: UILabel!
    
    let MAX_VOLUME: Float = 10.0    // Volume最大値
    let timePlayerSelector: Selector = #selector(ViewController.updatePlayTime)
    let timeRecordSelector: Selector = #selector(ViewController.updateRecordTime)
    
    /**
     Audio 再生
     */
    var audioPlayer: AVAudioPlayer! // AVAudioPlayer インスタンス
    var audioFile: URL!             // 再生するAudioのファイル
    var progressTimer: Timer!       // タイマー
    
    /**
     Audio録音
     */
    var audioRecorder : AVAudioRecorder!
    var isRecordMode = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectAudioFile()
        if !isRecordMode {
            initPlay()
            mBtnRecord.isEnabled = false
            mLbRecordTime.isEnabled = false
        } else {
            initRecord()
        }
    }
    
    func selectAudioFile() {
        if !isRecordMode {
            audioFile = Bundle.main.url(forResource: "Sicilian_Breeze", withExtension: "mp3")
        } else {
            // 録音モードの場合、ドキュメントディレクトリのファイルを使う
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) [0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        }
    }
    
    /**
     Audio 再生初期化
     */
    func initPlay() {
        // audioFileをURLとするaudioPlayerインスタンスを生成
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile); // errorが発生する可能性があるコード
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        
        mSlVolume.maximumValue = MAX_VOLUME
        mSlVolume.value = 1.0
        mProgressPlay.progress = 0
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer.volume = mSlVolume.value
        
        mLbEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        mLbCurrentTime.text = convertNSTimeInterval2String(0)
        
        setButtons(true, pause: false, stop: false)
    }
    
    /**
     Audio録音初期化
     */
    func initRecord() {
        // 録音の設定
        /**
         format：AppleLossless
         音質：最大
         bit率：320,000bps
         audioチャンネル：2
         サンプル率：44,100Hz
         */
        let recordSettings = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless as  UInt32),
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 441000.0] as [String: Any]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        mSlVolume.value = 1.0
        audioPlayer.volume = mSlVolume.value
        mLbCurrentTime.text = convertNSTimeInterval2String(0)
        mLbEndTime.text = convertNSTimeInterval2String(0)
        setButtons(false, pause: false, stop: false)
        
        let session = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
    }
    
    /**
     ボタンコントロール
     */
    func setButtons(_ play:Bool, pause:Bool, stop:Bool) {
        mBtnPlay.isEnabled = play
        mBtnPause.isEnabled = pause
        mBtnStop.isEnabled = stop
    }
    
    func convertNSTimeInterval2String(_ time:TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }
    
    /**
     表示時間更新
     */
    @objc func updatePlayTime() {
        mLbCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        mProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    @objc func updateRecordTime() {
        mLbRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
    
    @IBAction func btnPlayAudio(_ sender: UIButton) {
        audioPlayer.play()
        setButtons(false, pause: true, stop: true)
        // 0.1秒間隔でタイマーを生成
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    @IBAction func btnPauseAudio(_ sender: UIButton) {
        audioPlayer.pause()
        setButtons(true, pause: false, stop: true)
    }
    
    @IBAction func btnStopAudio(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        mLbCurrentTime.text = convertNSTimeInterval2String(0)
        setButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // タイマー無効にする
    }
    
    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = mSlVolume.value
    }
    
    @IBAction func btnRecord(_ sender: UIButton) {
        if (sender as AnyObject).titleLabel??.text == "Record" {
            audioRecorder.record()
            mBtnRecord.isSelected = true
            (sender as AnyObject).setTitle("Stop", for: .selected)
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        } else {
            audioRecorder.stop()
            mBtnRecord.isSelected = false
            (sender as AnyObject).setTitle("Record", for: .normal)
            progressTimer.invalidate()
            // 録音ファイル再生ボタン有効化
            mBtnPlay.isEnabled = true
            initPlay()
        }
    }
    
    @IBAction func swRecordMode(_ sender: UISwitch) {
        if (sender.isOn) {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            mLbCurrentTime.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            mBtnRecord.isEnabled = true
            mLbRecordTime.isEnabled = true
        } else {
            isRecordMode = false;
            mBtnRecord.isEnabled = false;
            mLbRecordTime.isEnabled = false;
            mLbRecordTime.text = convertNSTimeInterval2String(0)
        }
        selectAudioFile()
        if !isRecordMode {
            initPlay()
        } else {
            initRecord()
        }
    }
    
    /**
     Audioが終わった時のDelegate
     */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setButtons(true, pause: false, stop: false)
    }
}

