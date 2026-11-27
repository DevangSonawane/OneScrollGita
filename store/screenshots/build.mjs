// Store screenshot builder. No dependencies: Node + Google Chrome (headless).
//
//   node store/screenshots/build.mjs            # every target
//   node store/screenshots/build.mjs ios-6.9    # one target
//
// Raw captures go in store/screenshots/raw/<id>.png (iPhone) and optionally
// store/screenshots/raw-android/<id>.png (falls back to raw/). Missing raws
// render as a labelled placeholder so the layout can be checked first.
// Output: store/screenshots/out/<target>/<id>.png

import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const run = promisify(execFile);
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../..');
const fonts = path.join(repo, 'assets/fonts');
const CHROME =
  process.env.CHROME ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

// Sizes accepted by App Store Connect and Google Play Console.
const TARGETS = {
  'ios-6.9': { w: 1320, h: 2868, os: 'ios' }, // iPhone 6.9" (required)
  'ios-6.3': { w: 1206, h: 2622, os: 'ios' }, // iPhone 6.3"
  'ipad-13': { w: 2064, h: 2752, os: 'ios' }, // iPad 13" (only if iPad is enabled)
  'play-phone': { w: 1080, h: 1920, os: 'android' },
  'play-tablet-7': { w: 1200, h: 1920, os: 'android' },
  'play-tablet-10': { w: 1600, h: 2560, os: 'android' },
};

const C = {
  light: {
    bg: '#FBF8F3', glow: '#F6E3D2', glow2: '#F4EFE7', text: '#232120',
    sub: '#5F5850', eyebrow: '#A04A12', screen: '#F4EFE7', rule: '#D2691E',
  },
  dark: {
    bg: '#14110F', glow: '#3A2A1E', glow2: '#26211C', text: '#EDE6DC',
    sub: '#B5ACA0', eyebrow: '#E39A5E', screen: '#26211C', rule: '#E39A5E',
  },
};

const ICONS = [
  // signal
  '<svg viewBox="0 0 18 12" fill="currentColor"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg>',
  // wifi
  '<svg viewBox="0 0 16 12" fill="currentColor"><path d="M8 2.4c2.4 0 4.6.9 6.3 2.5l1.2-1.3C13.5 1.6 10.9.6 8 .6S2.5 1.6.5 3.6l1.2 1.3C3.4 3.3 5.6 2.4 8 2.4zm0 3.5c1.5 0 2.8.6 3.8 1.5L13 6.1C11.7 4.9 9.9 4.1 8 4.1S4.3 4.9 3 6.1l1.2 1.3c1-.9 2.3-1.5 3.8-1.5zm0 3.4c.6 0 1.1.2 1.5.6L8 11.4 6.5 9.9c.4-.4.9-.6 1.5-.6z"/></svg>',
  // battery
  '<svg viewBox="0 0 27 13" fill="none"><rect x=".5" y=".5" width="23" height="12" rx="3.5" stroke="currentColor" opacity=".4"/><rect x="2" y="2" width="20" height="9" rx="2" fill="currentColor"/><path d="M25 4.5v4c.8-.3 1.3-1.1 1.3-2s-.5-1.7-1.3-2z" fill="currentColor" opacity=".45"/></svg>',
].join('');

const esc = (s) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function rawFor(id, os) {
  const dirs = os === 'android' ? ['raw-android', 'raw'] : ['raw'];
  for (const d of dirs) {
    for (const ext of ['png', 'jpg', 'jpeg']) {
      const p = path.join(here, d, `${id}.${ext}`);
      if (fs.existsSync(p)) return p;
    }
  }
  return null;
}

