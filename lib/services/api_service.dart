import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:netscope/models/website_info.dart';

class ApiService {
  // For production, replace with your backend URL
  // The app uses a demo mode with simulated data when backend is unreachable
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  Future<WebsiteInfo> getWebsiteInfo(String domain) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/lookup?domain=$domain'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return WebsiteInfo.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('API ERROR: $e');
      // Fall back to demo data for demonstration purposes
      return _generateDemoData(domain);
    }
  }

  /// Generates realistic demo data for demonstration when backend is unavailable
  WebsiteInfo _generateDemoData(String domain) {
    final random = Random(domain.hashCode);

    // Generate realistic traceroute hops
    final hops = <TracerouteHop>[];
    final hopCities = [
      {'city': 'Local Network', 'country': 'Local', 'code': 'LO', 'lat': 0.0, 'lng': 0.0},
      {'city': 'Mumbai', 'country': 'India', 'code': 'IN', 'lat': 19.076, 'lng': 72.877},
      {'city': 'Chennai', 'country': 'India', 'code': 'IN', 'lat': 13.082, 'lng': 80.270},
      {'city': 'Singapore', 'country': 'Singapore', 'code': 'SG', 'lat': 1.352, 'lng': 103.819},
      {'city': 'Tokyo', 'country': 'Japan', 'code': 'JP', 'lat': 35.689, 'lng': 139.691},
      {'city': 'Los Angeles', 'country': 'United States', 'code': 'US', 'lat': 34.052, 'lng': -118.243},
      {'city': 'San Jose', 'country': 'United States', 'code': 'US', 'lat': 37.338, 'lng': -121.886},
      {'city': 'Ashburn', 'country': 'United States', 'code': 'US', 'lat': 39.043, 'lng': -77.487},
      {'city': 'New York', 'country': 'United States', 'code': 'US', 'lat': 40.712, 'lng': -74.005},
      {'city': 'London', 'country': 'United Kingdom', 'code': 'GB', 'lat': 51.507, 'lng': -0.127},
      {'city': 'Frankfurt', 'country': 'Germany', 'code': 'DE', 'lat': 50.110, 'lng': 8.682},
      {'city': 'Amsterdam', 'country': 'Netherlands', 'code': 'NL', 'lat': 52.366, 'lng': 4.894},
    ];

    final numHops = 6 + random.nextInt(5);
    final selectedCities = <Map<String, dynamic>>[];
    selectedCities.add(hopCities[0]); // Always start with local
    
    final remainingCities = List<Map<String, dynamic>>.from(hopCities.sublist(1));
    remainingCities.shuffle(random);
    
    for (int i = 0; i < numHops - 1 && i < remainingCities.length; i++) {
      selectedCities.add(remainingCities[i]);
    }

    double cumulativeLatency = 1.0;
    for (int i = 0; i < selectedCities.length; i++) {
      final city = selectedCities[i];
      cumulativeLatency += 2.0 + random.nextDouble() * (i < 3 ? 15.0 : 40.0);
      final isTimeout = random.nextDouble() < 0.08;
      hops.add(TracerouteHop(
        hop: i + 1,
        ip: isTimeout ? null : '${10 + random.nextInt(245)}.${random.nextInt(255)}.${random.nextInt(255)}.${random.nextInt(255)}',
        hostname: isTimeout ? null : (i == 0 ? 'gateway.local' : 'node-$i.$domain'),
        latency: isTimeout ? null : double.parse(cumulativeLatency.toStringAsFixed(1)),
        city: isTimeout ? null : city['city'] as String,
        country: isTimeout ? null : city['country'] as String,
        countryCode: isTimeout ? null : city['code'] as String,
        latitude: isTimeout ? null : (city['lat'] as double) + (random.nextDouble() - 0.5) * 0.1,
        longitude: isTimeout ? null : (city['lng'] as double) + (random.nextDouble() - 0.5) * 0.1,
        isTimeout: isTimeout,
      ));
    }

    final serverIp = '${104 + random.nextInt(50)}.${random.nextInt(255)}.${random.nextInt(255)}.${random.nextInt(255)}';
    final serverCity = selectedCities.last;

    final serverTypes = ['nginx', 'Apache', 'cloudflare', 'gws', 'Microsoft-IIS', 'LiteSpeed'];
    final hostingProviders = ['Cloudflare, Inc.', 'Amazon Web Services', 'Google Cloud', 'Microsoft Azure', 'DigitalOcean', 'Fastly'];
    final isps = ['Cloudflare', 'Amazon.com', 'Google LLC', 'Microsoft Corporation', 'DigitalOcean'];

    final dnsRecords = <DnsRecord>[
      DnsRecord(type: 'A', name: domain, value: serverIp, ttl: 300),
      DnsRecord(type: 'AAAA', name: domain, value: '2606:4700:${random.nextInt(9999)}:${random.nextInt(9999)}::${random.nextInt(99)}', ttl: 300),
      DnsRecord(type: 'CNAME', name: 'www.$domain', value: domain, ttl: 3600),
      DnsRecord(type: 'MX', name: domain, value: 'mail.$domain', ttl: 3600, priority: 10),
      DnsRecord(type: 'MX', name: domain, value: 'mail2.$domain', ttl: 3600, priority: 20),
      DnsRecord(type: 'TXT', name: domain, value: 'v=spf1 include:_spf.google.com ~all', ttl: 3600),
      DnsRecord(type: 'TXT', name: domain, value: 'google-site-verification=${_randomString(43, random)}', ttl: 3600),
      DnsRecord(type: 'NS', name: domain, value: 'ns1.$domain', ttl: 86400),
      DnsRecord(type: 'NS', name: domain, value: 'ns2.$domain', ttl: 86400),
    ];

    final creationYear = 1995 + random.nextInt(25);
    final expirationYear = 2025 + random.nextInt(5);

    return WebsiteInfo(
      domainInfo: DomainInfo(
        title: _generateTitle(domain),
        description: 'Welcome to $domain - A leading platform providing innovative solutions and services worldwide.',
        keywords: ['technology', 'services', domain.split('.')[0], 'innovation', 'digital', 'platform'],
        favicon: 'https://www.google.com/s2/favicons?domain=$domain&sz=128',
        url: 'https://$domain',
      ),
      serverInfo: ServerInfo(
        ip: serverIp,
        hostname: domain,
        serverType: serverTypes[random.nextInt(serverTypes.length)],
        hostingProvider: hostingProviders[random.nextInt(hostingProviders.length)],
        city: serverCity['city'] as String,
        country: serverCity['country'] as String,
        countryCode: serverCity['code'] as String,
        latitude: serverCity['lat'] as double,
        longitude: serverCity['lng'] as double,
        org: hostingProviders[random.nextInt(hostingProviders.length)],
        isp: isps[random.nextInt(isps.length)],
      ),
      dnsRecords: dnsRecords,
      whoisInfo: WhoisInfo(
        registrar: 'MarkMonitor Inc.',
        creationDate: '$creationYear-${(1 + random.nextInt(12)).toString().padLeft(2, '0')}-${(1 + random.nextInt(28)).toString().padLeft(2, '0')}',
        expirationDate: '$expirationYear-${(1 + random.nextInt(12)).toString().padLeft(2, '0')}-${(1 + random.nextInt(28)).toString().padLeft(2, '0')}',
        updatedDate: '2024-${(1 + random.nextInt(12)).toString().padLeft(2, '0')}-${(1 + random.nextInt(28)).toString().padLeft(2, '0')}',
        nameServers: 'ns1.$domain, ns2.$domain',
        status: 'clientDeleteProhibited, clientTransferProhibited, clientUpdateProhibited',
        registrantOrg: '${domain.split('.')[0][0].toUpperCase()}${domain.split('.')[0].substring(1)} Inc.',
        registrantCountry: serverCity['country'] as String,
      ),
      traceroute: TracerouteResult(
        destination: domain,
        destinationIp: serverIp,
        hops: hops,
      ),
      pingMs: double.parse((5.0 + random.nextDouble() * 150.0).toStringAsFixed(1)),
    );
  }

  String _generateTitle(String domain) {
    final name = domain.split('.')[0];
    final capitalized = name[0].toUpperCase() + name.substring(1);
    return '$capitalized - Official Website';
  }

  String _randomString(int length, Random random) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
