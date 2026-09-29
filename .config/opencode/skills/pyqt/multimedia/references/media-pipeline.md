# Media Pipeline Deep Dive

Loaded on demand from ../SKILL.md

## QMediaPlayer + QVideoWidget

Complete video player with controls, keyboard shortcuts, and playback state management.

```python
from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput
from PySide6.QtMultimediaWidgets import QVideoWidget
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QSlider, QLabel
)
from PySide6.QtCore import Qt, QUrl
import sys

class VideoPlayer(QWidget):
    def __init__(self):
        super().__init__()
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        
        self.video_widget = QVideoWidget()
        self.player.setVideoOutput(self.video_widget)
        
        # Controls
        self.play_btn = QPushButton("Play")
        self.pause_btn = QPushButton("Pause")
        self.stop_btn = QPushButton("Stop")
        self.position_slider = QSlider(Qt.Orientation.Horizontal)
        self.time_label = QLabel("00:00 / 00:00")
        self.volume_slider = QSlider(Qt.Orientation.Horizontal)
        self.volume_slider.setRange(0, 100)
        
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
        
        # Connections
        self.play_btn.clicked.connect(self.player.play)
        self.pause_btn.clicked.connect(self.player.pause)
        self.stop_btn.clicked.connect(self.player.stop)
        
        self.player.positionChanged.connect(self.position_changed)
        self.player.durationChanged.connect(self.duration_changed)
        self.volume_slider.valueChanged.connect(
            lambda v: self.audio_output.setVolume(v / 100)
        )
        
    def load_video(self, filepath):
        self.player.setSource(QUrl.fromLocalFile(filepath))
        
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
        self.time_label.setText(f"{pos_m:02d}:{pos_s:02d} / {dur_m:02d}:{dur_s:02d}")
        
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

**Playback Control Reference:**
| Method | Description |
|--------|-------------|
| `play()` | Start playback |
| `pause()` | Pause playback |
| `stop()` | Stop and reset position |
| `setPosition(pos)` | Set position in milliseconds |
| `seek(seconds)` | Seek relative to current position |
| `playbackState()` | Returns PlayingState, PausedState, StoppedState |

---

## QCamera + QMediaCaptureSession

Camera with photo capture and session management.

```python
from PySide6.QtMultimedia import QCamera, QMediaDevices, QMediaCaptureSession
from PySide6.QtMultimediaWidgets import QVideoWidget
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout,
    QPushButton, QLabel, QComboBox
)
from PySide6.QtGui import QPixmap
import sys

class CameraViewer(QWidget):
    def __init__(self):
        super().__init__()
        self.cameras = QMediaDevices.videoInputs()
        if not self.cameras:
            self.init_no_camera()
            return
        
        self.camera = QCamera(self.cameras[0])
        self.video_widget = QVideoWidget()
        
        self.camera_combo = QComboBox()
        self.camera_combo.addItems([f"Camera {i}" for i in range(len(self.cameras))])
        self.start_btn = QPushButton("Start")
        self.stop_btn = QPushButton("Stop")
        
        layout = QVBoxLayout()
        select_layout = QHBoxLayout()
        select_layout.addWidget(QLabel("Camera:"))
        select_layout.addWidget(self.camera_combo)
        layout.addLayout(select_layout)
        
        layout.addWidget(self.video_widget)
        layout.addWidget(self.start_btn)
        layout.addWidget(self.stop_btn)
        self.setLayout(layout)
        
        self.camera.setVideoOutput(self.video_widget)
        self.start_btn.clicked.connect(self.start_camera)
        self.stop_btn.clicked.connect(self.stop_camera)
        
    def init_no_camera(self):
        self.video_widget = QLabel("No camera detected")
        self.start_btn = QPushButton()
        self.start_btn.setEnabled(False)
        
    def start_camera(self):
        index = self.camera_combo.currentIndex()
        self.camera = QCamera(self.cameras[index])
        self.camera.setVideoOutput(self.video_widget)
        self.camera.start()
        
    def stop_camera(self):
        self.camera.stop()
        
    def closeEvent(self, event):
        self.camera.stop()
        super().closeEvent(event)

