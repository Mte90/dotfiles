---
name: pyqt-multimedia
description: "PyQt/PySide multimedia - audio playback, video playback, camera, audio recording, media player"
metadata:
  author: mte90
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

## Video Playback (PySide6)

### QMediaPlayer + QVideoWidget

```python
from PySide6.QtMultimedia import QMediaPlayer
from PySide6.QtMultimediaWidgets import QVideoWidget
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QSlider, QLabel, QMainWindow
)
from PySide6.QtCore import Qt, QUrl, QTimer
from PySide6.QtGui import QAction
import sys

class VideoPlayer(QMainWindow):
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
        self.play_btn = QPushButton("▶ Play")
        self.pause_btn = QPushButton("❚❚ Pause")
        self.stop_btn = QPushButton("■ Stop")
        
        self.position_slider = QSlider(Qt.Orientation.Horizontal)
        self.position_slider.setRange(0, 0)
        
        self.time_label = QLabel("00:00 / 00:00")
        self.volume_slider = QSlider(Qt.Orientation.Horizontal)
        self.volume_slider.setRange(0, 100)
        self.volume_slider.setValue(50)
        
        # Toolbar layout
        toolbar = QHBoxLayout()
        toolbar.addWidget(self.play_btn)
        toolbar.addWidget(self.pause_btn)
        toolbar.addWidget(self.stop_btn)
        toolbar.addWidget(self.position_slider)
        toolbar.addWidget(self.time_label)
        toolbar.addWidget(self.volume_slider)
        toolbar.addStretch()
        
        # Main layout
        main_layout = QVBoxLayout()
        main_layout.addWidget(self.video_widget)
        main_layout.addLayout(toolbar)
        self.setCentralWidget(QWidget())
        self.centralLayout = self.centralWidget().layout()
        self.centralLayout.addLayout(toolbar)
        
        # Signal connections
        self.player.setVideoOutput(self.video_widget)
        self.play_btn.clicked.connect(self.player.play)
        self.pause_btn.clicked.connect(self.player.pause)
        self.stop_btn.clicked.connect(self.player.stop)
        
        self.player.positionChanged.connect(self.position_changed)
        self.player.durationChanged.connect(self.duration_changed)
        
        self.volume_slider.valueChanged.connect(
            lambda v: self.audio_output.setVolume(v / 100)
        )
        
        # Keyboard shortcuts
        self.installEventFilter(self)
        
    def load_video(self, filepath):
        """Load a video file."""
        self.player.setSource(QUrl.fromLocalFile(filepath))
        
    def position_changed(self, position):
        """Update position slider and time display."""
        self.position_slider.setValue(position)
        self.update_time_label()
        
    def duration_changed(self, duration):
        """Update slider range and initial time display."""
        self.position_slider.setRange(0, duration)
        self.update_time_label()
        
    def update_time_label(self):
        """Convert position/duration to MM:SS format."""
        pos = self.player.position() // 1000
        dur = self.player.duration() // 1000 if self.player.duration() > 0 else 0
        
        pos_m, pos_s = divmod(pos, 60)
        dur_m, dur_s = divmod(dur, 60)
        
        self.time_label.setText(
            f"{pos_m:02d}:{pos_s:02d} / {dur_m:02d}:{dur_s:02d}"
        )
        
    def keyPressEvent(self, event):
        """Handle keyboard shortcuts."""
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
        elif event.key() == Qt.Key.Key_k:
            self.player.seek(5)
        elif event.key() == Qt.Key.Key_j:
            self.player.seek(-5)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    # Set application properties
    app.setApplicationName("Video Player")
    app.setOrganizationName("MyOrg")
    
    window = VideoPlayer()
    window.show()
    sys.exit(app.exec())
```

**Controls Reference:**
| Method | Description |
|--------|-------------|
| `play()` | Start playback |
| `pause()` | Pause playback |
| `stop()` | Stop playback and reset position |
| `setPosition(pos)` | Set playback position (milliseconds) |
| `seek(seconds)` | Seek relative to current position |
| `playbackState()` | Returns current state (PlayingState, PausedState, StoppedState) |
| `position()` | Current playback position in milliseconds |
| `duration()` | Total duration in milliseconds |

**Supported Formats:**
- **Audio/Video files**: `.mp4`, `.avi`, `.mkv`, `.mov`, `.flv`, `.webm`, `.wmv`
- **Audio files**: `.mp3`, `.wav`, `.ogg`, `.flac`, `.aac`
- **Real-time**: Camera feed, network streams (RTSP, HTTP)

Note: Codec support varies by platform. On Linux, ensure GStreamer backends are installed.

---

## Camera Access (PySide6)

