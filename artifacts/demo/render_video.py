"""Render a portrait motion demo from the browser-captured JPEGs.

Requires imageio-ffmpeg. Run from any directory after capturing the screens.
No account state, credentials or uploaded evidence is read by this script.
"""
from pathlib import Path
import subprocess
import tempfile
import array
import wave
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
FONT = '/System/Library/Fonts/Supplemental/Arial.ttf'
SCENES = [
    ('01-home.jpg', 'Small adventures. Real progress.'),
    ('02-quests.jpg', 'Find your next sidequest.'),
    ('03-progress.jpg', 'Follow your own path.'),
    ('08-club-tasks.jpg', 'Complete quests together.'),
    ('10-chat.jpg', 'Keep your crew connected.'),
    ('05-complete.jpg', 'Earn XP. Keep exploring.'),
    ('13-rewards.jpg', 'Earn rewards. Show your badges.'),
]


def run(args):
    subprocess.run([FFMPEG, '-hide_banner', '-loglevel', 'error', '-y', *args], check=True)


with tempfile.TemporaryDirectory(prefix='sidequest-video-') as scratch:
    scratch = Path(scratch)
    for index, (filename, caption) in enumerate(SCENES):
        # Slow camera movement, restrained typography and fades over actual UI.
        filters = (
            "scale=720:1564:flags=lanczos,pad=1080:1920:180:240:color=0x0e1117,"
            f"drawtext=fontfile={FONT}:text='SideQuest':fontsize=60:fontcolor=0x67e887:x=90:y=70,"
            f"drawtext=fontfile={FONT}:text='{caption}':fontsize=36:fontcolor=0xf3f5f0:x=90:y=148,"
            f"drawtext=fontfile={FONT}:text='LAPTOP DEMO':fontsize=22:fontcolor=0x929dad:x=90:y=1840,"
            "zoompan=z='min(1.022,1+on*0.000125)':x='iw/2-iw/zoom/2':"
            "y='ih/2-ih/zoom/2':d=180:s=1080x1920:fps=30,"
            "fade=t=in:st=0:d=0.35,fade=t=out:st=5.65:d=0.35,format=yuv420p"
        )
        run(['-i', str(HERE / filename), '-vf', filters, '-t', '6',
             '-c:v', 'libx264', '-preset', 'fast', '-crf', '20',
             str(scratch / f'{index}.mp4')])
    listing = scratch / 'clips.txt'
    listing.write_text(''.join(f"file '{scratch / f'{i}.mp4'}'\n" for i in range(len(SCENES))))
    run(['-f', 'concat', '-safe', '0', '-i', str(listing), '-c', 'copy', str(scratch / 'silent.mp4')])
    # A finite soundtrack avoids unbounded silence in the encoder filter graph.
    samples = array.array('h', [0]) * (44100 * 6 * len(SCENES))
    for cue, seconds in [('join', 18.5), ('complete', 30.5)]:
        with wave.open(str(ROOT / f'assets/audio/{cue}.wav'), 'rb') as source:
            assert source.getframerate() == 44100 and source.getnchannels() == 1
            cue_samples = array.array('h', source.readframes(source.getnframes()))
        offset = int(seconds * 44100)
        for i, value in enumerate(cue_samples):
            samples[offset + i] = int(value * .55)
    with wave.open(str(scratch / 'audio.wav'), 'wb') as track:
        track.setparams((1, 2, 44100, 0, 'NONE', 'not compressed'))
        track.writeframes(samples.tobytes())
    run(['-i', str(scratch / 'silent.mp4'), '-i', str(scratch / 'audio.wav'),
         '-map', '0:v', '-map', '1:a', '-c:v', 'copy', '-c:a', 'aac',
         '-b:a', '160k', '-t', str(6 * len(SCENES)), '-movflags', '+faststart',
         str(HERE / 'SideQuest-demo.mp4')])
print(f'Rendered SideQuest-demo.mp4: {6 * len(SCENES)} seconds, 1080x1920, 30 fps, completion/join cues.')
