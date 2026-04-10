const { exec } = require('child_process');
const fs = require('fs');
const util = require('util');
const execAsync = util.promisify(exec);

async function testTrace() {
  const cmd = `tracert -d -w 500 -h 15 google.com`;
  try {
    const { stdout } = await execAsync(cmd, { timeout: 60000 });
    
    const lines = stdout.split('\n').filter(l => l.trim().length > 0);
    const hops = [];
    for (const line of lines) {
      let match = line.match(/^\s*(\d+)\s+([\s\S]*?)(\d+\.\d+\.\d+\.\d+|\*)/);
      if (match) {
        const hopNum = parseInt(match[1]);
        const ip = match[3] === '*' ? null : match[3];
        const isTimeout = match[3] === '*';
        const latencyMatch = match[2].match(/(\d+)\s*ms|(\<1)\s*ms/);
        let latency = null;
        if (latencyMatch) {
            if (latencyMatch[1]) latency = parseFloat(latencyMatch[1]);
            else if (latencyMatch[2] === '<1') latency = 0.5;
        }

        hops.push({ hop: hopNum, line: line, ip, latency, is_timeout: isTimeout });
      }
    }
    fs.writeFileSync('trace_hops.json', JSON.stringify({ stdout, hops }, null, 2), 'utf8');
  } catch (e) {}
}
testTrace();