class CameraCapture(QWidget):
    """Camera with photo capture."""
    
    def __init__(self):
        super().__init__()
        self.camera = QCamera()
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        
        self.video_widget = QVideoWidget()
        self.capture_session.setVideoOutput(self.video_widget)
        
        self.image_capture = QImageCapture()
        self.capture_session.setImageCapture(self.image_capture)
        self.image_capture.setCaptureMode(QImageCapture.CaptureMode.Photo)
        self.image_capture.setCompressionType(QImageCapture.CompressionType.Jpeg)
        self.image_capture.setJpegQuality(85)
        
        self.capture_btn = QPushButton("Capture Photo")
        self.status_label = QLabel("Ready")
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        layout.addWidget(self.capture_btn)
        layout.addWidget(self.status_label)
        self.setLayout(layout)
        
        self.capture_btn.clicked.connect(self.capture_photo)
        self.image_capture.imageReady.connect(self.on_image_ready)
        self.camera.start()
        
    def capture_photo(self):
        self.image_capture.triggerCapture(self.image_capture.imageSize())
        self.status_label.setText("Capturing...")
        
    def on_image_ready(self, id: int, filePath: str):
        self.status_label.setText(f"Photo saved: {filePath}")
        pixmap = QPixmap(filePath)
        self.video_widget.setPixmap(pixmap.scaled(
            self.video_widget.size(),
            Qt.AspectRatioMode.KeepAspectRatio,
            Qt.TransformationMode.SmoothTransformation
        ))
```

**Camera Device Enumeration:**
```python
from PySide6.QtMultimedia import QMediaDevices

cameras = QMediaDevices.videoInputs()      # Video inputs (cameras)
audio_inputs = QMediaDevices.audioInputs()  # Microphones
audio_outputs = QMediaDevices.audioOutputs()  # Speakers
video_outputs = QMediaDevices.videoOutputs()  # Displays
```

---

## QMediaRecorder Setup

Media recording with audio/video encoding configuration.

```python
from PySide6.QtMultimedia import (
    QMediaRecorder, QMediaCaptureSession, QCamera, QMediaDevices
)
from PySide6.QtMultimediaWidgets import QVideoWidget
from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel
)
from PySide6.QtCore import QUrl, QStandardPaths
import os
import sys

class MediaRecorder(QWidget):
    def __init__(self):
        super().__init__()
        
        self.camera = QCamera(QMediaDevices.videoInputs()[0])
        self.capture_session = QMediaCaptureSession()
        self.capture_session.setCamera(self.camera)
        
        self.video_widget = QVideoWidget()
        self.capture_session.setVideoOutput(self.video_widget)
        
        self.recorder = QMediaRecorder()
        self.capture_session.setRecorder(self.recorder)
        
        self.record_btn = QPushButton("Start Recording")
        self.stop_btn = QPushButton("Stop Recording")
        self.stop_btn.setEnabled(False)
        self.status_label = QLabel("Ready")
        self.progress_label = QLabel("")
        
        layout = QVBoxLayout()
        layout.addWidget(self.video_widget)
        
        control_layout = QHBoxLayout()
        control_layout.addWidget(self.record_btn)
        control_layout.addWidget(self.stop_btn)
        control_layout.addWidget(self.progress_label)
        layout.addLayout(control_layout)
        
        layout.addWidget(self.status_label)
        self.setLayout(layout)
        
        self.setup_recorder_defaults()
        self.record_btn.clicked.connect(self.toggle_recording)
        self.stop_btn.clicked.connect(self.stop_recording)
        self.recorder.recorderStateChanged.connect(self.update_status)
        self.recorder.durationChanged.connect(self.duration_changed)
        
    def setup_recorder_defaults(self):
        documents = QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.MoviesLocation
        )
        self.output_path = os.path.join(documents, f"recording_{self._get_timestamp()}.mp4")
        
    def _get_timestamp(self):
        from datetime import datetime
        return datetime.now().strftime("%Y%m%d_%H%M%S")
        
    def toggle_recording(self):
        if self.recorder.recorderState() == QMediaRecorder.RecorderState.RecordingState:
            self.recorder.stop()
        else:
            self.recorder.setOutputLocation(QUrl.fromLocalFile(self.output_path))
            self.recorder.record()
            self.record_btn.setEnabled(False)
            self.stop_btn.setEnabled(True)
            
    def stop_recording(self):
        self.recorder.stop()
        self.record_btn.setEnabled(True)
        self.stop_btn.setEnabled(False)
        
    def update_status(self, state):
        states = {
            QMediaRecorder.RecorderState.StoppedState: "Ready to record",
            QMediaRecorder.RecorderState.RecordingState: "Recording...",
            QMediaRecorder.RecorderState.PausedState: "Paused",
            QMediaRecorder.RecorderState.ErrorState: "Error occurred"
        }
        self.status_label.setText(states.get(state, "Unknown"))
        
    def duration_changed(self, duration):
        if duration > 0:
            seconds = duration // 1000
            self.progress_label.setText(f"Recording: {seconds} seconds")
            
    def closeEvent(self, event):
        self.recorder.stop()
        self.camera.stop()
        super().closeEvent(event)
