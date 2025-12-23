"""
HaberNexus - Görsel ve Video İşleme Sistemi (v2.0)
Medya indirme, optimizasyon, multi-format encoding
"""

import logging
import os
import subprocess
from datetime import datetime
from io import BytesIO

import cv2
import requests
from PIL import Image

logger = logging.getLogger(__name__)


# ============================================================================
# GÖRSEL İŞLEME
# ============================================================================


class ImageProcessor:
    """
    Görselleri indir, optimize et ve çoklu formatlara dönüştür
    """

    SUPPORTED_FORMATS = ["AVIF", "WebP", "JPEG"]

    QUALITY_LEVELS = {
        "high": {"avif": {"quality": 90, "crf": 23}, "webp": {"quality": 85}, "jpeg": {"quality": 90}},
        "medium": {"avif": {"quality": 80, "crf": 28}, "webp": {"quality": 75}, "jpeg": {"quality": 80}},
        "low": {"avif": {"quality": 70, "crf": 35}, "webp": {"quality": 65}, "jpeg": {"quality": 70}},
    }

    def __init__(self, output_dir: str = "/media"):
        self.output_dir = output_dir
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": "HaberNexus/2.0 (+http://habernexus.com)"})

    def download_and_optimize(
        self, image_url: str, article_id: str, quality: str = "high", max_retries: int = 3
    ) -> dict:
        """
        Görseli indir ve optimize et
        """
        try:
            # Görseli indir
            image = self._download_image(image_url, max_retries)

            # Boyutlandır
            image = self._resize_image(image, (1920, 1080))

            # Optimize et
            optimized_paths = self._optimize_image(image, article_id, quality)

            # Metadata oluştur
            metadata = self._create_metadata(image, image_url, optimized_paths, quality)

            return metadata

        except Exception as e:
            logger.error(f"Image processing failed: {e!s}")
            raise

    def _download_image(self, url: str, max_retries: int = 3) -> Image.Image:
        """
        Görseli indir
        """
        for attempt in range(max_retries):
            try:
                response = self.session.get(url, timeout=10)
                response.raise_for_status()

                image = Image.open(BytesIO(response.content))

                # RGB'ye dönüştür (RGBA varsa)
                if image.mode in ("RGBA", "LA", "P"):
                    rgb_image = Image.new("RGB", image.size, (255, 255, 255))
                    rgb_image.paste(image, mask=image.split()[-1] if image.mode == "RGBA" else None)
                    image = rgb_image

                logger.info(f"Image downloaded: {url}")
                return image

            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                logger.warning(f"Retry {attempt + 1}/{max_retries}: {e!s}")
                continue

    def _resize_image(self, image: Image.Image, size: tuple[int, int]) -> Image.Image:
        """
        Görseli belirtilen boyuta yeniden boyutlandır
        """
        image.thumbnail(size, Image.Resampling.LANCZOS)

        # Padding ekle (aspect ratio'yu koru)
        new_image = Image.new("RGB", size, (255, 255, 255))
        offset = ((size[0] - image.width) // 2, (size[1] - image.height) // 2)
        new_image.paste(image, offset)

        return new_image

    def _optimize_image(self, image: Image.Image, article_id: str, quality: str = "high") -> dict[str, str]:
        """
        Görseli AVIF, WebP ve JPEG formatlarında kaydet
        """
        article_dir = os.path.join(self.output_dir, f"articles/{article_id}/featured")
        os.makedirs(article_dir, exist_ok=True)

        paths = {}
        quality_settings = self.QUALITY_LEVELS.get(quality, self.QUALITY_LEVELS["medium"])

        # AVIF formatı (en iyi sıkıştırma)
        try:
            avif_path = os.path.join(article_dir, "featured.avif")
            image.save(avif_path, "AVIF", quality=quality_settings["avif"]["quality"])
            paths["avif"] = avif_path
            logger.info(f"AVIF saved: {avif_path}")
        except Exception as e:
            logger.warning(f"AVIF encoding failed: {e!s}")

        # WebP formatı (fallback)
        try:
            webp_path = os.path.join(article_dir, "featured.webp")
            image.save(webp_path, "WEBP", quality=quality_settings["webp"]["quality"])
            paths["webp"] = webp_path
            logger.info(f"WebP saved: {webp_path}")
        except Exception as e:
            logger.warning(f"WebP encoding failed: {e!s}")

        # JPEG formatı (legacy)
        try:
            jpeg_path = os.path.join(article_dir, "featured.jpg")
            image.save(jpeg_path, "JPEG", quality=quality_settings["jpeg"]["quality"])
            paths["jpeg"] = jpeg_path
            logger.info(f"JPEG saved: {jpeg_path}")
        except Exception as e:
            logger.warning(f"JPEG encoding failed: {e!s}")

        return paths

    def _create_metadata(self, image: Image.Image, source_url: str, optimized_paths: dict, quality: str) -> dict:
        """
        Görsel metadata'sı oluştur
        """
        original_size = len(image.tobytes())
        optimized_size = sum(os.path.getsize(path) for path in optimized_paths.values() if os.path.exists(path))

        compression_ratio = (original_size - optimized_size) / original_size * 100 if original_size > 0 else 0

        return {
            "source_url": source_url,
            "formats": optimized_paths,
            "dimensions": image.size,
            "original_size": original_size,
            "optimized_size": optimized_size,
            "compression_ratio": compression_ratio,
            "quality_level": quality,
            "created_at": datetime.now().isoformat(),
        }

    def create_responsive_images(self, image_path: str, article_id: str, sizes: list[tuple[int, int]] = None) -> dict:
        """
        Responsive görseller oluştur (mobil, tablet, desktop)
        """
        if sizes is None:
            sizes = [(600, 400), (1024, 683), (1920, 1080)]  # Mobil  # Tablet  # Desktop

        image = Image.open(image_path)
        responsive_images = {}

        for width, height in sizes:
            size_name = f"{width}x{height}"
            resized = self._resize_image(image, (width, height))

            article_dir = os.path.join(self.output_dir, f"articles/{article_id}/featured")

            # AVIF
            avif_path = os.path.join(article_dir, f"featured-{size_name}.avif")
            resized.save(avif_path, "AVIF", quality=85)

            # WebP
            webp_path = os.path.join(article_dir, f"featured-{size_name}.webp")
            resized.save(webp_path, "WEBP", quality=80)

            responsive_images[size_name] = {"avif": avif_path, "webp": webp_path, "dimensions": (width, height)}

        return responsive_images


# ============================================================================
# VİDEO İŞLEME
# ============================================================================


class VideoProcessor:
    """
    Videoları indir, encode et ve HLS streaming için hazırla
    """

    ENCODING_PROFILES = {
        "1080p": {
            "resolution": "1920x1080",
            "bitrate": "5128k",
            "fps": 30,
            "codec": "libx264",
            "preset": "slow",
            "crf": 23,
        },
        "720p": {
            "resolution": "1280x720",
            "bitrate": "2596k",
            "fps": 30,
            "codec": "libx264",
            "preset": "medium",
            "crf": 28,
        },
        "480p": {
            "resolution": "854x480",
            "bitrate": "1064k",
            "fps": 24,
            "codec": "libx264",
            "preset": "fast",
            "crf": 32,
        },
        "360p": {
            "resolution": "640x360",
            "bitrate": "548k",
            "fps": 24,
            "codec": "libx264",
            "preset": "fast",
            "crf": 35,
        },
    }

    def __init__(self, output_dir: str = "/media"):
        self.output_dir = output_dir
        self.session = requests.Session()

    def download_and_encode(
        self, video_url: str, article_id: str, profiles: list[str] = None, max_retries: int = 3
    ) -> dict:
        """
        Videoyu indir ve encode et
        """
        if profiles is None:
            profiles = ["1080p", "720p", "480p"]

        try:
            # Videoyu indir
            video_path = self._download_video(video_url, article_id, max_retries)

            # Encode et
            encoded_videos = self._encode_video(video_path, article_id, profiles)

            # HLS manifest oluştur
            hls_manifest = self._create_hls_manifest(encoded_videos, article_id)

            # Metadata oluştur
            metadata = self._create_video_metadata(video_path, encoded_videos, hls_manifest)

            return metadata

        except Exception as e:
            logger.error(f"Video processing failed: {e!s}")
            raise

    def _download_video(self, url: str, article_id: str, max_retries: int = 3) -> str:
        """
        Videoyu indir
        """
        article_dir = os.path.join(self.output_dir, f"articles/{article_id}/video")
        os.makedirs(article_dir, exist_ok=True)

        video_path = os.path.join(article_dir, "original.mp4")

        for attempt in range(max_retries):
            try:
                response = self.session.get(url, stream=True, timeout=30)
                response.raise_for_status()

                with open(video_path, "wb") as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)

                logger.info(f"Video downloaded: {video_path}")
                return video_path

            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                logger.warning(f"Retry {attempt + 1}/{max_retries}: {e!s}")
                continue

    def _encode_video(self, video_path: str, article_id: str, profiles: list[str]) -> dict[str, str]:
        """
        Videoyu farklı çözünürlüklerde encode et
        """
        article_dir = os.path.join(self.output_dir, f"articles/{article_id}/video")
        encoded_videos = {}

        for profile in profiles:
            if profile not in self.ENCODING_PROFILES:
                logger.warning(f"Unknown profile: {profile}")
                continue

            settings = self.ENCODING_PROFILES[profile]
            output_path = os.path.join(article_dir, f"summary-{profile}.mp4")

            try:
                self._run_ffmpeg_encoding(video_path, output_path, settings)

                encoded_videos[profile] = output_path
                logger.info(f"Video encoded: {profile} -> {output_path}")

            except Exception as e:
                logger.error(f"Encoding failed for {profile}: {e!s}")
                continue

        return encoded_videos

    def _run_ffmpeg_encoding(self, input_path: str, output_path: str, settings: dict):
        """
        FFmpeg ile video encode et
        """
        cmd = [
            "ffmpeg",
            "-i",
            input_path,
            "-c:v",
            settings["codec"],
            "-preset",
            settings["preset"],
            "-crf",
            str(settings["crf"]),
            "-s",
            settings["resolution"],
            "-r",
            str(settings["fps"]),
            "-c:a",
            "aac",
            "-b:a",
            "128k",
            "-y",  # Overwrite
            output_path,
        ]

        try:
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=3600)  # 1 saat timeout

            if result.returncode != 0:
                raise Exception(f"FFmpeg error: {result.stderr}")

        except subprocess.TimeoutExpired:
            raise Exception(f"FFmpeg timeout for {output_path}")

    def _create_hls_manifest(self, encoded_videos: dict, article_id: str) -> str:
        """
        HLS master manifest oluştur
        """
        article_dir = os.path.join(self.output_dir, f"articles/{article_id}/video")
        manifest_path = os.path.join(article_dir, "master.m3u8")

        # Bitrate'leri belirle
        bitrates = {"1080p": 5128000, "720p": 2596000, "480p": 1064000, "360p": 548000}

        manifest_content = "#EXTM3U\n#EXT-X-VERSION:3\n"

        for profile, video_path in encoded_videos.items():
            if profile in bitrates:
                bitrate = bitrates[profile]
                resolution = self.ENCODING_PROFILES[profile]["resolution"]

                manifest_content += (
                    f"#EXT-X-STREAM-INF:BANDWIDTH={bitrate},RESOLUTION={resolution}\n{profile}/playlist.m3u8\n"
                )

        with open(manifest_path, "w") as f:
            f.write(manifest_content)

        logger.info(f"HLS manifest created: {manifest_path}")
        return manifest_path

    def _create_video_metadata(self, original_path: str, encoded_videos: dict, hls_manifest: str) -> dict:
        """
        Video metadata'sı oluştur
        """
        # Video süresi al
        try:
            cap = cv2.VideoCapture(original_path)
            fps = cap.get(cv2.CAP_PROP_FPS)
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            duration = frame_count / fps if fps > 0 else 0
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            cap.release()
        except Exception as e:
            logger.warning(f"Failed to get video metadata: {e!s}")
            duration = 0
            width = 0
            height = 0

        return {
            "original_path": original_path,
            "encoded_videos": encoded_videos,
            "hls_manifest": hls_manifest,
            "duration": duration,
            "dimensions": (width, height),
            "created_at": datetime.now().isoformat(),
        }