### QCamera + QMediaCaptureSession

```python
from PySide6.QtMultimedia import QCamera, QMediaDevices, QMediaCaptureSession
from PySide6.QtMultimediaWidgets import QVideoWidget
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QComboBox, QDialogButtonBox
)
from PySide6.QtCore import Qt, QUrl
import sys
from typing import Optional

class CameraViewer(QWidget):
    """Camera viewer with live preview."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Camera Viewer")
        self.setMinimumSize(640, 480)
        
        # Available cameras
        self.cameras = QMediaDevices.videoInputs()
        if not self.cameras:
            self.init_no_camera()
            return
        
        # Selected camera
        self.camera = QCamera(self.cameras[0])
        
        # Video widget for preview
        self.video_widget = QVideoWidget()
        
        # UI components
        self.camera_label = QLabel("No cameras found")
        self.camera_combo = QComboBox()
        self.camera_combo.addItems([f"Camera {i}" for i in range(len(self.cameras))])
        self.start_btn = QPushButton("Start")
        self.stop_btn = QPushButton("Stop")
        self.preview_label = QLabel("Ready")
        
        # Layout
        layout = QVBoxLayout()
        
        # Camera selection
        select_layout = QHBoxLayout()
        select_layout.addWidget(QLabel("Camera:"))
        select_layout.addWidget(self.camera_combo)
        layout.addLayout(select_layout)
        
        # Video preview
        layout.addWidget(self.camera_label)
        layout.addWidget(self.video_widget)
        
        # Controls
        control_layout = QHBoxLayout()
        control_layout.addWidget(self.start_btn)
        control_layout.addWidget(self.stop_btn)
        layout.addLayout(control_layout)
        
        # Status
        layout.addWidget(self.preview_label)
        layout.addStretch()
        
        self.setLayout(layout)
        
        # Setup camera
        self.setup_camera()
        
        # Connect signals
        self.start_btn.clicked.connect(self.start_camera)
        self.stop_btn.clicked.connect(self.stop_camera)
        
    def init_no_camera(self):
        """Initialize UI when no camera is available."""
        self.camera_label.setText("No camera detected")
        self.preview_label.setText("No camera found")
        self.camera_combo.hide()
        
    def setup_camera(self):
        """Configure camera and connect to video output."""
        camera_index = self.camera_combo.currentIndex()
        camera = self.cameras[camera_index]
        
        self.camera = QCamera(camera)
        self.camera.setVideoOutput(self.video_widget)
        
    def start_camera(self):
        """Start camera and enable preview."""
        camera_index = self.camera_combo.currentIndex()
        
        camera = self.cameras[camera_index]
        self.camera = QCamera(camera)
        
        self.camera.setVideoOutput(self.video_widget)
        self.camera.start()
        self.preview_label.setText("Camera active")
        self.start_btn.setText("Restart")
        self.stop_btn.setEnabled(True)
        
    def stop_camera(self):
        """Stop camera and disable preview."""
        self.camera.stop()
        self.preview_label.setText("Camera stopped")
        self.start_btn.setText("Start")
        self.start_btn.setEnabled(False)
        self.stop_btn.setEnabled(False)
        
    def closeEvent(self, event):
        """Clean up camera resources."""
        self.camera.stop()
        super().closeEvent(event)

class CameraCapture(QWidget):
    """Camera with photo capture functionality."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Camera Capture")
        self.setMinimumSize(640, 480)
        
        self.camera = QCamera()
        self.capture_session = QMediaCaptureSession()
        self.image_capture = QImageCapture()
        
        self.video_widget = QVideoWidget()
        self.capture_session.setVideoOutput(self.video_widget)
        
        self.capture_session.setCamera(self.camera)
        self.capture_session.setImageCapture(self.image_capture)
        
        # Image capture settings
        self.image_capture.setCaptureMode(
            QImageCapture.CaptureMode.Photo
        )
        self.image_capture.setResolution(
            self.image_capture.resolutionHighest()
        )
        
        self.image_capture.setCompressionType(
            QImageCapture.CompressionType.Jpeg
        )
        self.image_capture.setJpegQuality(85)
        
        self.capture_btn = QPushButton("Capture Photo")
        self.capture_btn.setEnabled(False)
        self.status_label = QLabel("Ready")
        
        # Layout
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        layout.addWidget(self.capture_btn)
        layout.addWidget(self.status_label)
        self.setLayout(layout)
        
        # Connect signals
        self.capture_btn.clicked.connect(self.capture_photo)
        self.camera.start()
        
    def capture_photo(self):
        """Capture photo from camera."""
        if self.camera.isRunning():
            self.capture_session.setImageCapture(self.image_capture)
            self.image_capture.triggerCapture(
                self.image_capture.imageSize()
            )
            self.status_label.setText("Capturing...")
            
            # Handle captured image
            self.image_capture.imageReady.connect(self.on_image_ready)
        else:
            self.status_label.setText("Camera not running")
            
    def on_image_ready(self, id: int, filePath: str):
        """Callback when image is captured."""
        self.status_label.setText(f"Photo saved: {filePath}")
        self.capture_btn.setEnabled(True)
        
        # Display captured image
        from PySide6.QtGui import QPixmap, QImage
        pixmap = QPixmap(filePath)
        self.video_widget.setPixmap(pixmap.scaled(
            self.video_widget.size(),
            Qt.AspectRatioMode.KeepAspectRatio,
            Qt.TransformationMode.SmoothTransformation
        ))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    window = CameraViewer()
    window.show()
    sys.exit(app.exec())
```

