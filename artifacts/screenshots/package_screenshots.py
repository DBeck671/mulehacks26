"""Package actual browser screenshots and verified Git development milestones."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import subprocess, zipfile
ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / '2026-10-04'
files = sorted(f for f in OUT.glob('[0-9][0-9]-*.jpg'))
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 17)
heading = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 30)
cols, cellw, cellh = 5, 236, 465
sheet = Image.new('RGB', (cols*cellw+40, ((len(files)+cols-1)//cols)*cellh+110), '#101319')
draw = ImageDraw.Draw(sheet)
draw.text((24,20), 'SideQuest — screenshot collection', font=heading, fill='#67e887')
draw.text((24,65), 'Actual Flutter UI · 440 × 956 phone viewport · October 4, 2026', font=font, fill='#adb6c4')
for i,f in enumerate(files):
    x=20+(i%cols)*cellw; y=110+(i//cols)*cellh
    im=Image.open(f).convert('RGB'); im.thumbnail((212,412))
    sheet.paste(im,(x,y))
    title=f.stem.replace('-', ' ')
    words=title.split(); lines=['']
    for word in words:
        if draw.textlength(lines[-1]+' '+word,font=font)>210: lines.append(word)
        else: lines[-1]=(lines[-1]+' '+word).strip()
    draw.multiline_text((x,y+419),'\n'.join(lines),font=font,fill='#e9edf5',spacing=3)
sheet.save(OUT/'contact-sheet.jpg',quality=94)
preview = Image.new('RGB',(748,1055),'#101319')
pd = ImageDraw.Draw(preview)
pd.text((24,18),'SideQuest · demo screens',font=heading,fill='#67e887')
for i,name in enumerate(['26-welcome.jpg','01-home.jpg','02-quests.jpg','32-active-tree-connections.jpg','12-club-discovery.jpg','24-rewards-light.jpg']):
    im=Image.open(OUT/name); im.thumbnail((220,478))
    preview.paste(im,(24+(i%3)*240,65+(i//3)*490))
preview.save(OUT/'preview.jpg',quality=94)
stages = [
 ('1. Core app', 'f038a64', 'Quest catalogue, verification methods, accounts, clubs and saved history.'),
 ('2. Personal progress', 'fef28de', 'Fresh new accounts and isolated profile/progress storage.'),
 ('3. Navigation and social demo', 'f77cefd', 'Phone navigation, quest browsing, active tasks and simulated friends.'),
 ('4. Quest connections', 'e9cac06', 'Full prerequisite map; category colours followed in 2bca901.'),
 ('5. Verification and lifecycle', '2598d0d', 'Photo checks, pause/resume refinements and a two-active-task limit; background timers followed in 0990f62.'),
 ('6. Rewards and identity', '25f2328', 'Demo tokens, reward offers and visible club badges; three selectable badges followed in de91e9c.'),
 ('7. Direct Gemini and presentation polish', '2aa9742', 'Server-only photo-verification gateway; active pulses, gesture isolation, demo reset and SQ identity followed.'),
 ('8. Club discovery and themes', '5522f67', 'Public/private clubs, join approvals, cloud membership and a calm light theme.'),
]
readme = ['# SideQuest screenshots and development stages', '',
 f'{len(files)} actual browser screenshots captured October 4, 2026 at a 440 × 956 CSS-pixel phone viewport. These are Flutter web-preview captures, not native iPhone screenshots or generated mockups.', '',
 '## Capture context', '',
 '- Login and create-account screenshots come from the configured authentication preview at localhost:8081. No account was created and no credentials were entered.',
 '- Other screens come from an isolated in-memory capture fixture at localhost:8085. They do not alter the user’s running demo at localhost:8083 or its saved activity history.',
 '- The fixture starts at a seeded demo level. Real new accounts start fresh. Bot members, bot chat, sample partner offers and simulated completion are presentation data.',
 '- GPS screenshot shows the tracking requirements and ready state; it is not evidence of a real outdoor GPS test. The photo completion uses the explicitly marked demo simulation, not a new Gemini verification request.',
 '- Long pages have additional scroll-position screenshots. The XP celebration image deliberately captures an animation frame, while the suggestions image shows the settled result.',
 '- The set contains current UI flow stages. The development milestones below are verified Git history, not a claim that these images show older versions.', '',
 '## Screenshot index', '']
readme += [f'- [{f.stem.replace("-", " ")}]({f.name})' for f in files]
readme += ['', '## Development milestones', '', 'All milestones below were committed October 4, 2026; the repository initial commit was October 3.']
for title,ref,description in stages:
    subject=subprocess.check_output(['git','show','-s','--format=%s',ref],cwd=ROOT,text=True).strip()
    readme += ['', f'### {title}', '', f'{description}', '', f'Source: commit `{ref}` — {subject}.']
readme += ['', '## Suggested demo sequence', '', 'Login → onboarding → Home → Quests → start/pause task → completion and suggestions → Activity Log → Progress connections → club discovery → shared tasks and members → group chat → rewards and badges → light theme.', '', '## Recreate the package', '', 'Capture JPEGs through the browser at 440 × 956, then run `python artifacts/screenshots/package_screenshots.py` with Pillow installed. The welcome-only fixture is available at `http://localhost:8085/?screen=welcome`.']
(OUT/'README.md').write_text('\n'.join(readme)+'\n')
with zipfile.ZipFile(OUT.parent/'SideQuest-screenshots.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in sorted(OUT.iterdir()):
        if f.is_file(): z.write(f,'SideQuest-screenshots/'+f.name)
print(f'Packaged {len(files)} screenshots.')
