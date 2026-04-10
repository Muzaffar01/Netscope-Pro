const express = require('express');
const cors = require('cors');
const axios = require('axios');
const cheerio = require('cheerio');
const dns = require('dns').promises;
const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// IP Geolocation cache
const geoCache = new Map();

async function getGeoInfo(ip) {
  if (!ip || ip === '*' || ip.startsWith('192.168') || ip.startsWith('10.') || ip.startsWith('127.')) {
    return { city: 'Local Network', country: 'Local', country_code: 'LO', latitude: 0, longitude: 0 };
  }

  if (geoCache.has(ip)) return geoCache.get(ip);

  try {
    const response = await axios.get(`http://ip-api.com/json/${ip}?fields=status,city,country,countryCode,lat,lon,org,isp`, {
      timeout: 5000,
    });

    if (response.data.status === 'success') {
      const geo = {
        city: response.data.city,
        country: response.data.country,
        country_code: response.data.countryCode,
        latitude: response.data.lat,
        longitude: response.data.lon,
        org: response.data.org,
        isp: response.data.isp,
      };
      geoCache.set(ip, geo);
      return geo;
    }
  } catch (e) {
    console.log(`Geo lookup failed for ${ip}: ${e.message}`);
  }
  return null;
}

// Fetch domain info (title, description, keywords, favicon)
async function getDomainInfo(domain) {
  try {
    const url = `https://${domain}`;
    const response = await axios.get(url, {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; NetScope/1.0)',
      },
      maxRedirects: 5,
    });

    const $ = cheerio.load(response.data);
    return {
      title: $('title').first().text().trim() || null,
      description: $('meta[name="description"]').attr('content') ||
        $('meta[property="og:description"]').attr('content') || null,
      keywords: ($('meta[name="keywords"]').attr('content') || '')
        .split(',').map(k => k.trim()).filter(k => k.length > 0),
      favicon: $('link[rel="icon"]').attr('href') ||
        $('link[rel="shortcut icon"]').attr('href') ||
        `https://www.google.com/s2/favicons?domain=${domain}&sz=128`,
      url: url,
    };
  } catch (e) {
    console.log(`Domain info fetch failed: ${e.message}`);
    return {
      title: domain,
      description: null,
      keywords: [],
      favicon: `https://www.google.com/s2/favicons?domain=${domain}&sz=128`,
      url: `https://${domain}`,
    };
  }
}

// Get server info
async function getServerInfo(domain) {
  try {
    const addresses = await dns.resolve4(domain);
    const ip = addresses[0];

    // Get server type from HTTP headers
    let serverType = null;
    try {
      const headResponse = await axios.head(`https://${domain}`, {
        timeout: 5000,
        validateStatus: () => true,
      });
      serverType = headResponse.headers['server'] || null;
    } catch (e) {
      // fallback
    }

    const geo = await getGeoInfo(ip);

    return {
      ip: ip,
      hostname: domain,
      server_type: serverType,
      hosting_provider: geo?.org || null,
      city: geo?.city || null,
      country: geo?.country || null,
      country_code: geo?.country_code || null,
      latitude: geo?.latitude || null,
      longitude: geo?.longitude || null,
      org: geo?.org || null,
      isp: geo?.isp || null,
    };
  } catch (e) {
    console.log(`Server info failed: ${e.message}`);
    return null;
  }
}

// Get DNS records
async function getDnsRecords(domain) {
  const records = [];
  const types = [
    { type: 'A', fn: () => dns.resolve4(domain) },
    { type: 'AAAA', fn: () => dns.resolve6(domain) },
    { type: 'MX', fn: () => dns.resolveMx(domain) },
    { type: 'TXT', fn: () => dns.resolveTxt(domain) },
    { type: 'NS', fn: () => dns.resolveNs(domain) },
    { type: 'CNAME', fn: () => dns.resolveCname(domain) },
  ];

  for (const { type, fn } of types) {
    try {
      const result = await fn();
      if (type === 'MX') {
        result.forEach(r => records.push({
          type, name: domain, value: r.exchange, priority: r.priority, ttl: 3600,
        }));
      } else if (type === 'TXT') {
        result.forEach(r => records.push({
          type, name: domain, value: r.join(''), ttl: 3600,
        }));
      } else {
        result.forEach(r => records.push({
          type, name: domain, value: r, ttl: 3600,
        }));
      }
    } catch (e) {
      // Record type not found - skip
    }
  }

  return records;
}

// Get WHOIS info
async function getWhoisInfo(domain) {
  try {
    const whois = require('whois-json');
    const result = await whois(domain);

    return {
      registrar: result.registrar || null,
      creation_date: result.creationDate || result.created || null,
      expiration_date: result.registrarRegistrationExpirationDate || result.expiryDate || null,
      updated_date: result.updatedDate || null,
      name_servers: Array.isArray(result.nameServer)
        ? result.nameServer.join(', ')
        : (result.nameServer || null),
      status: Array.isArray(result.domainStatus)
        ? result.domainStatus.join(', ')
        : (result.domainStatus || null),
      registrant_org: result.registrantOrganization || null,
      registrant_country: result.registrantCountry || null,
    };
  } catch (e) {
    console.log(`WHOIS lookup failed: ${e.message}`);
    return null;
  }
}