**Camera Device Enumeration:**

```python
from PySide6.QtMultimedia import QMediaDevices

# Get all video input devices (cameras)
cameras = QMediaDevices.videoInputs()
print(f"Available cameras: {len(cameras)}")
for i, camera in enumerate(cameras):
    print(f"  Camera {i}: {camera}")

# Get all video output devices (displays)
video_outputs = QMediaDevices.videoOutputs()

# Get audio input devices (microphones)
audio_inputs = QMediaDevices.audioInputs()

# Get audio output devices (speakers)
audio_outputs = QMediaDevices.audioOutputs()
```

**Photo Capture Options:**

```python
# Set capture mode
self.image_capture.setCaptureMode(
    QImageCapture.CaptureMode.Photo
)

# Set resolution
self.image_capture.setResolution(
    QImageCapture.Resolution.QVGA  # or QualityBestResolution
)

# Set compression
self.image_capture.setCompressionType(
    QImageCapture.CompressionType.Jpeg
)
self.image_capture.setJpegQuality(85)

# Set custom capture dimensions
self.image_capture.setCaptureSize(640, 480)

# Manual capture trigger
self.image_capture.triggerCapture(QSize(640, 480))
```

---

## Media Recording

### QMediaRecorder Setup

```python
from PySide6.QtMultimedia import (
    QMediaRecorder, QMediaCaptureSession, QCamera, QMediaDevices
)
from PySide6.QtMultimediaWidgets import QVideoWidget
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QFileDialog
)
from PySide6.QtCore import QUrl, QStandardPaths
from PySide6.QtGui import QDesktopServices
import os
import sys

class MediaRecorder(QWidget):
    """Complete media recording with audio/video support."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Media Recorder")
        self.setMinimumSize(800, 600)
        
        # Camera setup
        self.camera = QCamera(QMediaDevices.videoInputs()[0])
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        self.capture_session.setVideoOutput(self.video_widget)
        
        # Video widget
        self.video_widget = QVideoWidget()
        
        # Recorder
        self.recorder = QMediaRecorder()
        self.capture_session.setRecorder(self.recorder)
        
        # UI components
        self.record_btn = QPushButton("Start Recording")
        self.record_btn.setEnabled(False)
        self.stop_btn = QPushButton("Stop Recording")
        self.stop_btn.setEnabled(False)
        
        self.status_label = QLabel("Ready")
        self.progress_label = QLabel("")
        
        self.recorder.recorderStateChanged.connect(self.update_status)
        self.recorder.durationChanged.connect(self.duration_changed)
        
        # Layout
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        
        control_layout = QHBoxLayout()
        control_layout.addWidget(self.record_btn)
        control_layout.addWidget(self.stop_btn)
        control_layout.addWidget(self.progress_label)
        layout.addLayout(control_layout)
        
        layout.addWidget(self.status_label)
        layout.addStretch()
        
        self.setLayout(layout)
        
        # Setup recorder defaults
        self.setup_recorder_defaults()
        
        # Connect signals
        self.record_btn.clicked.connect(self.toggle_recording)
        self.stop_btn.clicked.connect(self.stop_recording)
        
    def setup_recorder_defaults(self):
        """Configure default recording settings."""
        # Default output location in Videos folder
        documents = QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.MoviesLocation
        )
        
        # Get video extension based on codec
        self.output_format = "mp4"
        self.output_path = os.path.join(documents, f"recording_{self._get_timestamp()}.{self.output_format}")
        
    def _get_timestamp(self):
        """Generate timestamp string."""
        from datetime import datetime
        return datetime.now().strftime("%Y%m%d_%H%M%S")
        
    def toggle_recording(self):
        """Toggle recording on/off."""
        state = self.recorder.recorderState()
        
        if state == QMediaRecorder.RecorderState.RecordingState:
            self.recorder.stop()
        else:
            self.recorder.setOutputLocation(QUrl.fromLocalFile(self.output_path))
            self.recorder.record()
            
    def stop_recording(self):
        """Stop current recording."""
        self.recorder.stop()
        self.status_label.setText("Recording stopped")
        self.record_btn.setEnabled(True)
        self.record_btn.setText("Record Again")
        self.stop_btn.setEnabled(False)
        
    def update_status(self, state):
        """Update status based on recorder state."""
        states = {
            QMediaRecorder.RecorderState.StoppedState: "Ready to record",
            QMediaRecorder.RecorderState.RecordingState: "Recording...",
            QMediaRecorder.RecorderState.PausedState: "Paused",
            QMediaRecorder.RecorderState.ErrorState: "Error occurred"
        }
        
        self.status_label.setText(states.get(state, "Unknown"))
        
    def duration_changed(self, duration):
        """Update progress based on recording duration."""
        if duration > 0:
            seconds = duration // 1000
            self.progress_label.setText(f"Recording: {seconds} seconds")
    
    def closeEvent(self, event):
        """Clean up resources."""
        self.recorder.stop()
        self.camera.stop()
        super().closeEvent(event)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    window = MediaRecorder()
    window.show()
    sys.exit(app.exec())
```

