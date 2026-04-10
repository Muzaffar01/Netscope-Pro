const axios = require('axios');

async function test() {
  try {
    const r = await axios.get('http://localhost:3000/api/lookup?domain=google.com', { timeout: 120000 });
    const t = r.data.traceroute;
    if (t) {
      console.log('Destination:', t.destination, t.destination_ip);
      console.log('Total hops:', t.hops.length);
      for (const h of t.hops) {
        console.log(JSON.stringify({
          hop: h.hop,
          ip: h.ip,
          latency: h.latency,
          city: h.city,
          country: h.country,
          lat: h.latitude,
          lng: h.longitude,
          timeout: h.is_timeout
        }));
      }
    } else {
      console.log('No traceroute data');
    }
  } catch (e) {
    console.log('Error:', e.message);
  }
}
test();
