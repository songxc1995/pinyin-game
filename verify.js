/* 拼音小厨房 · 词库校验
   用法：node verify.js
   改动 LEVELS 后务必跑一遍，防止三拼混入两拼关、整体认读写错等教学性错误。
*/
const fs = require('fs');
const path = require('path');

const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');
const src = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const seg = src.slice(src.indexOf('const LEVELS'), src.indexOf('const TOTAL_WORDS'));
const D = new Function(seg + '; return {LEVELS,INIT_ORDER,FINAL_ORDER,WHOLE_ORDER,TMAP,baseOf,toneIdx};')();
const { LEVELS, INIT_ORDER, FINAL_ORDER, WHOLE_ORDER, baseOf } = D;

const MED = ['i', 'u', 'ü'];
const tone = s => s.normalize('NFD').replace(/[̀-ͯ]/g, '');
const bare = s => baseOf(s).replace(/v/g, 'ü');   // baseOf 把 ü 折成 v，还原

let err = 0, warn = 0;
const seen = {};   // 汉字 -> Set(拼音)，发现多音字只提示

console.log('关  模式   词条  声母 介音 韵母   名称');
LEVELS.forEach((lv, li) => {
  const n = li + 1, mode = lv.mode;
  const keys = new Set();
  lv.words.forEach(w => {
    const shape = mode === 'whole' ? 2 : mode === 'tri' ? 4 : 3;
    if (w.length !== shape) { console.log(`❌ L${n} 词条形状不符(mode=${mode})`, JSON.stringify(w)); err++; }

    let py, ch, parts;
    if (mode === 'whole') {
      py = w[0]; ch = w[1]; parts = [w[0]];
      const b = bare(w[0]);
      if (!WHOLE_ORDER.includes(b)) { console.log(`❌ L${n} 不是整体认读音节: ${w[0]} -> ${b}`); err++; }
    } else if (mode === 'tri') {
      parts = [w[0], w[1], w[2]]; ch = w[3];
      py = w[0] + ((['j', 'q', 'x'].includes(w[0]) && w[1] === 'ü') ? 'u' : w[1]) + w[2];
      if (!INIT_ORDER.includes(w[0])) { console.log(`❌ L${n} 声母非法`, JSON.stringify(w)); err++; }
      if (!MED.includes(w[1])) { console.log(`❌ L${n} 介音必须是 i/u/ü`, JSON.stringify(w)); err++; }
      const fb = bare(w[2]);
      if (!FINAL_ORDER.includes(fb)) { console.log(`❌ L${n} 三拼的韵母不在 24 韵母表: ${fb}`, JSON.stringify(w)); err++; }
      // j q x 与 ü 相拼时去两点，还原后再查整体认读
      const triBare = (['j', 'q', 'x'].includes(w[0]) && w[1] === 'ü' ? 'u' : w[1]) + bare(w[2]);
      const triNoTone = w[0] + triBare.split('').map(c => baseOf(c)).join('');
      if (WHOLE_ORDER.includes(triNoTone)) { console.log(`❌ L${n} 三拼关混入整体认读: ${py} (${triNoTone})`); err++; }
    } else {
      parts = [w[0], w[1]]; ch = w[2]; py = w[0] + w[1];
      if (!INIT_ORDER.includes(w[0])) { console.log(`❌ L${n} 声母非法`, JSON.stringify(w)); err++; }
      let fb = bare(w[1]);
      // j q x 永不与 u 相拼，卡片上的 u 一定是 ü 去两点后的写法（ju→jü、xue→xüe、jun→jün）
      if (['j', 'q', 'x'].includes(w[0]) && fb[0] === 'u') fb = 'ü' + fb.slice(1);
      if (!FINAL_ORDER.includes(fb)) {
        const isTri = MED.includes(fb[0]) && fb.length > 1 && FINAL_ORDER.includes(fb.slice(1));
        console.log(`❌ L${n} 两拼关出现非标准韵母「${fb}」(${w[0]}+${w[1]}=${ch})`
          + (isTri ? ` —— 这是三拼，应写成 ${w[0]}-${fb[0]}-${fb.slice(1)} 放进第 9 关` : ''));
        err++;
      }
      // 去调后比对（py 带声调，WHOLE_ORDER 不带调，直接比对会永远不命中）
      const noTone = w[0] + bare(w[1]);
      if (WHOLE_ORDER.includes(noTone)) { console.log(`❌ L${n} 两拼关混入整体认读: ${py} -> ${noTone}`); err++; }
      if (WHOLE_ORDER.includes(py)) { console.log(`❌ L${n} 两拼关混入整体认读(带调): ${py}`); err++; }
    }

    const k = parts.join('|');
    if (keys.has(k)) { console.log(`❌ L${n} 同关答案冲突(同一组卡片对应多个字): ${k} -> ${ch}`); err++; }
    keys.add(k);

    seen[ch] = seen[ch] || new Set(); seen[ch].add(py);

    // 标调位置（只提醒，不判死）
    const b = bare(mode === 'whole' ? w[0] : (mode === 'tri' ? w[2] : w[1]));
    const marked = (mode === 'whole' ? w[0] : (mode === 'tri' ? w[2] : w[1]))
      .split('').filter(c => c in D.TMAP);
    if (marked.length === 1) {
      const want = (b.includes('a')) ? 'a' : (b.includes('o')) ? 'o' : (b.includes('e')) ? 'e'
        : (b === 'iu') ? 'u' : (b === 'ui') ? 'i' : (b.includes('i')) ? 'i'
          : (b.includes('u')) ? 'u' : (b.includes('ü')) ? 'ü' : null;
      const got = bare(marked[0]);
      if (want && got !== want) { console.log(`⚠️  L${n} 调号位置可疑: ${py} 标在「${got}」，规则应在「${want}」`); warn++; }
    }
  });

  const ni = new Set(lv.words.map(w => w[0])).size;
  const nm = mode === 'tri' ? new Set(lv.words.map(w => w[1])).size : 0;
  const nf = mode === 'whole' ? 0 : new Set(lv.words.map(w => w[mode === 'tri' ? 2 : 1])).size;
  console.log(`L${n}  ${mode.padEnd(6)}${String(lv.words.length).padStart(4)}${String(ni).padStart(6)}${String(nm).padStart(5)}${String(nf).padStart(5)}   ${lv.name.replace(/^第 \d 关 · /, '')}`);
});