### Audio Recording Example

```python
from PySide6.QtMultimedia import QMediaRecorder, QMediaCaptureSession
from PySide6.QtCore import QUrl, QStandardPaths, QMimeType
import os
import sys
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QPushButton, QLabel, QFileDialog
)

class AudioRecorder(QWidget):
    """Audio recording from microphone."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Audio Recorder")
        
        self.recorder = QMediaRecorder()
        self.capture_session = QMediaCaptureSession()
        
        # Audio input setup
        audio_inputs = QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.MoviesLocation
        )
        
        self.status_label = QLabel("Ready")
        self.record_btn = QPushButton("Start Recording")
        
        layout = QVBoxLayout()
        layout.addWidget(self.record_btn)
        layout.addWidget(self.status_label)
        self.setLayout(layout)
        
        self.record_btn.clicked.connect(self.toggle_recording)
        self.recorder.recorderStateChanged.connect(self.update_status)
        
        # Default output
        self.output_path = os.path.join(
            audio_inputs, "recording.wav"
        )
        
    def toggle_recording(self):
        """Toggle recording state."""
        state = self.recorder.recorderState()
        
        if state == QMediaRecorder.RecorderState.RecordingState:
            self.recorder.stop()
            self.status_label.setText("Recording stopped")
        else:
            self.recorder.setOutputLocation(QUrl.fromLocalFile(self.output_path))
            self.recorder.setAudioFormat(
                QMediaRecorder.AudioFormat.WAV,
                44100,
                2,
                2,
                -16,
                -1
            )
            self.recorder.record()
            self.status_label.setText("Recording...")
            
    def update_status(self, state):
        """Update status label."""
        if state == QMediaRecorder.RecorderState.RecordingState:
            self.status_label.setText("Recording...")
            self.record_btn.setText("Stop")
        else:
            self.status_label.setText("Recording saved")
            self.record_btn.setText("Start Recording")
    
    def save_recording(self):
        """Save recording to file dialog."""
        file_path, _ = QFileDialog.getSaveFileName(
            self, "Save Recording", self.output_path,
            "Audio Files (*.wav *.mp3 *.ogg *.flac);;All Files (*)"
        )
        if file_path:
            self.recorder.setOutputLocation(QUrl.fromLocalFile(file_path))
            self.output_path = file_path

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AudioRecorder()
    window.show()
    sys.exit(app.exec())
```

### Video Recording Example

