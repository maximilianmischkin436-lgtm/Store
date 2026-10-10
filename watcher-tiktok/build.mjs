// Generates video/index.html — "The Watcher" TikTok (HyperFrames, 1080x1920).
// Caption timings come from silence detection on the ElevenLabs voiceover.
import { writeFileSync } from "node:fs";

const DUR = 72.4;
const segs = [
  [0.05, 2.67, "Three days after they bought their dream house..."],
  [3.11, 4.84, "someone sent them a letter."],
  [5.28, 6.37, "And it was signed..."],
  [6.76, 7.67, "*The *Watcher."],
  [8.29, 17.96, "In June 2014, Derek and Maria Broaddus paid *$1.3 *million for 657 Boulevard, in Westfield, New Jersey."],
  [18.58, 19.62, "A quiet street."],
  [20.05, 22.21, "A perfect home for their three kids."],
  [22.89, 25.09, "Then the first *letter arrived."],
  [25.66, 28.75, "\"My grandfather watched the house in the 1920s."],
  [29.18, 31.63, "My father watched it in the 1960s."],
  [32.17, 33.50, "It is now *my *time.\""],
  [34.10, 35.24, "More letters came."],
  [35.69, 37.62, "The Watcher knew the color of their *car."],
  [37.99, 40.37, "He knew which kids slept in which *rooms."],
  [40.84, 41.64, "He called them..."],
  [41.95, 42.84, "\"*young *blood.\""],
  [43.28, 46.65, "And he asked one question that still haunts people today."],
  [47.25, 49.29, "\"Have they found what is in the *walls yet?\""],
  [49.81, 51.30, "The police investigated."],
  [51.60, 54.95, "Private detectives. Even *DNA from the envelopes."],
  [55.43, 56.00, "*Nothing."],
  [56.54, 59.69, "The family never spent a *single *night in that house."],
  [60.14, 61.86, "Years later, they sold it..."],
  [62.36, 63.08, "at a *loss."],
  [63.58, 66.52, "To this day, no one knows who The Watcher is."],
  [66.99, 68.76, "Or if he's *still *watching."],
  [69.29, 70.55, "Follow for part two..."],
  [71.02, 72.05, "if you *dare."],
];

