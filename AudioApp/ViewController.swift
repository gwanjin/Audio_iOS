//
//  ViewController.swift
//  AudioApp
//
//  Created by jeong gwanjin on 2020/06/27.
//  Copyright © 2020 jeong gwanjin. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {
    @IBOutlet weak var mProgressPlay: UIProgressView!
    @IBOutlet weak var mLbCurrentTime: UILabel!
    @IBOutlet weak var mLbEndTime: UILabel!
    @IBOutlet weak var mBtnPlay: UIButton!
    @IBOutlet weak var mBtnPause: UIButton!
    @IBOutlet weak var mBtnStop: UIButton!
    @IBOutlet weak var mSlVolume: UISlider!
    
    let MAX_VOLUME: Float = 10.0    // Volume最大値
    let timePlayerSelector: Selector = #selector(ViewController.updatePlayTime)
    
    var audioPlayer: AVAudioPlayer! // AVAudioPlayer インスタンス
    var audioFile: URL!             // 再生するAudioのファイル
    var progressTimer: Timer!       // タイマー
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioFile = Bundle.main.url(forResource: "Sicilian_Breeze", withExtension: "mp3")
        initPlay()
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
    
    /**
     Audioが終わった時のDelegate
     */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setButtons(true, pause: false, stop: false)
    }
}