```python
from PySide6.QtMultimedia import QMediaRecorder, QMediaCaptureSession
from PySide6.QtCore import QUrl, QStandardPaths
import os
import sys
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QPushButton, QLabel
)

class VideoRecorder(QWidget):
    """Video recording with encoding options."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Video Recorder")
        
        self.camera = QCamera(QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.VideosLocation
        ) + "camera.mp4")
        
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        
        self.recorder = QMediaRecorder()
        self.capture_session.setRecorder(self.recorder)
        
        self.status_label = QLabel("Ready")
        self.record_btn = QPushButton("Start Recording")
        
        layout = QVBoxLayout()
        layout.addWidget(self.record_btn)
        layout.addWidget(self.status_label)
        self.setLayout(layout)
        
        self.record_btn.clicked.connect(self.toggle_recording)
        self.recorder.recorderStateChanged.connect(self.update_status)
        
    def toggle_recording(self):
        """Start/stop video recording."""
        state = self.recorder.recorderState()
        
        if state == QMediaRecorder.RecorderState.RecordingState:
            self.recorder.stop()
        else:
            self.recorder.setMediaFormat(self._get_video_format())
            self.recorder.setVideoCodec(self.recorder.videoFormat().videoCodec())
            self.recorder.setAudioCodec(self.recorder.audioFormat().audioCodec())
            self.recorder.setOutputLocation(QUrl.fromLocalFile("video.mp4"))
            self.recorder.record()
            
    def _get_video_format(self):
        """Get H.264 video format."""
        return QMediaFormat(
            QMediaFormat.MediaFormat.MPEG4,
            self.camera.videoResolution(),
            QMediaFormat.VelocityLevel.Normal,
            2000000,  # 2 Mbps bitrate
            QMediaFormat.ResolutionSelector.Variable
        )
        
    def update_status(self, state):
        """Update status."""
        if state == QMediaRecorder.RecorderState.RecordingState:
            self.status_label.setText("Recording video...")
        else:
            self.status_label.setText("Recording complete")
    
    def save_recording(self):
        """Open save dialog."""
        file_path, _ = QFileDialog.getSaveFileName(
            self, "Save Video", "recording.mp4",
            "Video Files (*.mp4 *.avi *.mkv);;All Files (*)"
        )
        if file_path:
            self.recorder.setOutputLocation(QUrl.fromLocalFile(file_path))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = VideoRecorder()
    window.show()
    sys.exit(app.exec())
```

### Encoding Settings

```python
from PySide6.QtMultimedia import QMediaFormat, QMediaRecorder

# Configure video format
video_format = QMediaFormat()
video_format.setMediaType(QMediaFormat.MediaType.Video)
video_format.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)

# Set resolution
video_format.setResolution(1280, 720)  # 1280x720

# Set bitrate (bytes per second)
video_format.setBitRate(2000000)  # 2 Mbps

# Set video codec
video_format.setVideoCodec(
    QMediaFormat.VideoCodec.H264
)

# Set framerate
video_format.setFrameRate(30)  # 30 FPS

# Create recorder and set format
recorder = QMediaRecorder()
recorder.setMediaFormat(video_format)

# Audio format configuration
audio_format = QMediaFormat()
audio_format.setMediaType(QMediaFormat.MediaType.Audio)
audio_format.setMediaFormat(QMediaFormat.MediaFormat.Mp3)
audio_format.setAudioCodec(QMediaFormat.AudioCodec.AAC)
audio_format.setBitRate(128000)  # 128 kbps

# Full recording setup with encoding
recorder.setVideoCodec(QMediaFormat.VideoCodec.H264)
recorder.setAudioCodec(QMediaFormat.AudioCodec.AAC)
recorder.setVideoFormat(video_format)
recorder.setAudioFormat(audio_format)
recorder.setOutputLocation(QUrl.fromLocalFile("output.mp4"))
recorder.record()
```

---

## Error Handling

### QMediaRecorder Error Handling

```python
from PySide6.QtMultimedia import QMediaRecorder, QMediaFormat
from PySide6.QtWidgets import QMessageBox
import sys
from PySide6.QtWidgets import QApplication

class ErrorHandlingRecorder(QMediaRecorder):
    """MediaRecorder with comprehensive error handling."""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.error_signal = lambda: self.error_occurred()
        
    def error_occurred(self):
        """Handle recorder errors."""
        error_state = self.error()
        
        error_messages = {
            QMediaRecorder.ErrorState.NoError: "No error",
            QMediaRecorder.ErrorState.InvalidRoleError: "Invalid role error",
            QMediaRecorder.ErrorState.InvalidFormatError: "Invalid format error",
            QMediaRecorder.ErrorState.UnsupportedFormatError: "Unsupported format",
            QMediaRecorder.ErrorState.CodecNotAvailableError: "Codec not available",
            QMediaRecorder.ErrorState.UnknownError: "Unknown error"
        }
        
        error_msg = error_messages.get(error_state, "Unknown error")
        QMessageBox.critical(self, "Recording Error", error_msg)
        
        # Reset recorder state
        self.stop()

# Usage with error handling
recorder = ErrorHandlingRecorder()

# Connect to error signal
recorder.error.connect(lambda: print("Recorder error occurred"))

# Set invalid format (to trigger error)
recorder.setMediaFormat(QMediaFormat())
```

### QMediaPlayer Error Signal

