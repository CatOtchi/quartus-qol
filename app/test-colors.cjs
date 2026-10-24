const assert = require('node:assert/strict');
const {initialize,highlight,STYLE}=require('./highlighter.cjs');
(async()=>{
 const state=await initialize();
 function check(text,lang='systemverilog') {return highlight(text,lang,state,true);}
 function bracketStyles(r) {return r.details.filter(t=>t.bracket).map(t=>[t.text,t.style]);}
 const nested=check('begin begin begin begin begin begin end end end end end end');
 assert.deepEqual(bracketStyles(nested).map(x=>x[1]),[80,81,82,83,84,85,85,84,83,82,81,80]);
 const brackets=check('begin x(foo[3:0], {a,b}); end');
 assert.deepEqual(bracketStyles(brackets),[['begin',80],['(',81],['[',82],[']',82],['{',82],['}',82],[')',81],['end',80]]);
 const ignored=check('/* begin\n end [] */\n"begin end ()"\n// begin (\nbegin end');
 assert.deepEqual(bracketStyles(ignored),[['begin',80],['end',80]]);
 const example=check('sevenseg #(.WIDTH(8)) display1 (.data(bus[3:0]), .segments(HEX0));');
 for(const [text,style] of [['sevenseg',STYLE.module],['display1',STYLE.instance],['data',STYLE.port],['segments',STYLE.port]]) {
  assert(example.details.some(t=>t.text===text&&t.style===style),`Missing role: ${text}`);
 }
 assert(!bracketStyles(example).some(x=>x[1]===STYLE.unmatched));
 const utf8='// café 😃\r\nbegin\r\n  y="é";\r\nend\r\n';
 const unicode=check(utf8);
 assert.equal(unicode.styles.length,Buffer.byteLength(utf8));
 const begin=Buffer.byteLength(utf8.slice(0,utf8.indexOf('begin')));
 assert.equal(unicode.styles[begin],80);
 const unmatched=check('begin ] end');
 assert.deepEqual(bracketStyles(unmatched),[['begin',80],[']',86],['end',80]]);
 const forks=check('fork begin end join_any\nfork begin end join_none');
 assert.deepEqual(bracketStyles(forks).map(x=>x[1]),[80,81,81,80,80,81,81,80]);
 const verilog=check("module m; assign a=8'hff; endmodule",'verilog');
 assert.deepEqual(bracketStyles(verilog),[['module',80],['endmodule',80]]);
 const incomplete=check('module m(input logic a); always_comb begin if (a[');
 assert(incomplete.styles.length>0);
 const start=performance.now();
 check(('begin x(foo[3:0]); end\n').repeat(1000));
 console.log(`Passed: nesting, punctuation, multiline comments/strings, symbol roles, UTF-8/CRLF, mismatch recovery, fork variants, Verilog, incomplete code. 1000-line sample: ${Math.round(performance.now()-start)} ms.`);
})().catch(e=>{console.error(e);process.exitCode=1;});
