# Codecs & Platforms

Loaded on demand from ../SKILL.md

## Supported Codecs by Platform

### Linux (GStreamer Backend)

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

### Windows (DirectShow/WMF Backend)

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

### macOS (AVFoundation Backend)

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

---

## Platform Installation

### Linux Installation

```bash
# Ubuntu/Debian - core plugins
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly

# Additional codec support
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

### Windows Setup

**K-Lite Codec Pack:**
- **Standard**: Audio codecs + video players
- **Basic**: Essential codecs (MPEG-4, H.264)
- **Full**: All codecs including proprietary

```python
# Check codec support
from PySide6.QtMultimedia import QMediaDevices

def check_codec_support():
    audio_inputs = QMediaDevices.audioInputs()
    video_inputs = QMediaDevices.videoInputs()
    
    print(f"Audio devices: {len(audio_inputs)}")
    print(f"Video devices: {len(video_inputs)}")
    
    if not audio_inputs and not video_inputs:
        print("No codec support detected!")
        print("Install K-Lite Codec Pack: https://codecguide.com/install_windows_kl.mp")
```

### macOS Notes

No additional installation required. PySide6 uses AVFoundation which includes:
- All standard codecs (H.264, AAC, ProRes)
- AirPlay support for video output
- Camera support via AVFoundation

---

## Format Compatibility Reference

```python
from PySide6.QtMultimedia import QMediaFormat

def check_format_compatibility():
    """Return supported format list."""
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

---

## Codec Selection Examples

### High Quality Recording

```python
from PySide6.QtMultimedia import QMediaRecorder, QMediaFormat

def setup_high_quality_recording():
    recorder = QMediaRecorder()
    
    video_format = QMediaFormat()
    video_format.setMediaType(QMediaFormat.MediaType.Video)
    video_format.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)
    video_format.setVideoCodec(QMediaFormat.VideoCodec.H264)
    video_format.setResolution(1920, 1080)  # 1080p
    video_format.setBitRate(8000000)  # 8 Mbps
    video_format.setFrameRate(60)  # 60 FPS
    
    audio_format = QMediaFormat()
    audio_format.setMediaType(QMediaFormat.MediaType.Audio)
    audio_format.setAudioCodec(QMediaFormat.AudioCodec.AAC)
    audio_format.setBitRate(320000)  # 320 kbps
    audio_format.setSampleRate(48000)
    
    recorder.setMediaFormat(video_format)
    recorder.setAudioFormat(audio_format)
    return recorder
```

### Web-Optimized Recording

```python
def setup_web_recording():
    recorder = QMediaRecorder()
    
    video_format = QMediaFormat()
    video_format.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)
    video_format.setVideoCodec(QMediaFormat.VideoCodec.H264)
    video_format.setResolution(1280, 720)  # 720p
    video_format.setBitRate(2000000)  # 2 Mbps
    video_format.setFrameRate(30)
    
    audio_format = QMediaFormat()
    audio_format.setMediaFormat(QMediaFormat.MediaFormat.Mp3)
    audio_format.setAudioCodec(QMediaFormat.AudioCodec.AAC)
    audio_format.setBitRate(128000)
    
    recorder.setMediaFormat(video_format)
    recorder.setAudioFormat(audio_format)
    return recorder
```

### Mobile-Optimized Recording

```python
def setup_mobile_recording():
    recorder = QMediaRecorder()
    
    video_format = QMediaFormat()
    video_format.setMediaFormat(QMediaFormat.MediaFormat.MPEG4)
    video_format.setVideoCodec(QMediaFormat.VideoCodec.H264)
    video_format.setResolution(640, 480)  # 480p
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

---

## Codec Troubleshooting

```python
from PySide6.QtMultimedia import QMediaDevices, QMediaPlayer
from PySide6.QtWidgets import QMessageBox

def diagnose_codec_issues():
    """Diagnose codec-related problems."""
    issues = []
    
    if not QMediaDevices.audioInputs():
        issues.append("No audio input devices found")
    if not QMediaDevices.videoInputs():
        issues.append("No camera devices found")
    
    player = QMediaPlayer()
    try:
        player.play()
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

### Common Solutions

1. **No playback on Linux**: Install GStreamer plugins
   ```bash
   sudo apt-get install gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
   ```

2. **No H.265/HEVC support**:
   - Linux: `sudo apt-get install gstreamer1.0-libav`
   - Windows: Install HEVC Extension from Microsoft Store
   - macOS: Built-in support

3. **No audio recording**:
   - Check microphone permissions (macOS: System Preferences > Privacy)
   - Verify audio input device: `QMediaDevices.audioInputs()`

4. **Format not supported**:
   - Convert to MP4 with H.264 + AAC (widest compatibility)
   - Check codec availability for your platform