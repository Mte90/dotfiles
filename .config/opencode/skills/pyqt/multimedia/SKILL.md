---
name: pyqt-multimedia
description: "PyQt/PySide multimedia - audio playback, video playback, camera, audio recording, media player"
metadata:
  author: OSS AI Skills
  version: 1.0.0
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

Audio and video playback, camera capture, and media processing in PyQt/PySide.

## Overview

Qt Multimedia provides classes for audio, video, and camera functionality:
- **QMediaPlayer** - Audio/video playback
- **QVideoWidget** - Video display
- **QAudioOutput** - Audio output management
- **QCamera** - Camera capture
- **QMediaRecorder** - Audio/video recording

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
        self.setWindowTitle("Audio Player")
        
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        
        # UI
        self.play_btn = QPushButton("Play")
        self.pause_btn = QPushButton("Pause")
        self.stop_btn = QPushButton("Stop")
        self.label = QLabel("No file loaded")
        self.volume_slider = QSlider(Qt.Orientation.Horizontal)
        self.volume_slider.setRange(0, 100)
        self.volume_slider.setValue(50)
        
        layout = QVBoxLayout()
        layout.addWidget(self.label)
        layout.addWidget(self.play_btn)
        layout.addWidget(self.pause_btn)
        layout.addWidget(self.stop_btn)
        layout.addWidget(self.volume_slider)
        self.setLayout(layout)
        
        # Connections
        self.play_btn.clicked.connect(self.player.play)
        self.pause_btn.clicked.connect(self.player.pause)
        self.stop_btn.clicked.connect(self.player.stop)
        self.volume_slider.valueChanged.connect(
            lambda v: self.audio_output.setVolume(v / 100)
        )
        
        self.player.positionChanged.connect(self.update_position)
        
    def load_file(self, filepath):
        self.player.setSource(QUrl.fromLocalFile(filepath))
        self.label.setText(filepath.split('/')[-1])
        
    def update_position(self, position):
        # position in milliseconds
        seconds = position // 1000
        minutes = seconds // 60
        seconds = seconds % 60
        print(f"{minutes:02d}:{seconds:02d}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AudioPlayer()
    window.show()
    sys.exit(app.exec())
```

### Audio Playlist

```python
from PyQt6.QtMultimedia import QMediaPlayer, QAudioOutput
from PyQt6.QtCore import QUrl, QModelIndex
from PyQt6.QtWidgets import QListView

class PlaylistPlayer:
    def __init__(self, playlist_view: QListView):
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        
        self.playlist = []  # List of file paths
        self.current_index = -1
        
    def add_to_playlist(self, filepath):
        self.playlist.append(filepath)
        
    def play_index(self, index: int):
        if 0 <= index < len(self.playlist):
            self.current_index = index
            self.player.setSource(QUrl.fromLocalFile(self.playlist[index]))
            self.player.play()
            
    def next(self):
        if self.playlist:
            self.current_index = (self.current_index + 1) % len(self.playlist)
            self.play_index(self.current_index)
            
    def previous(self):
        if self.playlist:
            self.current_index = (self.current_index - 1) % len(self.playlist)
            self.play_index(self.current_index)
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
from PyQt6.QtCore import Qt, QUrl, QTimer
from PyQt6.QtGui import QAction
import sys

class VideoPlayer(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Video Player")
        self.resize(800, 600)
        
        # Media player
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        
        # Video widget
        self.video_widget = QVideoWidget()
        
        # Controls
        self.play_btn = QPushButton("Play")
        self.pause_btn = QPushButton("Pause")
        self.stop_btn = QPushButton("Stop")
        
        self.position_slider = QSlider(Qt.Orientation.Horizontal)
        self.position_slider.setRange(0, 0)
        
        self.time_label = QLabel("00:00 / 00:00")
        self.volume_slider = QSlider(Qt.Orientation.Horizontal)
        self.volume_slider.setRange(0, 100)
        self.volume_slider.setValue(50)
        
        # Layout
        control_layout = QHBoxLayout()
        control_layout.addWidget(self.play_btn)
        control_layout.addWidget(self.pause_btn)
        control_layout.addWidget(self.stop_btn)
        control_layout.addWidget(self.position_slider)
        control_layout.addWidget(self.time_label)
        control_layout.addWidget(self.volume_slider)
        
        main_layout = QVBoxLayout()
        main_layout.addWidget(self.video_widget)
        main_layout.addLayout(control_layout)
        self.setLayout(main_layout)
        
        # Connect
        self.player.setVideoOutput(self.video_widget)
        
        self.play_btn.clicked.connect(self.player.play)
        self.pause_btn.clicked.connect(self.player.pause)
        self.stop_btn.clicked.connect(self.stop)
        
        self.player.positionChanged.connect(self.position_changed)
        self.player.durationChanged.connect(self.duration_changed)
        
        self.volume_slider.valueChanged.connect(
            lambda v: self.audio_output.setVolume(v / 100)
        )
        
    def load_video(self, filepath):
        self.player.setSource(QUrl.fromLocalFile(filepath))
        
    def stop(self):
        self.player.stop()
        self.position_slider.setValue(0)
        
    def position_changed(self, position):
        self.position_slider.setValue(position)
        self.update_time_label()
        
    def duration_changed(self, duration):
        self.position_slider.setRange(0, duration)
        self.update_time_label()
        
    def update_time_label(self):
        pos = self.player.position() // 1000
        dur = self.player.duration() // 1000
        
        pos_m, pos_s = divmod(pos, 60)
        dur_m, dur_s = divmod(dur, 60)
        
        self.time_label.setText(
            f"{pos_m:02d}:{pos_s:02d} / {dur_m:02d}:{dur_s:02d}"
        )
        
    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_Space:
            if self.player.playbackState() == QMediaPlayer.PlaybackState.PlayingState:
                self.player.pause()
            else:
                self.player.play()
        elif event.key() == Qt.Key.Key_Left:
            self.player.setPosition(max(0, self.player.position() - 5000))
        elif event.key() == Qt.Key.Key_Right:
            self.player.setPosition(
                min(self.player.duration(), self.player.position() + 5000)
            )
```

### Fullscreen Video

```python
class FullscreenVideoPlayer(VideoPlayer):
    def __init__(self):
        super().__init__()
        self.is_fullscreen = False
        self.video_widget.doubleClicked.connect(self.toggle_fullscreen)
        
    def toggle_fullscreen(self):
        if self.is_fullscreen:
            self.showNormal()
        else:
            self.showFullScreen()
        self.is_fullscreen = not self.is_fullscreen
```

---

## Camera Capture

### Display Camera Feed

```python
from PyQt6.QtMultimedia import QCamera, QMediaDevices
from PyQt6.QtMultimediaWidgets import QVideoWidget
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton
from PyQt6.QtCore import Qt
import sys

class CameraViewer(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Camera Viewer")
        
        # Get available cameras
        self.cameras = QMediaDevices.videoInputs()
        if not self.cameras:
            print("No cameras available")
            return
            
        # Create camera
        self.camera = QCamera(self.cameras[0])
        
        # Video widget
        self.video_widget = QVideoWidget()
        
        # Buttons
        self.start_btn = QPushButton("Start")
        self.stop_btn = QPushButton("Stop")
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        layout.addWidget(self.start_btn)
        layout.addWidget(self.stop_btn)
        self.setLayout(layout)
        
        # Connect camera to widget
        self.camera.setVideoOutput(self.video_widget)
        
        self.start_btn.clicked.connect(self.camera.start)
        self.stop_btn.clicked.connect(self.camera.stop)
        
    def closeEvent(self, event):
        self.camera.stop()
        super().closeEvent(event)
```

### Capture Photo

```python
from PyQt6.QtMultimedia import QCamera, QMediaCaptureSession, QImageCapture
from PyQt6.QtMultimediaWidgets import QVideoWidget
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel
from PyQt6.QtCore import QUrl

class CameraCapture(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Camera Capture")
        
        self.camera = QCamera()
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        
        self.video_widget = QVideoWidget()
        self.capture_session.setVideoOutput(self.video_widget)
        
        # Image capture
        self.image_capture = QImageCapture()
        self.capture_session.setImageCapture(self.image_capture)
        
        self.capture_btn = QPushButton("Capture Photo")
        self.preview_label = QLabel()
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        layout.addWidget(self.capture_btn)
        layout.addWidget(self.preview_label)
        self.setLayout(layout)
        
        self.capture_btn.clicked.connect(self.capture_photo)
        
        self.camera.start()
        
    def capture_photo(self):
        self.image_capture.captureToFile()
        
    def handle_captured(self, id, filePath):
        print(f"Photo saved to: {filePath}")
```

### Record Video

```python
from PyQt6.QtMultimedia import QCamera, QMediaCaptureSession, QMediaRecorder
from PyQt6.QtMultimediaWidgets import QVideoWidget
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel

class VideoRecorder(QWidget):
    def __init__(self):
        super().__init__()
        
        self.camera = QCamera()
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        
        self.video_widget = QVideoWidget()
        self.capture_session.setVideoOutput(self.video_widget)
        
        # Recorder
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

## Audio Recording

### Microphone Input

```python
from PyQt6.QtMultimedia import QMediaRecorder, QMediaCaptureSession, QAudioInput
from PyQt6.QtCore import QUrl, QStandardPaths
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel
import os

class AudioRecorder(QWidget):
    def __init__(self):
        super().__init__()
        
        self.recorder = QMediaRecorder()
        self.capture_session = QMediaCaptureSession()
        
        self.audio_input = QAudioInput()
        self.capture_session.setAudioInput(self.audio_input)
        self.capture_session.setRecorder(self.recorder)
        
        self.record_btn = QPushButton("Start Recording")
        self.status_label = QLabel("Ready")
        
        layout = QVBoxLayout()
        layout.addWidget(self.record_btn)
        layout.addWidget(self.status_label)
        self.setLayout(layout)
        
        self.record_btn.clicked.connect(self.toggle_recording)
        self.recorder.recorderStateChanged.connect(self.update_status)
        
        # Default output location
        documents = QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.MoviesLocation
        )
        self.output_path = os.path.join(documents, "recording.mp3")
        
    def toggle_recording(self):
        if self.recorder.recorderState() == QMediaRecorder.RecorderState.RecordingState:
            self.recorder.stop()
        else:
            self.recorder.setOutputLocation(QUrl.fromLocalFile(self.output_path))
            self.recorder.record()
            
    def update_status(self, state):
        if state == QMediaRecorder.RecorderState.RecordingState:
            self.record_btn.setText("Stop Recording")
            self.status_label.setText("Recording...")
        else:
            self.record_btn.setText("Start Recording")
            self.status_label.setText("Ready")
```

---

## GStreamer Backend

### Install GStreamer (Linux)

```bash
# Ubuntu/Debian
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly

# For audio/video codecs
sudo apt-get install gstreamer1.0-libav
```

### Install on Windows

PySide6 on Windows typically uses DirectShow or WMF backends. Install K-Lite Codec Pack for additional codec support.

---

## Common Issues

### No Audio/Video Output

```python
# Check available codecs
from PyQt6.QtMultimedia import QMediaDevices
print("Audio outputs:", QMediaDevices.audioOutputs())
print("Video outputs:", QMediaDevices.videoOutputs())

# Check camera
print("Cameras:", QMediaDevices.videoInputs())
```

### Format Not Supported

```python
# Convert using QMediaEncoder with specific codec
from PyQt6.QtMultimedia import QMediaRecorder, QMediaFormat

recorder = QMediaRecorder()
recorder.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)
recorder.setAudioCodec(QMediaFormat.AudioCodec.AAC)
recorder.setVideoCodec(QMediaFormat.VideoCodec.H264)
```

---

## Best Practices

### Audio/Video Capture

```python
# ✅ GOOD: Check availability first
from PyQt6.QtMultimedia import QMediaDevices

if not QMediaDevices.audioInputs():
    print("No microphone available")
    return

# ✅ GOOD: Set output location before recording
recorder.setOutputLocation(QUrl.fromLocalFile(path))
recorder.record()  # Start after setting location
```

### Playback

```python
# ✅ GOOD: Check player state
player.play()
# Wait for state change signal, don't assume immediate playback

# ✅ GOOD: Handle missing codecs
# Install K-Lite on Windows, gstreamer on Linux
```

### Resource Management

```python
# ✅ GOOD: Clean up resources
def closeEvent(self, event):
    self.player.stop()
    self.recorder.stop()
    self.camera.stop()
    super().closeEvent(event)
```

### Do:
- Check device availability before use
- Set output location before recording
- Clean up on close

### Don't:
- Record without checking available disk space
- Use unsupported formats
- Forget to stop capture sessions

---

## References

- **Qt Multimedia**: https://doc.qt.io/qt-6/qtmultimedia-index.html
- **PySide6 Multimedia**: https://doc.qt.io/qt-6/multimedia.html
- **GStreamer**: https://gstreamer.freedesktop.org/