```

### Audio Recording

```python
from PySide6.QtMultimedia import QMediaRecorder, QMediaCaptureSession, QAudioInput
from PySide6.QtCore import QUrl, QStandardPaths
from PySide6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel
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
        
        documents = QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.MoviesLocation
        )
        self.output_path = os.path.join(documents, "recording.wav")
        
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

## Error Handling

### QMediaRecorder Errors

```python
from PySide6.QtMultimedia import QMediaRecorder
from PySide6.QtWidgets import QMessageBox

class ErrorHandlingRecorder:
    def handle_error(self, recorder: QMediaRecorder):
        error_state = recorder.error()
        
        error_messages = {
            QMediaRecorder.ErrorState.NoError: "No error",
            QMediaRecorder.ErrorState.InvalidRoleError: "Invalid role error",
            QMediaRecorder.ErrorState.InvalidFormatError: "Invalid format error",
            QMediaRecorder.ErrorState.UnsupportedFormatError: "Unsupported format",
            QMediaRecorder.ErrorState.CodecNotAvailableError: "Codec not available",
            QMediaRecorder.ErrorState.UnknownError: "Unknown error"
        }
        
        error_msg = error_messages.get(error_state, "Unknown error")
        QMessageBox.critical(None, "Recording Error", error_msg)
```

### QMediaPlayer Error Signal

```python
from PySide6.QtMultimedia import QMediaPlayer

class ErrorHandlingPlayer:
    def handle_playback_error(self, error_state: QMediaPlayer.ErrorState):
        errors = {
            QMediaPlayer.ErrorState.NoError: "No error",
            QMediaPlayer.ErrorState.InvalidRoleError: "Invalid role error",
            QMediaPlayer.ErrorState.ResourceNotAvailableError: "Resource not available",
            QMediaPlayer.ErrorState.ResourceCannotBeReadError: "Cannot read resource",
            QMediaPlayer.ErrorState.FormatError: "Format error",
            QMediaPlayer.ErrorState.PlaybackFailedError: "Playback failed",
            QMediaPlayer.ErrorState.UnknownMediaError: "Unknown media error",
            QMediaPlayer.ErrorState.ProtocolError: "Protocol error"
        }
        
        error_msg = errors.get(error_state, "Unknown error")
        print(f"MediaPlayer error: {error_msg}")
```

### QCamera Error Signal

```python
from PySide6.QtMultimedia import QCamera, QCameraError

class ErrorHandlingCamera:
    def handle_camera_error(self, error: QCameraError):
        error_codes = {
            QCameraError.NoError: "No error",
            QCameraError.UnsupportedBackendError: "Unsupported backend",
            QCameraError.UnsupportedFormatError: "Unsupported format",
            QCameraError.VideoInputNotFound: "Video input not found",
            QCameraError.ErrorStartingCamera: "Error starting camera",
            QCameraError.ErrorStoppingCamera: "Error stopping camera",
            QCameraError.ErrorResolutionChange: "Error changing resolution",
            QCameraError.ErrorInvalidState: "Invalid camera state"
        }
        
        error_msg = error_codes.get(error.code(), "Unknown error")
        print(f"Camera error: {error_msg}")
```

### Common Error Scenarios

```python
from PySide6.QtMultimedia import QMediaPlayer, QMediaDevices, QCamera
from PySide6.QtWidgets import QMessageBox
import os

class CommonErrorHandler:
    @staticmethod
    def check_device_availability():
        if not QMediaDevices.audioInputs():
            raise RuntimeError("No audio input devices found")
        if not QMediaDevices.videoInputs():
            raise RuntimeError("No camera devices found")
    
    @staticmethod
    def check_file_exists(filepath):
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"File not found: {filepath}")
    
    @staticmethod
    def handle_codec_error(error_state):
        if error_state == QMediaPlayer.ErrorState.FormatError:
            QMessageBox.information(
                None, "Codec Error",
                "The required codec is not installed.\n\n"
                "Install K-Lite Codec Pack (Windows) or GStreamer (Linux)."
            )
    
    @staticmethod
    def handle_network_error(error_state):
        if error_state in [
            QMediaPlayer.ErrorState.ResourceNotAvailableError,
            QMediaPlayer.ErrorState.ProtocolError
        ]:
            QMessageBox.warning(
                None, "Network Error",
                "Cannot access network stream.\n"
                "Check your network connection and URL."
            )
```