console.log('---');

/* 跨关检查：同一个字（或同一个音节）既被当整体认读、又被拆开拼读 —— 这是最隐蔽的教学冲突 */
const bySyllable = {};   // 去调音节 -> [{lv, mode, py, ch}]
const byCharMix = {};    // 汉字 -> 是否混合了整体认读与拼读
LEVELS.forEach((lv, li) => {
  const n = li + 1;
  lv.words.forEach(w => {
    let py, ch;
    if (lv.mode === 'whole') { py = w[0]; ch = w[1]; }
    else if (lv.mode === 'tri') { py = w[0] + ((['j', 'q', 'x'].includes(w[0]) && w[1] === 'ü') ? 'u' : w[1]) + w[2]; ch = w[3]; }
    else { py = w[0] + w[1]; ch = w[2]; }
    const noTone = py.split('').map(c => baseOf(c)).join('').replace(/v/g, 'ü');
    const rec = { lv: n, mode: lv.mode, py, ch, whole: WHOLE_ORDER.includes(noTone) };
    (bySyllable[noTone] = bySyllable[noTone] || []).push(rec);
    (byCharMix[ch] = byCharMix[ch] || []).push(rec);
  });
});

Object.keys(bySyllable).forEach(syl => {
  const arr = bySyllable[syl];
  const asWhole = arr.filter(a => a.mode === 'whole');
  const asSplit = arr.filter(a => a.mode !== 'whole');
  // 同一个音节在整体认读关、又在拼读关 —— 教学冲突
  if (asWhole.length && asSplit.length) {
    console.log(`❌ 音节「${syl}」既在整体认读关、又在拼读关: `
      + arr.map(a => `L${a.lv}(${a.mode})${a.py}=${a.ch}`).join(' '));
    err++;
  }
  // 同一个音节散落在两个不同的拼读关（不算硬错，但要提醒避免重复刷题）
  else if (new Set(asSplit.map(a => a.lv)).size > 1) {
    console.log(`⚠️  音节「${syl}」出现在多个拼读关: ` + asSplit.map(a => `L${a.lv}${a.py}=${a.ch}`).join(' '));
    warn++;
  }
});

/* 多音字：同一个字在同一关出现多个读音 —— 题目只显示单字，孩子拼对了也会被判错 */
LEVELS.forEach((lv, li) => {
  const n = li + 1, m = {};
  lv.words.forEach(w => {
    const py = lv.mode === 'tri' ? w[0] + w[1] + w[2] : (lv.mode === 'whole' ? w[0] : w[0] + w[1]);
    const ch = lv.mode === 'tri' ? w[3] : (lv.mode === 'whole' ? w[1] : w[2]);
    (m[ch] = m[ch] || []).push(py);
  });
  Object.keys(m).forEach(ch => {
    const uniq = [...new Set(m[ch])];
    if (uniq.length > 1) {
      console.log(`❌ L${n} 同关内多音字「${ch}」有 ${uniq.length} 个读音: ${uniq.join(' / ')}（无上下文，孩子无法判断该读哪个）`);
      err++;
    }
  });
});

/* 卡片区防线：即使答案正确，声母卡 × 韵母卡 也可能拼出整体认读音节（孩子会拼出 zh+ī 却被判错） */
LEVELS.forEach((lv, li) => {
  const n = li + 1;
  if (lv.mode !== 'split') return;
  const ini = [...new Set(lv.words.map(w => w[0]))];
  const fin = [...new Set(lv.words.map(w => bare(w[1])))];
  const hits = [];
  ini.forEach(i => fin.forEach(f => { if (WHOLE_ORDER.includes(i + f)) hits.push(i + f); }));
  if (hits.length) {
    console.log(`⚠️  L${n} 卡片能拼出整体认读音节: ${hits.join(', ')}（答案里没有，但孩子会这么拼）`);
    warn++;
  }
});

Object.keys(byCharMix).forEach(ch => {
  const arr = byCharMix[ch];
  if (arr.some(a => a.whole) && arr.some(a => !a.whole)) {
    console.log(`❌ 汉字「${ch}」既被当整体认读又被拆开拼: ` + arr.map(a => `L${a.lv}${a.py}`).join(' '));
    err++;
  }
});

Object.keys(seen).forEach(c => { if (seen[c].size > 1) console.log('· 一字多音(正常):', c, [...seen[c]].join('/')); });
const total = LEVELS.reduce((a, l) => a + l.words.length, 0);
console.log('总词条', total, '| 不重复汉字', Object.keys(seen).length);
console.log(err ? `❌ 硬错误 ${err} 处` : '✅ 词库校验通过', warn ? `（另有 ${warn} 条提醒）` : '');
process.exit(err ? 1 : 0);
