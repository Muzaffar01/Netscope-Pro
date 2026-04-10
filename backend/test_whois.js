const whois = require('whois-json');

async function testWhois() {
  const start = Date.now();
  console.log("Starting whois...");
  try {
    const result = await whois('github.com');
    console.log("Whois finished in", Date.now() - start, "ms");
  } catch (e) {
    console.error("Error:", e);
  }
}
testWhois();