// Run traceroute
async function runTraceroute(domain) {
  try {
    const isWindows = process.platform === 'win32';
    const cmd = isWindows
      ? `tracert -d -w 500 -h 15 ${domain}`
      : `traceroute -n -w 1 -q 1 -m 15 ${domain}`;

    const { stdout } = await execAsync(cmd, { timeout: 60000 });
    const hops = parseTraceroute(stdout, isWindows);

    // Enrich hops with geolocation
    for (const hop of hops) {
      if (hop.ip && !hop.is_timeout) {
        const geo = await getGeoInfo(hop.ip);
        if (geo) {
          hop.city = geo.city;
          hop.country = geo.country;
          hop.country_code = geo.country_code;
          hop.latitude = geo.latitude;
          hop.longitude = geo.longitude;
        }
      }
    }

    // Resolve destination IP
    let destIp = '';
    try {
      const addrs = await dns.resolve4(domain);
      destIp = addrs[0] || '';
    } catch (e) { }

    return {
      destination: domain,
      destination_ip: destIp,
      hops: hops,
    };
  } catch (e) {
    console.log(`Traceroute failed: ${e.message}`);
    return null;
  }
}

function parseTraceroute(output, isWindows) {
  const lines = output.split('\n').filter(l => l.trim().length > 0);
  const hops = [];

  for (const line of lines) {
    // Windows format: "  1    <1 ms    <1 ms    <1 ms  192.168.1.1"
    // Linux format:   " 1  192.168.1.1  0.345 ms  0.298 ms  0.276 ms"
    let match;

    if (isWindows) {
      match = line.match(/^\s*(\d+)\s+([\s\S]+?)\s+(\d+\.\d+\.\d+\.\d+|[a-zA-Z0-9.-]+\s+\[\d+\.\d+\.\d+\.\d+\]|Request timed out\.?|\*)\s*$/i);
      if (match) {
        const hopNum = parseInt(match[1]);
        const ipSection = match[3];
        
        let ip = null;
        let isTimeout = ipSection === '*' || ipSection.startsWith('Request timed out');
        
        if (!isTimeout) {
            const ipMatch = ipSection.match(/(\d+\.\d+\.\d+\.\d+)/);
            if (ipMatch) ip = ipMatch[1];
        }

        // Extract latency
        let latency = null;
        const latencyMatch = match[2].match(/(\d+)\s*ms|(\<1)\s*ms/);
        if (latencyMatch) {
            if (latencyMatch[1]) latency = parseFloat(latencyMatch[1]);
            else if (latencyMatch[2] === '<1') latency = 0.5;
        }

        // Only mark pure timeouts where all latency probes failed (latency == null && ip == null)
        isTimeout = (latency === null && ip === null);

        hops.push({
          hop: hopNum,
          ip: ip,
          hostname: null,
          latency: latency,
          is_timeout: isTimeout,
        });
      }
    } else {
      match = line.match(/^\s*(\d+)\s+(\S+)\s+([\d.]+)\s*ms/);
      if (match) {
        const hopNum = parseInt(match[1]);
        const ipOrStar = match[2];
        const isTimeout = ipOrStar === '*';

        hops.push({
          hop: hopNum,
          ip: isTimeout ? null : ipOrStar,
          hostname: null,
          latency: isTimeout ? null : parseFloat(match[3]),
          is_timeout: isTimeout,
        });
      } else {
        // Check for timeout line
        const timeoutMatch = line.match(/^\s*(\d+)\s+\*/);
        if (timeoutMatch) {
          hops.push({
            hop: parseInt(timeoutMatch[1]),
            ip: null,
            hostname: null,
            latency: null,
            is_timeout: true,
          });
        }
      }
    }
  }

  return hops;
}

// Measure ping
async function measurePing(domain) {
  try {
    const start = Date.now();
    await axios.head(`https://${domain}`, {
      timeout: 10000,
      validateStatus: () => true,
    });
    return Date.now() - start;
  } catch (e) {
    try {
      const start = Date.now();
      await axios.head(`http://${domain}`, {
        timeout: 10000,
        validateStatus: () => true,
      });
      return Date.now() - start;
    } catch (e2) {
      return null;
    }
  }
}

// Main lookup endpoint
app.get('/api/lookup', async (req, res) => {
  const domain = req.query.domain;

  if (!domain) {
    return res.status(400).json({ error: 'Domain parameter is required' });
  }

  // Validate domain
  const domainRegex = /^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/;
  if (!domainRegex.test(domain)) {
    return res.status(400).json({ error: 'Invalid domain format' });
  }

  console.log(`\n[${new Date().toISOString()}] Looking up: ${domain}`);

  try {
    // Run all lookups in parallel
    const [domainInfo, serverInfo, dnsRecords, whoisInfo, traceroute, pingMs] =
      await Promise.all([
        getDomainInfo(domain),
        getServerInfo(domain),
        getDnsRecords(domain),
        getWhoisInfo(domain),
        runTraceroute(domain),
        measurePing(domain),
      ]);

    const result = {
      domain_info: domainInfo,
      server_info: serverInfo,
      dns_records: dnsRecords,
      whois_info: whoisInfo,
      traceroute: traceroute,
      ping_ms: pingMs,
    };

    console.log(`[${new Date().toISOString()}] Lookup complete for: ${domain}`);
    res.json(result);
  } catch (e) {
    console.error(`Lookup error: ${e.message}`);
    res.status(500).json({ error: 'Failed to lookup domain' });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════╗
║  NetScope Backend API Server                   ║
║  Running on http://localhost:${PORT}           ║
║  Endpoints:                                    ║
║    GET /api/lookup?domain=example.com          ║
║    GET /api/health                             ║
╚════════════════════════════════════════════════╝
  `);
});
