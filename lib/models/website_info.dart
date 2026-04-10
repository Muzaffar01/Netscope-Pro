class WebsiteInfo {
  final DomainInfo? domainInfo;
  final ServerInfo? serverInfo;
  final List<DnsRecord> dnsRecords;
  final WhoisInfo? whoisInfo;
  final TracerouteResult? traceroute;
  final double? pingMs;

  WebsiteInfo({
    this.domainInfo,
    this.serverInfo,
    this.dnsRecords = const [],
    this.whoisInfo,
    this.traceroute,
    this.pingMs,
  });

  factory WebsiteInfo.fromJson(Map<String, dynamic> json) {
    return WebsiteInfo(
      domainInfo: json['domain_info'] != null
          ? DomainInfo.fromJson(json['domain_info'])
          : null,
      serverInfo: json['server_info'] != null
          ? ServerInfo.fromJson(json['server_info'])
          : null,
      dnsRecords: (json['dns_records'] as List<dynamic>?)
              ?.map((e) => DnsRecord.fromJson(e))
              .toList() ??
          [],
      whoisInfo: json['whois_info'] != null
          ? WhoisInfo.fromJson(json['whois_info'])
          : null,
      traceroute: json['traceroute'] != null
          ? TracerouteResult.fromJson(json['traceroute'])
          : null,
      pingMs: (json['ping_ms'] as num?)?.toDouble(),
    );
  }
}

class DomainInfo {
  final String? title;
  final String? description;
  final List<String> keywords;
  final String? favicon;
  final String? url;

  DomainInfo({
    this.title,
    this.description,
    this.keywords = const [],
    this.favicon,
    this.url,
  });

  factory DomainInfo.fromJson(Map<String, dynamic> json) {
    return DomainInfo(
      title: json['title'],
      description: json['description'],
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      favicon: json['favicon'],
      url: json['url'],
    );
  }
}

class ServerInfo {
  final String? ip;
  final String? hostname;
  final String? serverType;
  final String? hostingProvider;
  final String? city;
  final String? country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final String? org;
  final String? isp;

  ServerInfo({
    this.ip,
    this.hostname,
    this.serverType,
    this.hostingProvider,
    this.city,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.org,
    this.isp,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      ip: json['ip'],
      hostname: json['hostname'],
      serverType: json['server_type'],
      hostingProvider: json['hosting_provider'],
      city: json['city'],
      country: json['country'],
      countryCode: json['country_code'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      org: json['org'],
      isp: json['isp'],
    );
  }
}

class DnsRecord {
  final String type;
  final String name;
  final String value;
  final int? ttl;
  final int? priority;

  DnsRecord({
    required this.type,
    required this.name,
    required this.value,
    this.ttl,
    this.priority,
  });

  factory DnsRecord.fromJson(Map<String, dynamic> json) {
    return DnsRecord(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      ttl: json['ttl'],
      priority: json['priority'],
    );
  }
}

class WhoisInfo {
  final String? registrar;
  final String? creationDate;
  final String? expirationDate;
  final String? updatedDate;
  final String? nameServers;
  final String? status;
  final String? registrantOrg;
  final String? registrantCountry;
  final String? rawData;

  WhoisInfo({
    this.registrar,
    this.creationDate,
    this.expirationDate,
    this.updatedDate,
    this.nameServers,
    this.status,
    this.registrantOrg,
    this.registrantCountry,
    this.rawData,
  });

  factory WhoisInfo.fromJson(Map<String, dynamic> json) {
    return WhoisInfo(
      registrar: json['registrar'],
      creationDate: json['creation_date'],
      expirationDate: json['expiration_date'],
      updatedDate: json['updated_date'],
      nameServers: json['name_servers'],
      status: json['status'],
      registrantOrg: json['registrant_org'],
      registrantCountry: json['registrant_country'],
      rawData: json['raw_data'],
    );
  }
}

class TracerouteResult {
  final String destination;
  final String destinationIp;
  final List<TracerouteHop> hops;

  TracerouteResult({
    required this.destination,
    required this.destinationIp,
    required this.hops,
  });

  factory TracerouteResult.fromJson(Map<String, dynamic> json) {
    return TracerouteResult(
      destination: json['destination'] ?? '',
      destinationIp: json['destination_ip'] ?? '',
      hops: (json['hops'] as List<dynamic>?)
              ?.map((e) => TracerouteHop.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TracerouteHop {
  final int hop;
  final String? ip;
  final String? hostname;
  final double? latency;
  final String? city;
  final String? country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final bool isTimeout;

  TracerouteHop({
    required this.hop,
    this.ip,
    this.hostname,
    this.latency,
    this.city,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.isTimeout = false,
  });

  factory TracerouteHop.fromJson(Map<String, dynamic> json) {
    return TracerouteHop(
      hop: json['hop'] ?? 0,
      ip: json['ip'],
      hostname: json['hostname'],
      latency: (json['latency'] as num?)?.toDouble(),
      city: json['city'],
      country: json['country'],
      countryCode: json['country_code'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isTimeout: json['is_timeout'] ?? false,
    );
  }
}