```python
from PySide6.QtMultimedia import QMediaPlayer
from PySide6.QtWidgets import QApplication, QWidget, QLabel, QPushButton
from PySide6.QtCore import QUrl
import sys

class ErrorHandlingPlayer(QMediaPlayer):
    """MediaPlayer with error handling."""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.status_label = QLabel("Ready")
        
    def playback_error(self, error_state):
        """Handle playback errors."""
        errors = {
            QMediaPlayer.ErrorState.NoError: "No error",
            QMediaPlayer.ErrorState.InvalidRoleError: "Invalid role error",
            QMediaPlayer.ErrorState.ResourceNotAvailableError: "Resource not available",
            QMediaPlayer.ErrorState.ResourceCannotBeReadError: "Cannot read resource",
            QMediaPlayer.ErrorState.FormatError: "Format error",
            QMediaPlayer.ErrorState.PlaybackFailedError: "Playback failed",
            QMediaPlayer.ErrorState.UnknownMediaError: "Unknown media error",
            QMediaPlayer.ErrorState.ProtocolError: "Protocol error",
            QMediaPlayer.ErrorState.AbstractError: "Abstract error"
        }
        
        error_msg = errors.get(error_state, "Unknown error")
        self.status_label.setText(f"Error: {error_msg}")
        print(f"MediaPlayer error: {error_msg}")

# Usage
app = QApplication(sys.argv)

player = ErrorHandlingPlayer()
player.playbackError.connect(lambda e: print(f"Error: {e}"))

# Load invalid file (to trigger error)
player.setSource(QUrl.fromLocalFile("invalid_file.mp4"))
player.play()

sys.exit(app.exec())
```

### QCamera Error Signal

```python
from PySide6.QtMultimedia import QCamera, QCameraError
from PySide6.QtWidgets import QApplication, QWidget, QLabel, QPushButton
import sys

class ErrorHandlingCamera(QCamera):
    """Camera with error handling."""
    
    def __init__(self, video_input, parent=None):
        super().__init__(video_input, parent)
        self.status_label = QLabel("Ready")
        
    def camera_error(self, error):
        """Handle camera errors."""
        error_codes = {
            QCameraError.NoError: "No error",
            QCameraError.UnsupportedBackendError: "Unsupported backend",
            QCameraError.UnsupportedFormatError: "Unsupported format",
            QCameraError.VideoInputNotFound: "Video input not found",
            QCameraError.ErrorStartingCamera: "Error starting camera",
            QCameraError.ErrorStoppingCamera: "Error stopping camera",
            QCameraError.ErrorReadingProperty: "Error reading property",
            QCameraError.ErrorWritingProperty: "Error writing property",
            QCameraError.FrameAlreadyReleasedError: "Frame already released",
            QCameraError.ErrorResolutionChange: "Error changing resolution",
            QCameraError.ErrorSourceChange: "Error changing source",
            QCameraError.ErrorInvalidState: "Invalid state",
            QCameraError.ErrorImageBufferCreation: "Error creating image buffer",
            QCameraError.ErrorImageBufferRelease: "Error releasing image buffer",
            QCameraError.ErrorInvalidState: "Invalid camera state",
            QCameraError.ErrorAccessingFrameBuffer: "Error accessing frame buffer",
            QCameraError.ErrorRecordingStopped: "Recording stopped"
        }
        
        error_msg = error_codes.get(error, "Unknown error")
        self.status_label.setText(f"Error: {error_msg}")
        print(f"Camera error: {error_msg}")

# Usage
app = QApplication(sys.argv)

camera = ErrorHandlingCamera(QCameraError)
camera.start()
camera.stop()

sys.exit(app.exec())
```

### Common Error Scenarios

```python
from PySide6.QtMultimedia import QMediaPlayer, QMediaDevices, QCamera
from PySide6.QtWidgets import QMessageBox
from PySide6.QtCore import QUrl
import sys

class CommonErrorHandler:
    """Handle common multimedia errors."""
    
    @staticmethod
    def check_device_availability():
        """Check if required devices are available."""
        if not QMediaDevices.audioInputs():
            raise RuntimeError("No audio input devices found")
            
        if not QMediaDevices.videoInputs():
            raise RuntimeError("No camera devices found")
    
    @staticmethod
    def check_file_exists(filepath):
        """Verify file exists and is accessible."""
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"File not found: {filepath}")
            
        if not os.path.isfile(filepath):
            raise FileExistsError("Path is not a file")
    
    @staticmethod
    def handle_codec_error(player, error_state):
        """Handle codec-related errors."""
        if error_state == QMediaPlayer.ErrorState.FormatError:
            QMessageBox.information(
                None, "Codec Error",
                "The required codec is not installed.\n\n"
                "Install K-Lite Codec Pack (Windows) or GStreamer (Linux)."
            )
    
    @staticmethod
    def handle_network_error(player, error_state):
        """Handle network stream errors."""
        if error_state in [
            QMediaPlayer.ErrorState.ResourceNotAvailableError,
            QMediaPlayer.ErrorState.ProtocolError
        ]:
            QMessageBox.warning(
                None, "Network Error",
                "Cannot access network stream.\n"
                "Check your network connection and URL."
            )

# Usage
try:
    CommonErrorHandler.check_device_availability()
    CommonErrorHandler.check_file_exists("video.mp4")
    
    player = QMediaPlayer()
    player.play()
    
except (RuntimeError, FileNotFoundError, FileExistsError) as e:
    print(f"Setup error: {e}")
    sys.exit(1)
```