# ============================================================================
# MEDYA YÖNETİCİ
# ============================================================================


class MediaManager:
    """
    Görsel ve video işlemeyi yönet
    """

    def __init__(self, output_dir: str = "/media"):
        self.output_dir = output_dir
        self.image_processor = ImageProcessor(output_dir)
        self.video_processor = VideoProcessor(output_dir)

    def process_article_media(
        self, article_id: str, image_urls: list[str] = None, video_urls: list[str] = None
    ) -> dict:
        """
        Makale için tüm medyayı işle
        """
        result = {"article_id": article_id, "images": [], "videos": [], "errors": []}

        # Görselleri işle
        if image_urls:
            for idx, image_url in enumerate(image_urls[:3]):  # İlk 3 görseli al
                try:
                    image_metadata = self.image_processor.download_and_optimize(
                        image_url, article_id, quality="high" if idx == 0 else "medium"
                    )
                    result["images"].append(image_metadata)
                except Exception as e:
                    logger.error(f"Image processing failed: {e!s}")
                    result["errors"].append(f"Image {idx}: {e!s}")

        # Videoları işle
        if video_urls:
            for video_url in video_urls[:1]:  # İlk videoyu al
                try:
                    video_metadata = self.video_processor.download_and_encode(video_url, article_id)
                    result["videos"].append(video_metadata)
                except Exception as e:
                    logger.error(f"Video processing failed: {e!s}")
                    result["errors"].append(f"Video: {e!s}")

        return result

    def create_media_html(self, article_id: str, image_metadata: dict = None, video_metadata: dict = None) -> str:
        """
        Medya için HTML kodu oluştur
        """
        html = ""

        # Görsel HTML
        if image_metadata and image_metadata.get("formats"):
            formats = image_metadata["formats"]
            html += "<picture>\n"

            if "avif" in formats:
                html += f'  <source srcset="{formats["avif"]}" type="image/avif">\n'

            if "webp" in formats:
                html += f'  <source srcset="{formats["webp"]}" type="image/webp">\n'

            if "jpeg" in formats:
                html += f'  <img src="{formats["jpeg"]}" alt="{image_metadata.get("alt", "Article image")}">\n'

            html += "</picture>\n"

        # Video HTML
        if video_metadata and video_metadata.get("encoded_videos"):
            html += '<video controls width="100%" height="auto">\n'

            # HLS stream
            if video_metadata.get("hls_manifest"):
                html += f'  <source src="{video_metadata["hls_manifest"]}" type="application/x-mpegURL">\n'

            # Fallback videos
            for profile, path in video_metadata["encoded_videos"].items():
                html += f'  <source src="{path}" type="video/mp4">\n'

            html += "  Your browser does not support the video tag.\n"
            html += "</video>\n"

        return html