function html(slide, t) {
  const c = C[slide.theme ?? 'light'];
  // One layout unit. The design canvas is 100 x 217 units (iPhone 6.9"
  // ratio); on wider canvases the height decides, so nothing is clipped.
  const u = Math.min(t.w / 100, t.h / 217);
  const top = slide.layout === 'top';
  const phoneW = 76 * u;
  // Frame matches the raw capture's aspect (iPhone 1206 x 2622), so nothing is cropped.
  const phoneH = (phoneW - 3.2 * u) * (2622 / 1206) + 3.2 * u;
  const textBlock = 58 * u; // room for eyebrow + 2-line title + subtitle
  const phoneTop = top ? t.h - textBlock - phoneH + 6 * u : textBlock + 4 * u;
  const cutout =
    t.os === 'ios'
      ? `<div class="island"></div>`
      : `<div class="hole"></div>`;
  const phones = slide.pair
    ? [
        // Back phone up-left, front phone down-right, both a little smaller.
        { id: slide.id, dx: -15 * u, dy: -2 * u, k: 0.8 },
        { id: slide.pair, dx: 15 * u, dy: 10 * u, k: 0.8 },
      ]
    : [{ id: slide.id, dx: 0, dy: 0, k: 1 }];
  const phoneHtml = phones
    .map((ph, i) => {
      const r = rawFor(ph.id, t.os);
      const status = r && slide.cleanStatus !== false
        ? `<div class="pt pl" id="pl${i}"></div><div class="pt pr" id="pr${i}"></div>
<div class="sb" id="sb${i}"><span class="tm">9:41</span><span class="ic">${ICONS}</span></div>
<script>paint(${i})</script>`
        : '';
      const inner = r
        ? `<img id="raw${i}" src="file://${r}">${status}`
        : `<div class="ph">raw/${ph.id}.png</div>`;
      return `<div class="phone" style="transform:translateX(calc(-50% + ${ph.dx}px)) translateY(${ph.dy}px) scale(${ph.k})">
<div class="screen">${inner}${cutout}</div></div>`;
    })
    .join('\n');

  return `<!doctype html><html><head><meta charset="utf-8"><style>
@font-face{font-family:Literata;src:url("file://${fonts}/Literata.ttf")}
@font-face{font-family:Inter;src:url("file://${fonts}/Inter.ttf")}
@font-face{font-family:Deva;src:url("file://${fonts}/NotoSerifDevanagari.ttf")}
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:${t.w}px;height:${t.h}px;overflow:hidden}
body{background:${c.bg};position:relative;-webkit-font-smoothing:antialiased}
.g1,.g2{position:absolute;border-radius:50%;filter:blur(${14 * u}px)}
.g1{width:${90 * u}px;height:${90 * u}px;background:${c.glow};
  right:${-30 * u}px;${top ? 'bottom' : 'top'}:${-20 * u}px;opacity:.9}
.g2{width:${80 * u}px;height:${80 * u}px;background:${c.glow2};
  left:${-34 * u}px;${top ? 'top' : 'bottom'}:${20 * u}px;opacity:.8}
.text{position:absolute;left:0;right:0;text-align:center;padding:0 ${7 * u}px;
  ${top ? `bottom:${10 * u}px` : `top:${15 * u}px`}}
.eyebrow{font:600 ${3.1 * u}px Inter,Deva;letter-spacing:.2em;
  text-transform:uppercase;color:${c.eyebrow};display:inline-flex;
  align-items:center;gap:${2.4 * u}px}
.eyebrow:before,.eyebrow:after{content:"";width:${5 * u}px;height:${0.35 * u}px;
  background:${c.rule};opacity:.7;border-radius:9px}
h1{font:600 ${9.4 * u}px/1.1 Literata,Deva;color:${c.text};
  margin-top:${3.4 * u}px;letter-spacing:-.01em;white-space:pre-line}
p{font:400 ${3.8 * u}px/1.4 Inter,Deva;color:${c.sub};margin-top:${3 * u}px}
.phone{position:absolute;left:50%;top:${phoneTop}px;width:${phoneW}px;
  height:${phoneH}px;transform-origin:50% 0;background:#0E0C0A;
  border-radius:${12.5 * u}px;padding:${1.6 * u}px;
  box-shadow:0 ${5 * u}px ${12 * u}px rgba(30,15,5,${slide.theme === 'dark' ? '.6' : '.22'}),
    inset 0 0 0 ${0.35 * u}px #3a332c}
.screen{container-type:size;position:relative;width:100%;height:100%;overflow:hidden;
  border-radius:${11 * u}px;background:${c.screen}}
.screen img{width:100%;height:100%;object-fit:cover;object-position:top;display:block}
.island{position:absolute;top:${2.3 * u}px;left:50%;transform:translateX(-50%);
  width:${22 * u}px;height:${6.4 * u}px;border-radius:${4 * u}px;background:#000}
.hole{position:absolute;top:${2.4 * u}px;left:50%;transform:translateX(-50%);
  width:${3.6 * u}px;height:${3.6 * u}px;border-radius:50%;background:#000}
.sb{position:absolute;left:0;right:0;top:0;height:6.2cqh;color:#fff}
.pt{position:absolute;top:1.9cqh;height:3.6cqh;border-radius:2cqw;filter:blur(.8cqw)}
.pl{left:2cqw;width:34cqw}.pr{right:1.5cqw;width:36cqw}
.tm{position:absolute;left:12.2cqw;top:3.66cqh;transform:translate(-50%,-50%);
  font:600 4.3cqw Inter;letter-spacing:-.01em}
.ic{position:absolute;right:6.4cqw;top:3.66cqh;transform:translateY(-50%);
  display:flex;gap:1.5cqw;align-items:center}
.ic svg{height:3.1cqw;width:auto;display:block}
.ph{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;
  font:500 ${3.4 * u}px Inter;color:${c.sub};opacity:.7}
</style>
<script>
// Clean status bar (9:41, full signal and battery). Two soft patches cover
// the capture's own time and icons; each is a gradient between colours
// sampled at its outer and inner edge, so artwork behind it stays visible.
function paint(i){const im=document.getElementById('raw'+i);
const go=()=>{try{const W=im.naturalWidth,H=im.naturalHeight;
const c=document.createElement('canvas');c.width=W;c.height=Math.round(H*.07);
const x=c.getContext('2d');x.drawImage(im,0,0);
const at=(fx)=>{const d=x.getImageData(Math.round(W*fx),Math.round(H*.035),1,1).data;
return [d,'rgb('+d[0]+','+d[1]+','+d[2]+')'];};
const [ld,lo]=at(.015),[,li]=at(.38),[,ro]=at(.985),[,ri]=at(.6);
document.getElementById('pl'+i).style.background='linear-gradient(90deg,'+lo+','+li+')';
document.getElementById('pr'+i).style.background='linear-gradient(90deg,'+ri+','+ro+')';
document.getElementById('sb'+i).style.color=(ld[0]*.3+ld[1]*.59+ld[2]*.11)>140?'#000':'#fff';
}catch(e){}};im.complete?go():im.addEventListener('load',go);}
</script></head><body>
<div class="g1"></div><div class="g2"></div>
${phoneHtml}
<div class="text">
  <div class="eyebrow">${esc(slide.eyebrow)}</div>
  <h1>${esc(slide.title)}</h1>
  <p>${esc(slide.subtitle)}</p>
</div>
</body></html>`;
}

