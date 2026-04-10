const fs = require('fs');
function testTrace() {
  const line3 = "  1    <1 ms     *       <1 ms  192.168.10.73";
  let match3 = line3.match(/^\s*(\d+)\s+(.+?)\s+(\d+\.\d+\.\d+\.\d+|[a-zA-Z0-9.-]+\s+\[\d+\.\d+\.\d+\.\d+\]|Request timed out|\*)/i);
  fs.writeFileSync('regex_test.json', JSON.stringify(match3, null, 2));
}
testTrace();
