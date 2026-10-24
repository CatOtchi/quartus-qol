// VS Code's actual TextMate engine and the user's installed HDL grammar.
// Local-only worker. Input/output are ASCII, one request per line.
const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline');
const tm = require('./vendor/vscode-textmate');
const onig = require('./vendor/vscode-oniguruma');
const vendor = path.join(__dirname, 'vendor/veriloghdl');
const STYLE = Object.freeze({text:64, comment:65, string:66, number:67,
  keyword:68, type:69, module:70, function:71, port:72, instance:73,
  constant:74, preprocessor:75, operator:76, label:77, escape:78,
  depth:80, unmatched:86});

function category(scopes) {
  // A more specific child scope wins over the surrounding context.
  if (scopes.some(s => s.startsWith('comment'))) return STYLE.comment;
  for (const s of [...scopes].reverse()) {
    if (/^constant\.character/.test(s)) return STYLE.escape;
    if (/^string|^punctuation\.definition\.string/.test(s)) return STYLE.string;
    if (/^meta\.preprocessor|^punctuation\.definition\.directive|preprocessor|compiler\.directive/.test(s)) return STYLE.preprocessor;
    if (/^constant\.numeric/.test(s)) return STYLE.number;
    if (/^constant|^variable\.other\.constant/.test(s)) return STYLE.constant;
    if (/^support\.function\.port/.test(s)) return STYLE.port;
    if (/^entity\.name\.(type\.module|tag\.module\.reference)/.test(s)) return STYLE.module;
    if (/^variable\.other\.module|^entity\.name\.tag\.module\.identifier/.test(s)) return STYLE.instance;
    if (/^entity\.name\.function|^support\.function/.test(s)) return STYLE.function;
    if (/^entity\.name/.test(s)) return STYLE.label;
    if (/^storage\.type|^support\.(type|class)/.test(s)) return STYLE.type;
    if (/^keyword\.operator|^punctuation/.test(s)) return STYLE.operator;
    if (/^keyword|^storage\.modifier/.test(s)) return STYLE.keyword;
  }
  return STYLE.text;
}

async function initialize() {
  await onig.loadWASM(fs.readFileSync(path.join(__dirname, 'vendor/vscode-oniguruma/release/onig.wasm')));
  const registry = new tm.Registry({
    onigLib: Promise.resolve({createOnigScanner: patterns => new onig.OnigScanner(patterns),
      createOnigString: text => new onig.OnigString(text)}),
    loadGrammar: async scope => {
      const lang = scope === 'source.verilog' ? 'verilog' : 'systemverilog';
      return tm.parseRawGrammar(fs.readFileSync(path.join(vendor, `${lang}.tmLanguage.json`), 'utf8'), 'grammar.json');
    }
  });
  const grammars = {};
  const pairs = {};
  for (const lang of ['verilog', 'systemverilog']) {
    grammars[lang] = await registry.loadGrammar(`source.${lang}`);
    pairs[lang] = JSON.parse(fs.readFileSync(path.join(vendor, `${lang}.configuration.json`), 'utf8')).brackets;
  }
  return {grammars, pairs};
}

function highlight(text, lang, state, inspect=false) {
  const styles = Buffer.alloc(Buffer.byteLength(text), STYLE.text);
  const opens = new Map(), closes = new Set();
  for (const [a,b] of state.pairs[lang]) {
    if (!opens.has(a)) opens.set(a, new Set());
    opens.get(a).add(b); closes.add(b);
  }
  const words = [...new Set([...opens.keys(), ...closes])].filter(w => w.length > 1);
  const bracketRE = new RegExp(`\\b(?:${words.join('|')})\\b|[()\\[\\]{}]`, 'g');
  const nesting = [], details = [];
  let ruleStack = tm.INITIAL, byteOffset = 0;
  for (const chunk of text.match(/[^\n]*\n|[^\n]+$/g) || []) {
    const line = chunk.replace(/\r?\n$/, '');
    const result = state.grammars[lang].tokenizeLine(line, ruleStack, 100);
    if (result.stoppedEarly) throw new Error('Syntax tokenization time limit exceeded');
    ruleStack = result.ruleStack;
    const opaque = new Uint8Array(line.length);
    for (const token of result.tokens) {
      const start = Math.min(line.length, token.startIndex), end = Math.min(line.length, token.endIndex);
      const a = byteOffset + Buffer.byteLength(line.slice(0, start));
      const b = byteOffset + Buffer.byteLength(line.slice(0, end));
      const style = category(token.scopes);
      styles.fill(style, a, b);
      if (token.scopes.some(s => /^(comment|string)/.test(s))) opaque.fill(1,start,end);
      if (inspect && end > start) details.push({text:line.slice(start,end),start:a,end:b,style,scopes:token.scopes});
    }
    bracketRE.lastIndex = 0;
    for (const match of line.matchAll(bracketRE)) {
      const at = match.index, value = match[0];
      if (opaque[at] || (value.length > 1 && at > 0 && /[\\$\w]/.test(line[at-1]))) continue;
      let style;
      if (opens.has(value)) {
        style = STYLE.depth + nesting.length % 6;
        nesting.push({close:opens.get(value),style});
      } else {
        let index = nesting.length - 1;
        while (index >= 0 && !nesting[index].close.has(value)) index--;
        if (index < 0) style = STYLE.unmatched;
        else {style = nesting[index].style; nesting.length = index;}
      }
      const a = byteOffset + Buffer.byteLength(line.slice(0, at));
      styles.fill(style, a, a + Buffer.byteLength(value));
      if (inspect) details.push({text:value,start:a,end:a+Buffer.byteLength(value),style,bracket:true});
    }
    byteOffset += Buffer.byteLength(chunk);
  }
  return {styles,details};
}

module.exports = {initialize,highlight,STYLE,category};
if (require.main === module) {
  initialize().then(state => {
    const input = readline.createInterface({input:process.stdin,crlfDelay:Infinity});
    input.on('line', line => {
      const [id,lang,data] = line.split(' ');
      try {
        if (!/^\d+$/.test(id) || !state.grammars[lang]) throw new Error('Invalid request');
        const text = Buffer.from(data || '', 'base64').toString('utf8');
        if (Buffer.byteLength(text) > 4*1024*1024) throw new Error('Source exceeds highlight limit');
        const result = highlight(text,lang,state);
        process.stdout.write(`${id} ok ${result.styles.toString('base64')}\n`);
      } catch (error) {
        process.stdout.write(`${id} error ${Buffer.from(error.message).toString('base64')}\n`);
      }
    });
  }).catch(error => {process.stderr.write(error.stack+'\n');process.exitCode=1;});
}