async function shoot(file, out, t) {
  await run(CHROME, [
    '--headless=new', '--disable-gpu', '--hide-scrollbars',
    '--allow-file-access-from-files', '--force-device-scale-factor=1',
    `--window-size=${t.w},${t.h}`, '--virtual-time-budget=4000',
    `--screenshot=${out}`, `file://${file}`,
  ]);
}

const { slides } = JSON.parse(
  fs.readFileSync(path.join(here, 'slides.json'), 'utf8'),
);
const wanted = process.argv.slice(2);
const targets = Object.entries(TARGETS).filter(
  ([k]) => !wanted.length || wanted.includes(k),
);
const tmp = path.join(here, '.build');
fs.mkdirSync(tmp, { recursive: true });

const jobs = [];
for (const [name, t] of targets) {
  const dir = path.join(here, 'out', name);
  fs.mkdirSync(dir, { recursive: true });
  for (const s of slides.filter((s) => t.os === 'ios' || s.play !== false)) {
    const f = path.join(tmp, `${name}-${s.id}.html`);
    fs.writeFileSync(f, html(s, t));
    jobs.push(() => shoot(f, path.join(dir, `${s.id}.png`), t));
  }
}
// Four Chrome processes at a time.
const queue = [...jobs];
await Promise.all(
  Array.from({ length: 4 }, async () => {
    while (queue.length) await queue.shift()();
  }),
);
const missing = slides.filter((s) => !rawFor(s.id, 'ios')).map((s) => s.id);
console.log(`Rendered ${jobs.length} images into store/screenshots/out/`);
if (missing.length) console.log(`Placeholders (no raw yet): ${missing.join(', ')}`);
