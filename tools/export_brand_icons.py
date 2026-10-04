"""Export the selected SQ artwork to the existing platform icon sizes.

Requires Pillow. No creative changes: opaque RGB, resampling, and safe padding
for maskable web icons. The original generated master remains untouched.
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / 'assets/branding/sidequest-sq-icon-master.png').convert('RGB')


def export(path, size, maskable=False):
    artwork = source.resize((size, size), Image.Resampling.LANCZOS)
    if maskable:
        safe_size = round(size * .85)
        padded = Image.new('RGB', (size, size), source.getpixel((0, 0)))
        padded.paste(source.resize((safe_size, safe_size), Image.Resampling.LANCZOS), ((size-safe_size)//2, (size-safe_size)//2))
        artwork = padded
    artwork.save(ROOT / path, optimize=True)


export('assets/branding/sidequest-app-icon-1024.png', 1024)
export('web/favicon.png', 32)
for size in [192, 512]:
    export(f'web/icons/Icon-{size}.png', size)
    export(f'web/icons/Icon-maskable-{size}.png', size, maskable=True)
for density, size in [('mdpi',48), ('hdpi',72), ('xhdpi',96), ('xxhdpi',144), ('xxxhdpi',192)]:
    export(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
icons = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((icons / 'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
    export((icons / entry['filename']).relative_to(ROOT), size)
print('Exported opaque SQ icons for iOS, Android, web and the 1024px master.')
