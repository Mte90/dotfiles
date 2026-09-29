---
name: pyqt-multimedia
description: "Use when adding multimedia to PyQt/PySide6 apps - audio and video playback with QMediaPlayer, camera capture with QCamera and QMediaCaptureSession, audio/video recording with QMediaRecorder, GStreamer backend setup, or codec and platform compatibility issues"
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - qt
    - pyqt
    - multimedia
    - audio
    - video
    - camera
    - media
---

# PyQt/PySide Multimedia

Audio and video playback, camera capture, and media recording in PyQt6/PySide6.

## Overview

Qt Multimedia provides classes for audio, video, and camera functionality:
- **QMediaPlayer** - Audio/video playback
- **QVideoWidget** - Video display
- **QAudioOutput** - Audio output management
- **QCamera** - Camera capture
- **QMediaCaptureSession** - Camera/recording session management
- **QMediaRecorder** - Audio/video recording
- **QMediaFormat** - Encoding format configuration

**Backend by platform:**
- Linux: GStreamer
- Windows: DirectShow/WMF
- macOS: AVFoundation

---

## Audio Playback

### Basic Audio Player

```python
from PyQt6.QtMultimedia import QMediaPlayer, QAudioOutput
from PyQt6.QtWidgets import QApplication, QPushButton, QVBoxLayout, QWidget, QSlider, QLabel
from PyQt6.QtCore import Qt, QUrl
import sys

class AudioPlayer(QWidget):
    def __init__(self):
        super().__init__()
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        
        self.play_btn = QPushButton("Play")
        self.volume_slider = QSlider(Qt.Orientation.Horizontal)
        self.volume_slider.setRange(0, 100)
        
        layout = QVBoxLayout()
        layout.addWidget(self.play_btn)
        layout.addWidget(self.volume_slider)
        self.setLayout(layout)
        
        self.play_btn.clicked.connect(self.player.play)
        self.volume_slider.valueChanged.connect(
            lambda v: self.audio_output.setVolume(v / 100)
        )
        
    def load_file(self, filepath):
        self.player.setSource(QUrl.fromLocalFile(filepath))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AudioPlayer()
    window.show()
    sys.exit(app.exec())
```

---

## Video Playback

### Video Player with Controls

```python
from PyQt6.QtMultimedia import QMediaPlayer, QAudioOutput
from PyQt6.QtMultimediaWidgets import QVideoWidget
from PyQt6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QSlider, QLabel
)
from PyQt6.QtCore import Qt, QUrl

class VideoPlayer(QWidget):
    def __init__(self):
        super().__init__()
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        
        self.video_widget = QVideoWidget()
        self.player.setVideoOutput(self.video_widget)
        
        self.play_btn = QPushButton("Play")
        self.position_slider = QSlider(Qt.Orientation.Horizontal)
        self.time_label = QLabel("00:00 / 00:00")
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        layout.addWidget(self.play_btn)
        layout.addWidget(self.position_slider)
        layout.addWidget(self.time_label)
        self.setLayout(layout)
        
        self.play_btn.clicked.connect(self.player.play)
        self.player.positionChanged.connect(self.position_changed)
        self.player.durationChanged.connect(self.duration_changed)
        
    def load_video(self, filepath):
        self.player.setSource(QUrl.fromLocalFile(filepath))
        
    def position_changed(self, position):
        self.position_slider.setValue(position)
        
    def duration_changed(self, duration):
        self.position_slider.setRange(0, duration)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = VideoPlayer()
    window.show()
    sys.exit(app.exec())
```

**Key methods:**
- `play()`, `pause()`, `stop()` - Playback control
- `setPosition(ms)`, `seek(seconds)` - Position control
- `playbackState()` - Returns PlayingState, PausedState, or StoppedState

---

## Camera Capture

### Camera Viewer

```python
from PyQt6.QtMultimedia import QCamera, QMediaDevices
from PyQt6.QtMultimediaWidgets import QVideoWidget
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton

class CameraViewer(QWidget):
    def __init__(self):
        super().__init__()
        cameras = QMediaDevices.videoInputs()
        if not cameras:
            print("No cameras available")
            return
            
        self.camera = QCamera(cameras[0])
        self.video_widget = QVideoWidget()
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        self.setLayout(layout)
        
        self.camera.setVideoOutput(self.video_widget)
        self.camera.start()
        
    def closeEvent(self, event):
        self.camera.stop()
        super().closeEvent(event)
```