// Captions: chunks of <=3 words, each word pops in on its estimated time.
let caps = "";
const capAnims = [];
let ci = 0;
for (const [s, e, text] of segs) {
  const words = text.split(" ");
  const weights = words.map((w) => w.replace(/[*"]/g, "").length + 2);
  const total = weights.reduce((a, b) => a + b, 0);
  let t = s;
  const times = weights.map((w) => { const st = t; t += ((e - s) * w) / total; return st; });
  for (let i = 0; i < words.length; i += 3) {
    const grp = words.slice(i, i + 3);
    const start = times[i];
    const end = i + 3 < words.length ? times[i + 3] : Math.max(e + 0.15, start + 0.4);
    const id = `c${ci++}`;
    const spans = grp.map((w, k) => {
      const hot = w.startsWith("*");
      return `<span class="w${hot ? " hot" : ""}" id="${id}w${k}">${w.replace(/\*/g, "")}</span>`;
    }).join(" ");
    caps += `<div class="cap clip" id="${id}" data-start="${start.toFixed(2)}" data-duration="${(end - start).toFixed(2)}" data-track-index="9">${spans}</div>\n`;
    grp.forEach((_, k) => capAnims.push([`#${id}w${k}`, times[i + k]]));
  }
}

const scene = (id, s, e, inner) =>
  `<section class="scene clip" id="${id}" data-start="${s}" data-duration="${(e - s).toFixed(2)}" data-track-index="1">${inner}</section>`;

const houseSvg = `<svg class="house" viewBox="0 0 600 520" width="760">
  <path class="hs" d="M40 260 L300 60 L560 260 M90 220 V500 H510 V220 M250 500 V380 H350 V500 M300 60 V20 H360 V105"/>
  <rect class="win" x="140" y="280" width="80" height="80"/><rect class="win" x="380" y="280" width="80" height="80"/>
  <rect class="win attic" x="265" y="170" width="70" height="60"/></svg>`;

const html = `<!doctype html>
<html lang="en" data-resolution="portrait">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=1080, height=1920" />
<link href="assets/fonts.css" rel="stylesheet">
<script src="assets/gsap.min.js"></script>
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1080px;height:1920px;overflow:hidden;background:#050505}
#root{position:relative;width:1080px;height:1920px;overflow:hidden;font-family:Inter,sans-serif;color:#eee;background:radial-gradient(ellipse at 50% 35%,#1a0f0f 0%,#060505 70%)}
.scene{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:40px}
.big{font-family:Anton,sans-serif;text-transform:uppercase;letter-spacing:.02em;line-height:.95;text-align:center}
.red{color:#e11d2a;text-shadow:0 0 40px rgba(225,29,42,.6)}
.mono{font-family:"Special Elite",monospace}
.kicker{font-family:Inter;font-weight:800;letter-spacing:.35em;font-size:34px;color:#aaa;text-transform:uppercase}
.cap{position:absolute;left:60px;right:60px;top:1530px;text-align:center;font-family:Anton,sans-serif;font-size:92px;line-height:1.05;text-transform:uppercase;z-index:20;text-shadow:0 6px 0 #000,0 0 30px #000}
.cap .w{display:inline-block;opacity:0}
.cap .hot{color:#ff2b38}
#bar{position:absolute;top:0;left:0;height:10px;width:1080px;background:#e11d2a;transform-origin:left;z-index:30;box-shadow:0 0 20px #e11d2a}
#chip{position:absolute;top:120px;left:50%;transform:translateX(-50%);z-index:30;padding:14px 30px;border:3px solid #e11d2a;color:#fff;font-weight:800;letter-spacing:.3em;font-size:30px;background:rgba(0,0,0,.6)}
#chip i{display:inline-block;width:18px;height:18px;border-radius:50%;background:#e11d2a;margin-right:14px}
#vig{position:absolute;inset:0;z-index:25;pointer-events:none;background:radial-gradient(ellipse at center,transparent 45%,rgba(0,0,0,.92) 100%)}
#grain{position:absolute;inset:-50%;z-index:26;opacity:.09;pointer-events:none;background-image:repeating-radial-gradient(circle at 17% 32%,#fff 0 1px,transparent 1px 3px),repeating-radial-gradient(circle at 83% 71%,#fff 0 1px,transparent 1px 4px)}
#flash{position:absolute;inset:0;z-index:28;background:#fff;opacity:0}
#redflash{position:absolute;inset:0;z-index:27;background:#e11d2a;mix-blend-mode:multiply;opacity:0}
.env{width:620px;height:400px;background:#d8cdb4;position:relative;box-shadow:0 30px 80px #000;border-radius:6px}
.env:before{content:"";position:absolute;inset:0;background:linear-gradient(155deg,transparent 49.5%,#b9ad92 50%) left/50% 100% no-repeat,linear-gradient(-155deg,transparent 49.5%,#b9ad92 50%) right/50% 100% no-repeat}
.env .seal{position:absolute;left:260px;top:160px;width:100px;height:100px;border-radius:50%;background:#8f1018;box-shadow:inset 0 0 20px #400}
.sign{font-family:"Special Elite";font-size:150px;color:#e11d2a;transform:rotate(-4deg)}
.house .hs{fill:none;stroke:#ddd;stroke-width:8;stroke-linecap:round;stroke-linejoin:round}
.house .win{fill:#f5c86a;opacity:0}
.stat{font-family:Anton;font-size:190px;color:#fff}
.paper{width:900px;padding:70px 64px;background:#e9e1cc;color:#1b1b1b;font-family:"Special Elite";font-size:52px;line-height:1.35;box-shadow:0 40px 90px #000;transform:rotate(-2deg)}
.paper p{opacity:0;margin-bottom:28px}
.paper .sig{color:#9b0f19;text-align:right;font-size:58px}
.eye{width:520px;height:260px;border-radius:50%/50%;background:#eee;position:relative;overflow:hidden;box-shadow:0 0 80px rgba(225,29,42,.5)}
.eye .iris{position:absolute;left:180px;top:50px;width:160px;height:160px;border-radius:50%;background:radial-gradient(circle,#000 30%,#5a0a0f 32%,#e11d2a 70%,#300 72%)}
.eye .lid{position:absolute;inset:0;background:#050505;transform-origin:top}
.list{display:flex;flex-direction:column;gap:30px}
.row{font-family:Anton;font-size:96px;text-transform:uppercase;opacity:0;display:flex;align-items:center;gap:34px}
.row b{color:#e11d2a;font-size:100px}
.wall{position:absolute;inset:0;background:repeating-linear-gradient(0deg,#2a201c 0 120px,#1f1714 120px 124px)}
.crack{position:absolute;inset:0}
.crack path{fill:none;stroke:#000;stroke-width:10}
.stamp{font-family:Anton;font-size:130px;color:#e11d2a;border:12px solid #e11d2a;padding:10px 40px;transform:rotate(-12deg);opacity:0}
.sold{font-family:Anton;font-size:110px;background:#e11d2a;color:#fff;padding:10px 40px;transform:rotate(-6deg)}
.cta{font-family:Anton;font-size:150px;text-align:center;line-height:1}
.btn{font-family:Inter;font-weight:800;font-size:56px;background:#e11d2a;color:#fff;padding:26px 70px;border-radius:100px}
</style>
</head>
<body>
<div id="root" data-composition-id="main" data-start="0" data-duration="${DUR}" data-width="1080" data-height="1920">
<audio id="vo" class="clip" src="assets/vo.mp3" data-start="0" data-duration="72.05" data-volume="1" data-track-index="10"></audio>
<audio id="bed" class="clip" src="assets/drone.wav" data-start="0" data-duration="${DUR}" data-volume="0.35" data-track-index="11"></audio>

<div id="world" style="position:absolute;inset:0">
${scene("s1", 0, 8.29, `<div class="kicker" id="s1k">3 days after moving in</div><div class="env" id="env"><div class="seal"></div></div><div class="sign" id="sign" style="opacity:0">The Watcher</div>`)}
${scene("s2", 8.29, 22.89, `<div class="kicker" id="s2k">June 2014 · Westfield, NJ</div>${houseSvg}<div class="stat" id="price">$0</div>`)}
${scene("s3", 22.89, 34.1, `<div class="paper" id="paper"><p id="p1">My grandfather watched the house in the 1920s.</p><p id="p2">My father watched it in the 1960s.</p><p id="p3">It is now my time.</p><p class="sig" id="p4">— The Watcher</p></div>`)}
${scene("s4", 34.1, 43.28, `<div class="eye" id="eye1"><div class="iris" id="iris1"></div><div class="lid" id="lid1"></div></div><div class="list"><div class="row" id="r1"><b>●</b>Their car</div><div class="row" id="r2"><b>●</b>Their rooms</div><div class="row red" id="r3"><b>●</b>"Young blood"</div></div>`)}
${scene("s5", 43.28, 49.81, `<div class="wall"></div><svg class="crack" viewBox="0 0 1080 1920"><path id="crk" d="M540 0 L500 300 L590 520 L470 760 L560 980 L430 1200 L520 1500 L460 1920 M590 520 L800 640 L900 900 M470 760 L230 840 L120 1100"/></svg><div class="big" id="walls" style="font-size:150px;position:relative;margin-top:-500px">What is in<br><span class="red">the walls?</span></div>`)}
${scene("s6", 49.81, 56.54, `<div class="kicker">Case file</div><div class="list"><div class="row" id="x1"><b>✕</b>Police</div><div class="row" id="x2"><b>✕</b>Detectives</div><div class="row" id="x3"><b>✕</b>DNA tests</div></div><div class="stamp" id="stamp">Unsolved</div>`)}
${scene("s7", 56.54, 63.58, `<div class="stat" id="nights" style="opacity:0">0 nights</div><div class="kicker">spent inside</div><div class="sold" id="sold" style="opacity:0">Sold at a loss</div>`)}
${scene("s8", 63.58, 69.29, `<div class="kicker">Identity</div><div class="big" style="font-size:240px" id="unk">Unknown</div><div class="eye" id="eye2" style="margin-top:60px"><div class="iris"></div><div class="lid" id="lid2"></div></div>`)}
${scene("s9", 69.29, DUR, `<div class="cta" id="cta1">Follow for<br><span class="red">Part 2</span></div><div class="btn" id="btn">+ Follow</div>`)}
</div>

${caps}
<div id="bar"></div>
<div id="chip"><i id="dot"></i>TRUE STORY</div>
<div id="redflash"></div><div id="flash"></div>
<div id="vig"></div><div id="grain"></div>
</div>
<script>
const tl = gsap.timeline({ paused: true });
const D = ${DUR};
// persistent: progress bar, grain drift, breathing camera, live dot
tl.fromTo("#bar",{scaleX:0},{scaleX:1,duration:D,ease:"none"},0);
tl.to("#grain",{x:120,y:-90,duration:D,ease:"steps(400)"},0);
tl.fromTo("#world",{scale:1},{scale:1.06,duration:D,ease:"sine.inOut"},0);
for(let t=0;t<D;t+=1.2) tl.to("#dot",{opacity:.2,duration:.6,yoyo:true,repeat:1},t);
const flash=(t,el="#flash",o=.8)=>tl.fromTo(el,{opacity:o},{opacity:0,duration:.45,ease:"power2.out",immediateRender:false},t);
const shake=(t,a=18)=>tl.fromTo("#world",{x:-a},{x:0,duration:.5,ease:"elastic.out(1,.2)",immediateRender:false},t);
// captions word pop
${capAnims.map(([s, t]) => `tl.fromTo("${s}",{opacity:0,scale:1.6,y:20},{opacity:1,scale:1,y:0,duration:.18,ease:"back.out(3)"},${t.toFixed(2)});`).join("\n")}
// S1 hook
tl.from("#s1k",{opacity:0,y:-40,duration:.5},0.1);
tl.fromTo("#env",{scale:2.4,rotation:-14,opacity:0},{scale:1,rotation:-4,opacity:1,duration:.7,ease:"power4.out"},0.05);
tl.to("#env",{y:-20,duration:2,yoyo:true,repeat:2,ease:"sine.inOut"},0.8);
shake(3.1,12);
tl.to("#env",{scale:.75,y:-60,duration:.4},6.85);
tl.fromTo("#sign",{opacity:0,scale:3,filter:"blur(20px)"},{opacity:1,scale:1,filter:"blur(0px)",duration:.35,ease:"power4.out"},6.76);
flash(6.76); flash(6.76,"#redflash",1); shake(6.76,30);
for(let i=0;i<5;i++) tl.to("#sign",{x:i%2?8:-8,skewX:i%2?6:-6,duration:.05},7.1+i*.06);
tl.to("#sign",{x:0,skewX:0,duration:.05},7.45);
// S2 house
tl.from("#s2k",{opacity:0,y:-30,duration:.6},8.4);
tl.fromTo(".hs",{strokeDasharray:2600,strokeDashoffset:2600},{strokeDashoffset:0,duration:3,ease:"power2.inOut"},8.4);
tl.to(".win",{opacity:1,duration:.4,stagger:.3},11.2);
tl.fromTo("#price",{opacity:0},{opacity:1,duration:.3},11.5);
const pr={v:0};tl.to(pr,{v:1300000,duration:1.8,ease:"power2.out",onUpdate:()=>{document.querySelector("#price").textContent="$"+Math.round(pr.v).toLocaleString("en-US")}},11.5);

tl.to(".win",{opacity:.15,duration:.08,yoyo:true,repeat:5},21.2);
tl.to(".attic",{opacity:1,fill:"#e11d2a",duration:.2},22.2);
// S3 letter
tl.fromTo("#paper",{y:900,rotation:8},{y:0,rotation:-2,duration:.8,ease:"power3.out"},22.95);
[["#p1",25.66],["#p2",29.18],["#p3",32.17],["#p4",32.9]].forEach(([s,t])=>tl.fromTo(s,{opacity:0,x:-30},{opacity:1,x:0,duration:.6},t));
tl.to("#p3",{color:"#9b0f19",scale:1.05,transformOrigin:"left",duration:.3},32.6);
shake(32.2,10);
// S4 eye + knowledge
tl.fromTo("#lid1",{scaleY:1},{scaleY:0,duration:.6,ease:"power3.out"},34.2);
tl.to("#iris1",{x:-120,duration:.4},36.0);tl.to("#iris1",{x:120,duration:.4},38.2);tl.to("#iris1",{x:0,y:40,duration:.4},41.9);
tl.fromTo("#r1",{opacity:0,x:-80},{opacity:1,x:0,duration:.4},36.6);
tl.fromTo("#r2",{opacity:0,x:-80},{opacity:1,x:0,duration:.4},39.4);
tl.fromTo("#r3",{opacity:0,scale:2},{opacity:1,scale:1,duration:.3,ease:"power4.out"},41.95);
flash(41.95,"#redflash",.9);shake(41.95,22);
// S5 walls
tl.fromTo("#crk",{strokeDasharray:4000,strokeDashoffset:4000},{strokeDashoffset:0,duration:3.5,ease:"power1.in"},43.4);
tl.fromTo("#walls",{opacity:0,scale:.6},{opacity:1,scale:1,duration:.4,ease:"power4.out"},47.25);
flash(47.25);shake(47.25,40);
tl.to("#walls",{scale:1.12,duration:2.4,ease:"none"},47.7);
// S6 case file
[["#x1",50.0],["#x2",51.7],["#x3",53.2]].forEach(([s,t])=>tl.fromTo(s,{opacity:0,y:40},{opacity:1,y:0,duration:.35},t));
tl.fromTo("#stamp",{opacity:0,scale:3},{opacity:1,scale:1,duration:.25,ease:"power4.in"},55.43);
shake(55.68,35);flash(55.68,"#redflash",.8);
// S7 sold
tl.fromTo("#nights",{opacity:0,y:60},{opacity:1,y:0,duration:.5},57.3);
tl.fromTo("#sold",{opacity:0,scale:2.5},{opacity:1,scale:1,duration:.3,ease:"back.out(2)"},62.36);
shake(62.5,14);
// S8 unknown
tl.fromTo("#unk",{opacity:0,scale:1.4},{opacity:1,scale:1,duration:2.5,ease:"power2.out"},63.7);
tl.fromTo("#lid2",{scaleY:1},{scaleY:0,duration:1.2,ease:"power2.inOut"},66.99);
flash(68.2,"#redflash",.7);
// S9 CTA
tl.fromTo("#cta1",{opacity:0,y:80},{opacity:1,y:0,duration:.5,ease:"back.out(2)"},69.35);
tl.fromTo("#btn",{scale:0},{scale:1,duration:.4,ease:"back.out(3)"},69.8);
tl.to("#btn",{scale:1.08,duration:.4,yoyo:true,repeat:3},70.3);
window.__timelines["main"] = tl;
tl.seek(0);
</script>
</body>
</html>`;
writeFileSync(new URL("./video/index.html", import.meta.url), html);
console.log("ok", ci, "caption chunks");
