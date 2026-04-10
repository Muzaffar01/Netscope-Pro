const fs = require('fs');
function testTrace() {
  const line1 = "  4     *        *        *     Request timed out.";
  const line2 = "  6    17 ms    16 ms    17 ms  172.253.53.145";
  const line3 = "  1    <1 ms     *       <1 ms  192.168.10.73";
  const line4 = " 14    17 ms    17 ms    17 ms  sin11s32-in-f14.1e100.net [142.250.207.142]";
  const line5 = "  2     *        *        *     *"; // Hypothetical full timeout

  const rgx = /^\s*(\d+)\s+([\s\S]+?)\s+(\d+\.\d+\.\d+\.\d+|[a-zA-Z0-9.-]+\s+\[\d+\.\d+\.\d+\.\d+\]|Request timed out\.?|\*)\s*$/i;

  const result = {
    line1: line1.match(rgx),
    line2: line2.match(rgx),
    line3: line3.match(rgx),
    line4: line4.match(rgx),
    line5: line5.match(rgx)
  };
  fs.writeFileSync('regex_test2.json', JSON.stringify(result, null, 2));
}
testTrace();