### Photo Capture with QMediaCaptureSession

```python
from PyQt6.QtMultimedia import QCamera, QMediaCaptureSession, QImageCapture
from PyQt6.QtMultimediaWidgets import QVideoWidget
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton

class CameraCapture(QWidget):
    def __init__(self):
        super().__init__()
        self.camera = QCamera()
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        
        self.video_widget = QVideoWidget()
        self.capture_session.setVideoOutput(self.video_widget)
        
        self.image_capture = QImageCapture()
        self.capture_session.setImageCapture(self.image_capture)
        
        self.capture_btn = QPushButton("Capture Photo")
        self.capture_btn.clicked.connect(self.capture_photo)
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        layout.addWidget(self.capture_btn)
        self.setLayout(layout)
        
        self.camera.start()
        
    def capture_photo(self):
        self.image_capture.captureToFile()
```

---

## Audio/Video Recording

### Media Recorder

```python
from PyQt6.QtMultimedia import QCamera, QMediaCaptureSession, QMediaRecorder
from PyQt6.QtMultimediaWidgets import QVideoWidget
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel
from PyQt6.QtCore import QUrl

class MediaRecorder(QWidget):
    def __init__(self):
        super().__init__()
        self.camera = QCamera()
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        
        self.video_widget = QVideoWidget()
        self.capture_session.setVideoOutput(self.video_widget)
        
        self.recorder = QMediaRecorder()
        self.capture_session.setRecorder(self.recorder)
        
        self.record_btn = QPushButton("Start Recording")
        self.status_label = QLabel("Ready")
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        layout.addWidget(self.record_btn)
        layout.addWidget(self.status_label)
        self.setLayout(layout)
        
        self.record_btn.clicked.connect(self.toggle_recording)
        self.recorder.recorderStateChanged.connect(self.update_status)
        
    def toggle_recording(self):
        if self.recorder.recorderState() == QMediaRecorder.RecorderState.RecordingState:
            self.recorder.stop()
        else:
            self.recorder.setOutputLocation(QUrl.fromLocalFile("output.mp4"))
            self.recorder.record()
            
    def update_status(self, state):
        states = {
            QMediaRecorder.RecorderState.StoppedState: "Stopped",
            QMediaRecorder.RecorderState.RecordingState: "Recording",
            QMediaRecorder.RecorderState.PausedState: "Paused"
        }
        self.status_label.setText(states.get(state, "Unknown"))
```

---

## GStreamer Backend (Linux)

```bash
# Ubuntu/Debian - core plugins
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly

# Additional codec support
sudo apt-get install gstreamer1.0-libav
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| No audio/video output | Check `QMediaDevices.audioOutputs()` and `videoOutputs()` |
| No cameras found | Check `QMediaDevices.videoInputs()` |
| Format not supported | Install codec pack (Windows) or GStreamer plugins (Linux) |
| Playback fails | Check `player.error()` for specific error code |

---

## Best Practices

```python
# ✅ Check device availability first
from PyQt6.QtMultimedia import QMediaDevices
if not QMediaDevices.audioInputs():
    print("No microphone available")

# ✅ Set output location before recording
recorder.setOutputLocation(QUrl.fromLocalFile(path))
recorder.record()

# ✅ Clean up on close
def closeEvent(self, event):
    self.camera.stop()
    self.recorder.stop()
    super().closeEvent(event)
```

---

## Deep Dives

For detailed implementations, see the reference files:

- **Media Pipeline** (`references/media-pipeline.md`) - QMediaPlayer + QVideoWidget, QCamera + QMediaCaptureSession, QMediaRecorder setup
- **Codecs & Platforms** (`references/codecs-platforms.md`) - Platform-specific codec support, installation guides, format compatibility

---

## References

- **Qt Multimedia**: https://doc.qt.io/qt-6/qtmultimedia-index.html
- **PySide6 Multimedia**: https://doc.qt.io/qt-6/multimedia.html
- **GStreamer**: https://gstreamer.freedesktop.org/