---

## Codec Support

### Supported Codecs by Platform

#### Linux (GStreamer Backend)

| Codec | Container | Quality | Required Package |
|-------|-----------|---------|------------------|
| **Audio** |
| MP3 | .mp3 | Good | `gstreamer1.0-plugins-good` |
| WAV | .wav | Excellent | Built-in |
| OGG | .ogg | Good | `gstreamer1.0-plugins-good` |
| FLAC | .flac | Excellent | `gstreamer1.0-plugins-good` |
| AAC | .m4a | Good | `gstreamer1.0-plugins-good` |
| **Video** |
| H.264 (AVC) | .mp4, .avi, .mkv | Excellent | `gstreamer1.0-plugins-bad` |
| H.265 (HEVC) | .mp4 | Good | `gstreamer1.0-libav` |
| MPEG-4 | .mp4 | Good | Built-in |
| MPEG-2 | .mpg, .mpeg | Good | `gstreamer1.0-plugins-bad` |
| VP8 | .webm | Good | `gstreamer1.0-plugins-good` |
| VP9 | .webm | Good | `gstreamer1.0-plugins-bad` |
| AV1 | .webm | Excellent | `gstreamer1.0-libav` |

#### Windows (DirectShow/WMF Backend)

| Codec | Container | Quality | Recommended |
|-------|-----------|---------|-------------|
| **Audio** |
| MP3 | .mp3 | Good | K-Lite Codec Pack |
| WAV | .wav | Excellent | Built-in |
| AAC | .m4a | Good | K-Lite Codec Pack |
| WMA | .wma | Good | Built-in |
| **Video** |
| H.264 (AVC) | .mp4, .avi | Excellent | K-Lite Codec Pack |
| H.265 (HEVC) | .mp4 | Good | HEVC Extension |
| MPEG-4 | .mp4 | Good | Built-in |
| WMV | .wmv | Excellent | Built-in |
| AV1 | .webm | Good | AV1 Extensions |

#### macOS (AVFoundation Backend)

| Codec | Container | Quality | Status |
|-------|-----------|---------|--------|
| **Audio** |
| AAC | .m4a | Excellent | Built-in |
| ALAC | .m4a | Excellent | Built-in |
| WAV | .wav | Excellent | Built-in |
| **Video** |
| H.264 (AVC) | .mp4, .mov | Excellent | Built-in |
| H.265 (HEVC) | .mp4 | Good | Built-in (Free) |
| ProRes | .mov | Excellent | Built-in (Professional) |
| AAC | .m4a | Good | Built-in |

### Platform-Specific Notes

#### Linux Installation

```bash
# Ubuntu/Debian
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly

# For better codec support
sudo apt-get install gstreamer1.0-libav gstreamer1.0-clutter

# Fedora
sudo dnf install gstreamer1-devel gstreamer1-plugins-base-devel \
    gstreamer1-plugins-good gstreamer1-plugins-bad gstreamer1-plugins-ugly

# Arch Linux
sudo pacman -S gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    gst-libav gst-clutter

# Verify installation
python -c "from PySide6.QtMultimedia import QMediaDevices; \
    print('Audio inputs:', len(QMediaDevices.audioInputs())); \
    print('Video inputs:', len(QMediaDevices.videoInputs()))"
```

#### Windows Setup

```python
# Check codec support
from PySide6.QtMultimedia import QMediaDevices

def check_codec_support():
    """Check available codec support."""
    audio_inputs = QMediaDevices.audioInputs()
    video_inputs = QMediaDevices.videoInputs()
    
    print(f"Audio devices: {len(audio_inputs)}")
    print(f"Video devices: {len(video_inputs)}")
    
    # If no devices, install codec pack
    if not audio_inputs and not video_inputs:
        print("No codec support detected!")
        print("Install K-Lite Codec Pack: https://codecguide.com/install_windows_kl.mp")
```

**K-Lite Codec Pack (Windows):**
- **Standard**: Audio codecs + video players
- **Basic**: Essential codecs (MPEG-4, H.264)
- **Full**: All codecs including proprietary

#### macOS Notes

No additional installation required. PySide6 uses AVFoundation which includes:
- All standard codecs (H.264, AAC, ProRes)
- AirPlay support for video output
- Camera support via AVFoundation

### Format Compatibility Reference

```python
from PySide6.QtMultimedia import QMediaFormat

# Check format compatibility
def check_format_compatibility(filepath):
    """Check if format is supported."""
    media = QMediaFormat()
    
    supported_formats = {
        QMediaFormat.MediaFormat.MPEG4: "MPEG-4 (MP4, M4V)",
        QMediaFormat.MediaFormat.Wav: "WAV (WAV)",
        QMediaFormat.MediaFormat.Mp3: "MP3 (MP3)",
        QMediaFormat.MediaFormat.Ogg: "OGG (OGG)",
        QMediaFormat.MediaFormat.Flac: "FLAC",
        QMediaFormat.MediaFormat.Aac: "AAC (M4A)",
        QMediaFormat.MediaFormat.H264: "H.264 Video",
        QMediaFormat.MediaFormat.H265: "H.265/HEVC Video",
    }
    
    return supported_formats
```

### Codec Selection Examples

```python
from PySide6.QtMultimedia import QMediaRecorder, QMediaFormat

# Best quality for recording
def setup_high_quality_recording():
    recorder = QMediaRecorder()
    
    # Video format
    video_format = QMediaFormat()
    video_format.setMediaType(QMediaFormat.MediaType.Video)
    video_format.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)
    video_format.setVideoCodec(QMediaFormat.VideoCodec.H264)
    video_format.setResolution(1920, 1080)  # 1080p
    video_format.setBitRate(8000000)  # 8 Mbps
    video_format.setFrameRate(60)  # 60 FPS
    
    # Audio format
    audio_format = QMediaFormat()
    audio_format.setMediaType(QMediaFormat.MediaType.Audio)
    audio_format.setMediaFormat(QMediaFormat.MediaFormat.Mp3)
    audio_format.setAudioCodec(QMediaFormat.AudioCodec.AAC)
    audio_format.setBitRate(320000)  # 320 kbps
    audio_format.setSampleRate(48000)
    
    recorder.setMediaFormat(video_format)
    recorder.setAudioFormat(audio_format)
    return recorder

# Web-compatible recording
def setup_web_recording():
    recorder = QMediaRecorder()
    
    video_format = QMediaFormat()
    video_format.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)
    video_format.setVideoCodec(QMediaFormat.VideoCodec.H264)
    video_format.setResolution(1280, 720)  # 720p for web
    video_format.setBitRate(2000000)  # 2 Mbps
    video_format.setFrameRate(30)
    
    audio_format = QMediaFormat()
    audio_format.setMediaFormat(QMediaFormat.MediaFormat.Mp3)
    audio_format.setAudioCodec(QMediaFormat.AudioCodec.AAC)
    audio_format.setBitRate(128000)
    
    recorder.setMediaFormat(video_format)
    recorder.setAudioFormat(audio_format)
    return recorder

# Mobile-optimized recording
def setup_mobile_recording():
    recorder = QMediaRecorder()
    
    video_format = QMediaFormat()
    video_format.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)
    video_format.setVideoCodec(QMediaFormat.VideoCodec.H264)
    video_format.setResolution(640, 480)  # 480p for mobile
    video_format.setBitRate(500000)  # 0.5 Mbps
    video_format.setFrameRate(30)
    
    audio_format = QMediaFormat()
    audio_format.setMediaFormat(QMediaFormat.MediaFormat.Mp3)
    audio_format.setAudioCodec(QMediaFormat.AudioCodec.AAC)
    audio_format.setBitRate(96000)
    
    recorder.setMediaFormat(video_format)
    recorder.setAudioFormat(audio_format)
    return recorder
```

### Troubleshooting Codec Issues

```python
from PySide6.QtMultimedia import QMediaDevices, QMediaPlayer
from PySide6.QtWidgets import QMessageBox, QLabel

def diagnose_codec_issues():
    """Diagnose codec-related problems."""
    issues = []
    
    # Check device availability
    if not QMediaDevices.audioInputs():
        issues.append("No audio input devices found")
        
    if not QMediaDevices.videoInputs():
        issues.append("No camera devices found")
    
    # Test playback
    player = QMediaPlayer()
    try:
        # This will fail if codec is missing
        player.play()
        issues.append("Playback test inconclusive")
    except Exception as e:
        issues.append(f"Playback error: {e}")
    
    if issues:
        QMessageBox.warning(
            None, "Codec Issues",
            "Issues detected:\n\n" + "\n".join(issues) + "\n\n"
            "Consider installing codec packs for your platform."
        )
    
    return issues
```