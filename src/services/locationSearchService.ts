import { LocationCoordinate, LocationPlaceType, LocationSearchResult } from '../types';
import nagpurPlaces from '../../shared/data/local_places/city/nagpur.json';
import punePlaces from '../../shared/data/local_places/city/pune.json';
import mumbaiPlaces from '../../shared/data/local_places/city/mumbai.json';

export interface MapBounds {
  north: number;
  south: number;
  east: number;
  west: number;
}

export interface LocationSearchOptions {
  mapCenter?: LocationCoordinate;
  mapBounds?: MapBounds;
  selectedCity?: string;
  limit?: number;
}

interface CityInfo {
  name: string;
  state: string;
  lat: number;
  lon: number;
  radiusKm: number;
}

export const CITIES_CONFIG: Record<string, CityInfo> = {
  nagpur: { name: 'Nagpur', state: 'Maharashtra', lat: 21.1458, lon: 79.0882, radiusKm: 45 },
  pune: { name: 'Pune', state: 'Maharashtra', lat: 18.5204, lon: 73.8567, radiusKm: 55 },
  mumbai: { name: 'Mumbai', state: 'Maharashtra', lat: 19.076, lon: 72.8777, radiusKm: 65 },
  delhi: { name: 'Delhi', state: 'Delhi', lat: 28.6139, lon: 77.209, radiusKm: 60 },
  jaipur: { name: 'Jaipur', state: 'Rajasthan', lat: 26.9124, lon: 75.7873, radiusKm: 50 },
  bengaluru: { name: 'Bengaluru', state: 'Karnataka', lat: 12.9716, lon: 77.5946, radiusKm: 55 },
  hyderabad: { name: 'Hyderabad', state: 'Telangana', lat: 17.385, lon: 78.4867, radiusKm: 55 },
  chennai: { name: 'Chennai', state: 'Tamil Nadu', lat: 13.0827, lon: 80.2707, radiusKm: 50 },
  kolkata: { name: 'Kolkata', state: 'West Bengal', lat: 22.5726, lon: 88.3639, radiusKm: 50 },
  ahmedabad: { name: 'Ahmedabad', state: 'Gujarat', lat: 23.0225, lon: 72.5714, radiusKm: 50 },
  lucknow: { name: 'Lucknow', state: 'Uttar Pradesh', lat: 26.8467, lon: 80.9462, radiusKm: 45 },
  indore: { name: 'Indore', state: 'Madhya Pradesh', lat: 22.7196, lon: 75.8577, radiusKm: 45 },
  bhopal: { name: 'Bhopal', state: 'Madhya Pradesh', lat: 23.2599, lon: 77.4126, radiusKm: 45 }
};

// Major verified Postal PIN codes in India (especially Nagpur & Maharashtra)
const PIN_CODE_DATABASE: Record<
  string,
  { name: string; locality: string; city: string; state: string; lat: number; lon: number }
> = {
  '440001': {
    name: '440001 — Civil Lines / Sadar / Sitabuldi',
    locality: 'Civil Lines, Sadar',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.153,
    lon: 79.075
  },
  '440002': {
    name: '440002 — Shantinagar / Itwari / Gandhibagh',
    locality: 'Shantinagar, Itwari, Gandhibagh',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.1591,
    lon: 79.1263
  },
  '440003': {
    name: '440003 — Pachpaoli / Bezonbagh',
    locality: 'Pachpaoli, Bezonbagh',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.168,
    lon: 79.105
  },
  '440004': {
    name: '440004 — Mahal / Ayachit Mandir',
    locality: 'Mahal, Kotwali',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.144,
    lon: 79.112
  },
  '440008': {
    name: '440008 — Medical College / Hanuman Nagar',
    locality: 'Hanuman Nagar, Medical Square',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.127,
    lon: 79.098
  },
  '440009': {
    name: '440009 — Sakkardara / Ayodhya Nagar',
    locality: 'Sakkardara, Ayodhya Nagar',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.12,
    lon: 79.115
  },
  '440010': {
    name: '440010 — Dharampeth / Ramdaspeth / Bajaj Nagar',
    locality: 'Dharampeth, Ramdaspeth',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.1415,
    lon: 79.0611
  },
  '440012': {
    name: '440012 — Sitabuldi / Cotton Market',
    locality: 'Sitabuldi Central',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.1466,
    lon: 79.0832
  },
  '440013': {
    name: '440013 — Katol Road / KT Nagar / Friends Colony',
    locality: 'Katol Road',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.175,
    lon: 79.055
  },
  '440014': {
    name: '440014 — Gokulpeth / Ravi Nagar',
    locality: 'Gokulpeth, Ravi Nagar',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.145,
    lon: 79.048
  },
  '440015': {
    name: '440015 — Khamla / Pratap Nagar / Swavalambi Nagar',
    locality: 'Pratap Nagar, Khamla',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.115,
    lon: 79.06
  },
  '440020': {
    name: '440020 — Trimurti Nagar / Subhash Nagar',
    locality: 'Trimurti Nagar',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.112,
    lon: 79.045
  },
  '440022': {
    name: '440022 — Manish Nagar / Besa / Somalwada',
    locality: 'Manish Nagar, Besa',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.085,
    lon: 79.075
  },
  '440024': {
    name: '440024 — Nandanvan / Hasanbagh',
    locality: 'Nandanvan, Hasanbagh',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.135,
    lon: 79.135
  },
  '440025': {
    name: '440025 — MIHAN / Wardha Road / SEZ',
    locality: 'MIHAN, Wardha Road',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.05,
    lon: 79.04
  },
  '440030': {
    name: '440030 — MIDC Hingna / Wanadongri',
    locality: 'Hingna Road, MIDC',
    city: 'Nagpur',
    state: 'Maharashtra',
    lat: 21.095,
    lon: 79.005
  },
  '411001': {
    name: '411001 — Pune Station / Camp / Sassoon',
    locality: 'Pune Camp, Station',
    city: 'Pune',
    state: 'Maharashtra',
    lat: 18.5284,
    lon: 73.8744
  },
  '411004': {
    name: '411004 — Deccan Gymkhana / FC Road',
    locality: 'Deccan Gymkhana',
    city: 'Pune',
    state: 'Maharashtra',
    lat: 18.5236,
    lon: 73.8398
  },
  '411005': {
    name: '411005 — Shivaji Nagar / Model Colony',
    locality: 'Shivaji Nagar',
    city: 'Pune',
    state: 'Maharashtra',
    lat: 18.5314,
    lon: 73.8446
  },
  '400001': {
    name: '400001 — Fort / CST / Colaba',
    locality: 'Fort, CST',
    city: 'Mumbai',
    state: 'Maharashtra',
    lat: 18.94,
    lon: 72.8354
  },
  '400051': {
    name: '400051 — Bandra Kurla Complex (BKC)',
    locality: 'Bandra East, BKC',
    city: 'Mumbai',
    state: 'Maharashtra',
    lat: 19.066,
    lon: 72.8687
  }
};

export function haversineDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export function detectCityContext(query: string, options?: LocationSearchOptions): { city: CityInfo; hasExplicitCity: boolean } {
  const q = query.toLowerCase();
  for (const [key, ctx] of Object.entries(CITIES_CONFIG)) {
    const regex = new RegExp(`\\b${key}\\b`, 'i');
    if (regex.test(q)) {
      return { city: ctx, hasExplicitCity: true };
    }
  }

  if (options?.selectedCity && CITIES_CONFIG[options.selectedCity.toLowerCase()]) {
    return { city: CITIES_CONFIG[options.selectedCity.toLowerCase()], hasExplicitCity: false };
  }

  if (options?.mapCenter) {
    let nearestCity = CITIES_CONFIG.nagpur;
    let shortestDist = Infinity;
    for (const ctx of Object.values(CITIES_CONFIG)) {
      const d = haversineDistanceKm(options.mapCenter.latitude, options.mapCenter.longitude, ctx.lat, ctx.lon);
      if (d < shortestDist) {
        shortestDist = d;
        nearestCity = ctx;
      }
    }
    if (shortestDist < 100) {
      return { city: nearestCity, hasExplicitCity: false };
    }
  }

  return { city: CITIES_CONFIG.nagpur, hasExplicitCity: false };
}

/**
 * Intelligent phonetic and speech/typo expansion for Indian names and places
 */
export function expandQueryVariants(rawQuery: string, city: CityInfo): string[] {
  const cleaned = rawQuery.trim().replace(/\s+/g, ' ');
  const variants: string[] = [cleaned];

  // Common Indian typo / speech-to-text corrections
  let corrected = cleaned
    .replace(/\blodishmukh\b/gi, 'Deshmukh')
    .replace(/\bdeshmuk\b/gi, 'Deshmukh')
    .replace(/\bshantinagr\b/gi, 'Shantinagar')
    .replace(/\bshanti\s+nagar\b/gi, 'Shantinagar')
    .replace(/\bmarwarivadi\b/gi, 'Marwadi')
    .replace(/\bmarwady\b/gi, 'Marwadi')
    .replace(/\bmudliha\s*(?:sq|sq\.|chwk|chowk)\b/gi, 'Mudliha Square')
    .replace(/\bmudliya\b/gi, 'Mudliha')
    .replace(/\bmudliar\b/gi, 'Mudliha')
    .replace(/\bitwri\b/gi, 'Itwari')
    .replace(/\brly\s*(?:stn|station)\b/gi, 'Railway Station')
    .replace(/\bstn\b/gi, 'Station')
    .replace(/\bhosp\b/gi, 'Hospital')
    .replace(/\bhighschool\b/gi, 'High School')
    .replace(/\bvadi\b/gi, 'wadi')
    .trim();

  if (corrected.toLowerCase() !== cleaned.toLowerCase()) {
    variants.push(corrected);
  }

  // Strip house/flat/plot numbers and PIN codes
  const strippedNumber = corrected
    .replace(/(?:plot|no|house|flat|ward|block|room|shop|h\.no|p\.no)\s*[:#.]?\s*\w+/gi, '')
    .replace(/\b\d{1,6}\b/g, '')
    .replace(/,(\s*,)+/g, ',')
    .replace(/^[\s,]+|[\s,]+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();

  if (strippedNumber && strippedNumber.toLowerCase() !== corrected.toLowerCase()) {
    variants.push(strippedNumber);
  }

  // Primary locality / segment
  const parts = corrected.split(',').map((p) => p.trim()).filter(Boolean);
  if (parts.length > 1) {
    variants.push(parts[0]);
  }

  // Suffix with city if not already explicit
  const lower = corrected.toLowerCase();
  const hasCityExplicit = lower.includes(city.name.toLowerCase());
  const citySuffix = hasCityExplicit ? '' : `, ${city.name}`;

  const expandedList: string[] = [];
  for (const v of variants) {
    expandedList.push(v);
    if (!hasCityExplicit) {
      expandedList.push(`${v}${citySuffix}`);
    }
  }

  return Array.from(new Set(expandedList)).filter((q) => q.length > 1);
}

/**
 * Determine high-level category & place type from tags / properties
 */
export function determinePlaceType(
  tags: Record<string, any>,
  name: string = ''
): { type: LocationPlaceType; category: string } {
  const n = name.toLowerCase();
  const amenity = (tags.amenity || tags.type || '').toLowerCase();
  const place = (tags.place || '').toLowerCase();
  const highway = (tags.highway || '').toLowerCase();
  const building = (tags.building || '').toLowerCase();

  if (amenity === 'school' || building === 'school' || n.includes('school') || n.includes('vidyalaya') || n.includes('shikshan')) {
    return { type: 'school', category: 'School' };
  }
  if (amenity === 'college' || amenity === 'university' || n.includes('college') || n.includes('university')) {
    return { type: 'college', category: 'College / University' };
  }
  if (amenity === 'hospital' || amenity === 'clinic' || tags.healthcare === 'hospital' || n.includes('hospital') || n.includes('clinic')) {
    return { type: 'hospital', category: 'Hospital / Clinic' };
  }
  if (n.includes('institute') || n.includes('classes') || n.includes('coaching') || n.includes('academy')) {
    return { type: 'institute', category: 'Educational Institute' };
  }
  if (n.includes('square') || n.includes('chowk') || tags.junction === 'roundabout') {
    return { type: 'square', category: 'Square / Chowk' };
  }
  if (tags.railway === 'station' || n.includes('railway station') || n.includes('rly stn')) {
    return { type: 'railway_station', category: 'Railway Station' };
  }
  if (tags.aeroway === 'aerodrome' || n.includes('airport') || n.includes('aerodrome')) {
    return { type: 'airport', category: 'Airport' };
  }
  if (place === 'suburb' || place === 'neighbourhood' || place === 'quarter' || place === 'residential') {
    return { type: 'neighbourhood', category: 'Neighbourhood' };
  }
  if (place === 'locality' || place === 'village' || place === 'town' || place === 'city') {
    return { type: 'locality', category: 'Locality' };
  }
  if (highway || n.includes('road') || n.includes('marg') || n.includes('street') || n.includes('galli')) {
    return { type: 'road', category: 'Road / Street' };
  }
  if (amenity === 'marketplace' || tags.shop || n.includes('market') || n.includes('bazaar') || n.includes('mall')) {
    return { type: 'business', category: 'Market / Commercial' };
  }

  return { type: 'poi', category: 'Point of Interest' };
}

// Memory caches
const searchMemoryCache = new Map<string, LocationSearchResult[]>();
const allGazetteers: LocationSearchResult[] = [
  ...(nagpurPlaces as any[]),
  ...(punePlaces as any[]),
  ...(mumbaiPlaces as any[])
];

// =========================================================================
// PROVIDER 1: VERIFIED LOCAL GAZETTEER CACHE PROVIDER
// =========================================================================
class LocalGazetteerProvider {
  search(query: string, _city: CityInfo): LocationSearchResult[] {
    const qLower = query.toLowerCase().trim();
    if (!qLower || qLower.length < 2) return [];

    const tokens = qLower.split(/[^a-z0-9]+/).filter((t) => t.length > 2);
    const results: LocationSearchResult[] = [];

    for (const place of allGazetteers) {
      const pName = place.name.toLowerCase();
      const aliases = ((place as any).aliases || []).map((a: string) => a.toLowerCase());

      let match = false;
      let conf = place.confidence || 0.95;

      // Exact or alias match
      if (pName === qLower || aliases.includes(qLower)) {
        match = true;
        conf = 0.99;
      } else if (pName.includes(qLower) || aliases.some((a: string) => a.includes(qLower))) {
        match = true;
        conf = 0.96;
      } else if (tokens.length > 0 && tokens.every((t) => pName.includes(t) || aliases.some((a: string) => a.includes(t)))) {
        match = true;
        conf = 0.92;
      } else if (tokens.length > 1) {
        const matchesCount = tokens.filter((t) => pName.includes(t) || aliases.some((a: string) => a.includes(t))).length;
        if (matchesCount >= Math.ceil(tokens.length * 0.6)) {
          match = true;
          conf = 0.88;
        }
      }

      if (match) {
        results.push({
          ...place,
          confidence: conf
        });
      }
    }

    return results;
  }
}

// =========================================================================
// PROVIDER 2: INDIAN POSTAL CODE / PIN RESOLVER
// =========================================================================
class PostalAreaProvider {
  search(query: string, _city: CityInfo): LocationSearchResult[] {
    const pinMatch = query.match(/\b([1-9][0-9]{5})\b/);
    if (!pinMatch) return [];

    const pin = pinMatch[1];
    const postal = PIN_CODE_DATABASE[pin];
    if (!postal) {
      // General recognized format
      return [];
    }

    return [
      {
        id: `pin-${pin}`,
        name: postal.name,
        displayName: `${postal.name}, ${postal.city}, ${postal.state}`,
        latitude: postal.lat,
        longitude: postal.lon,
        type: 'postal_area',
        category: 'Postal Area / PIN Code',
        locality: postal.locality,
        city: postal.city,
        state: postal.state,
        postalCode: pin,
        source: 'postal_service',
        confidence: 0.98
      }
    ];
  }
}

// =========================================================================
// PROVIDER 3: NOMINATIM / OPENSTREETMAP PROVIDER
// =========================================================================
class NominatimProvider {
  async search(query: string, _city: CityInfo, _options?: LocationSearchOptions): Promise<LocationSearchResult[]> {
    const results: LocationSearchResult[] = [];
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3500);

      const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
        query
      )}&limit=6&addressdetails=1`;

      const res = await fetch(url, {
        signal: controller.signal,
        headers: { 'Accept-Language': 'en' }
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        const list = await res.json();
        for (const item of list) {
          const lat = parseFloat(item.lat);
          const lon = parseFloat(item.lon);
          if (isNaN(lat) || isNaN(lon)) continue;

          const addr = item.address || {};
          const rawName = item.name || item.display_name.split(',')[0] || query;
          const { type, category } = determinePlaceType(
            { ...addr, type: item.type, class: item.class },
            rawName
          );

          results.push({
            id: `nom-${item.osm_type || 'p'}-${item.osm_id || Math.random()}`,
            name: rawName,
            displayName: item.display_name,
            latitude: lat,
            longitude: lon,
            type,
            category,
            locality: addr.suburb || addr.neighbourhood || addr.residential || addr.road,
            city: addr.city || addr.town || addr.village || addr.municipality || addr.county || addr.state_district,
            district: addr.state_district || addr.county,
            state: addr.state || addr.country,
            postalCode: addr.postcode,
            source: 'nominatim',
            confidence: 0.92
          });
        }
      }
    } catch (_e) {
      // Graceful timeout
    }
    return results;
  }
}

// =========================================================================
// PROVIDER 4: PHOTON (KOMOOT POI & GEOCODER API)
// =========================================================================
class PhotonProvider {
  async search(query: string, _city: CityInfo, _options?: LocationSearchOptions): Promise<LocationSearchResult[]> {
    const results: LocationSearchResult[] = [];
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3200);

      const url = `https://photon.komoot.io/api/?q=${encodeURIComponent(query)}&limit=6`;

      const res = await fetch(url, { signal: controller.signal });
      clearTimeout(timeoutId);

      if (res.ok) {
        const data = await res.json();
        if (data && data.features) {
          for (const f of data.features) {
            const [lon, lat] = f.geometry?.coordinates || [];
            if (typeof lat !== 'number' || typeof lon !== 'number') continue;

            const p = f.properties || {};
            const rawName = p.name || query;
            const { type, category } = determinePlaceType(
              { type: p.osm_type, key: p.osm_key, value: p.osm_value },
              rawName
            );

            const resolvedCity = p.city || p.town || p.county || p.district;
            const resolvedState = p.state || p.country;

            const display = [
              rawName,
              p.street,
              p.district || p.suburb,
              resolvedCity,
              resolvedState,
              p.country && p.country !== resolvedState ? p.country : undefined
            ]
              .filter(Boolean)
              .join(', ');

            results.push({
              id: `pho-${p.osm_type || 'p'}-${p.osm_id || Math.random()}`,
              name: rawName,
              displayName: display || rawName,
              latitude: lat,
              longitude: lon,
              type,
              category: p.osm_value ? `${p.osm_value.charAt(0).toUpperCase() + p.osm_value.slice(1)}` : category,
              locality: p.district || p.suburb || p.street,
              city: resolvedCity,
              state: resolvedState,
              postalCode: p.postcode,
              source: 'photon',
              confidence: 0.9
            });
          }
        }
      }
    } catch (_e) {
      // Graceful timeout
    }
    return results;
  }
}

// =========================================================================
// PROVIDER 5: OVERPASS OPENSTREETMAP LOCAL POI SEARCH
// =========================================================================
class OverpassPOIProvider {
  async search(query: string, city: CityInfo, options?: LocationSearchOptions): Promise<LocationSearchResult[]> {
    const clean = query.trim();
    if (clean.length < 3) return [];

    const results: LocationSearchResult[] = [];
    const center = options?.mapCenter || { latitude: city.lat, longitude: city.lon };
    const radius = 12000; // 12km search radius around map center / city

    // Check if query is category-based (e.g. "school", "hospital", "college") or specific place name
    const qLower = clean.toLowerCase();
    const isCategorySearch =
      qLower === 'school' ||
      qLower === 'local school' ||
      qLower === 'college' ||
      qLower === 'local college' ||
      qLower === 'hospital' ||
      qLower === 'clinic' ||
      qLower === 'market';

    let overpassFilter = '';
    if (isCategorySearch) {
      const tag = qLower.includes('school')
        ? 'amenity=school'
        : qLower.includes('college')
        ? 'amenity=college'
        : qLower.includes('hospital')
        ? 'amenity=hospital'
        : 'amenity=marketplace';
      overpassFilter = `node["${tag}"](around:${radius}, ${center.latitude}, ${center.longitude});
        way["${tag}"](around:${radius}, ${center.latitude}, ${center.longitude});`;
    } else {
      // Escape for Overpass regex
      const safeQuery = clean.replace(/([.*+?^${}()|[\]/\\])/g, '\\$1');
      overpassFilter = `
        node[~"^(amenity|school|college|hospital|place|shop|leisure|building)$"~"."][~"^(name|name:en|name:hi|name:mr|official_name|alt_name|short_name)$"~"${safeQuery}",i](around:${radius}, ${center.latitude}, ${center.longitude});
        way[~"^(amenity|school|college|hospital|place|shop|leisure|building)$"~"."][~"^(name|name:en|name:hi|name:mr|official_name|alt_name|short_name)$"~"${safeQuery}",i](around:${radius}, ${center.latitude}, ${center.longitude});
      `;
    }

    const overpassQL = `[out:json][timeout:3];(${overpassFilter});out center 6;`;

    const endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://lz4.overpass-api.de/api/interpreter'
    ];

    for (const endpoint of endpoints) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 3200);

        const res = await fetch(endpoint + '?data=' + encodeURIComponent(overpassQL), {
          signal: controller.signal
        });
        clearTimeout(timeoutId);

        if (res.ok) {
          const data = await res.json();
          if (data && data.elements) {
            for (const el of data.elements) {
              const lat = el.lat || el.center?.lat;
              const lon = el.lon || el.center?.lon;
              if (typeof lat !== 'number' || typeof lon !== 'number') continue;

              const tags = el.tags || {};
              const name = tags.name || tags['name:en'] || tags['name:mr'] || tags.official_name || clean;
              const { type, category } = determinePlaceType(tags, name);

              results.push({
                id: `ovp-${el.type}-${el.id}`,
                name,
                displayName: `${name}, ${tags['addr:suburb'] || tags['addr:street'] || city.name}`,
                latitude: lat,
                longitude: lon,
                type,
                category,
                locality: tags['addr:suburb'] || tags['addr:street'] || tags['addr:neighbourhood'],
                city: tags['addr:city'] || city.name,
                state: tags['addr:state'] || city.state,
                postalCode: tags['addr:postcode'],
                source: 'overpass',
                confidence: 0.94
              });
            }
          }
          if (results.length > 0) break;
        }
      } catch (_e) {
        // Try next endpoint or finish
      }
    }

    return results;
  }
}

// =========================================================================
// PROVIDER 6: GOOGLE PLACES API (OPTIONAL HIGH-COVERAGE POI PROVIDER)
// =========================================================================
class GooglePlacesProvider {
  private apiKey: string | null = null;

  constructor() {
    // Read optional client or server key
    try {
      this.apiKey =
        (typeof import.meta !== 'undefined' && (import.meta as any).env?.VITE_GOOGLE_PLACES_API_KEY) ||
        null;
    } catch {
      this.apiKey = null;
    }
  }

  isConfigured(): boolean {
    return Boolean(this.apiKey && this.apiKey.length > 5);
  }

  async search(query: string, city: CityInfo, options?: LocationSearchOptions): Promise<LocationSearchResult[]> {
    if (!this.isConfigured()) return [];

    const results: LocationSearchResult[] = [];
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3500);

      const center = options?.mapCenter || { latitude: city.lat, longitude: city.lon };

      const body = {
        textQuery: query.includes(city.name) ? query : `${query}, ${city.name}`,
        locationBias: {
          circle: {
            center: { latitude: center.latitude, longitude: center.longitude },
            radius: 15000.0
          }
        },
        maxResultCount: 6
      };

      const res = await fetch('https://places.googleapis.com/v1/places:searchText', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': this.apiKey!,
          'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress,places.location,places.types'
        },
        body: JSON.stringify(body),
        signal: controller.signal
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        const data = await res.json();
        if (data && data.places) {
          for (const p of data.places) {
            const lat = p.location?.latitude;
            const lon = p.location?.longitude;
            if (typeof lat !== 'number' || typeof lon !== 'number') continue;

            const name = p.displayName?.text || query;
            const primaryType = (p.types && p.types[0]) || '';
            const { type, category } = determinePlaceType({ type: primaryType }, name);

            results.push({
              id: `gplaces-${p.id}`,
              name,
              displayName: p.formattedAddress || `${name}, ${city.name}`,
              latitude: lat,
              longitude: lon,
              type,
              category,
              city: city.name,
              state: city.state,
              source: 'google_places',
              confidence: 0.98
            });
          }
        }
      }
    } catch (_e) {
      // Graceful fallback
    }

    return results;
  }
}

// =========================================================================
// LOCATION SEARCH AGGREGATOR ENGINE
// =========================================================================
export class LocationSearchAggregator {
  private gazetteer = new LocalGazetteerProvider();
  private postal = new PostalAreaProvider();
  private nominatim = new NominatimProvider();
  private photon = new PhotonProvider();
  private overpass = new OverpassPOIProvider();
  private googlePlaces = new GooglePlacesProvider();

  public isGooglePlacesConfigured(): boolean {
    return this.googlePlaces.isConfigured();
  }

  /**
   * Search multiple data sources concurrently, normalize, deduplicate, and rank results.
   */
  async search(rawQuery: string, options?: LocationSearchOptions): Promise<LocationSearchResult[]> {
    const query = rawQuery.trim();
    if (!query || query.length < 2) return [];

    const cacheKey = `${query.toLowerCase()}_${options?.mapCenter?.latitude?.toFixed(2) || ''}_${
      options?.mapCenter?.longitude?.toFixed(2) || ''
    }`;

    if (searchMemoryCache.has(cacheKey)) {
      return searchMemoryCache.get(cacheKey)!;
    }

    const { city, hasExplicitCity } = detectCityContext(query, options);
    const variants = expandQueryVariants(query, city);

    // 1. Synchronous & Fast Local Checks (Gazetteer & Postal Codes)
    const instantResults: LocationSearchResult[] = [];

    // Check PIN codes
    const postalMatches = this.postal.search(query, city);
    instantResults.push(...postalMatches);

    // Check Local Gazetteer for all variants
    for (const v of variants) {
      const gResults = this.gazetteer.search(v, city);
      instantResults.push(...gResults);
    }

    // 2. Parallel Remote Provider Queries
    const remotePromises: Promise<LocationSearchResult[]>[] = [];

    // Overpass POI search for the primary corrected variant
    const primaryVariant = variants[0] || query;
    remotePromises.push(this.overpass.search(primaryVariant, city, options));

    // Photon search
    remotePromises.push(this.photon.search(primaryVariant, city, options));
    if (hasExplicitCity && variants.length > 1 && variants[1] !== primaryVariant) {
      remotePromises.push(this.photon.search(variants[1], city, options));
    }

    // Nominatim search
    remotePromises.push(this.nominatim.search(primaryVariant, city, options));

    // Optional Google Places
    if (this.googlePlaces.isConfigured()) {
      remotePromises.push(this.googlePlaces.search(primaryVariant, city, options));
    }

    const remoteArrays = await Promise.allSettled(remotePromises);
    const allCollected: LocationSearchResult[] = [...instantResults];

    for (const res of remoteArrays) {
      if (res.status === 'fulfilled' && Array.isArray(res.value)) {
        allCollected.push(...res.value);
      }
    }

    // 3. Deduplication
    const deduplicated = this.deduplicate(allCollected);

    // 4. Ranking
    const ranked = this.rankResults(deduplicated, query, city, hasExplicitCity, options);

    const limit = options?.limit || 7;
    const finalResults = ranked.slice(0, limit);

    searchMemoryCache.set(cacheKey, finalResults);
    return finalResults;
  }

  /**
   * Deduplicate by coordinates vicinity (< 250m) and normalized name tokens
   */
  private deduplicate(items: LocationSearchResult[]): LocationSearchResult[] {
    const deduped: LocationSearchResult[] = [];

    for (const item of items) {
      const existingIdx = deduped.findIndex((existing) => {
        const dist = haversineDistanceKm(item.latitude, item.longitude, existing.latitude, existing.longitude);
        if (dist < 0.25) return true; // Within 250m
        if (dist < 1.0 && this.normalizeName(item.name) === this.normalizeName(existing.name)) return true;
        return false;
      });

      if (existingIdx === -1) {
        deduped.push(item);
      } else {
        // Merge metadata if the new one has a more specific POI type
        const existing = deduped[existingIdx];
        if (existing.type === 'poi' || existing.type === 'address') {
          if (item.type !== 'poi' && item.type !== 'address') {
            deduped[existingIdx] = {
              ...item,
              confidence: Math.max(existing.confidence, item.confidence)
            };
          }
        }
      }
    }

    return deduped;
  }

  private normalizeName(str: string): string {
    return str
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '')
      .trim();
  }

  /**
   * Multi-factor ranking engine
   */
  private rankResults(
    items: LocationSearchResult[],
    query: string,
    city: CityInfo,
    hasExplicitCity: boolean,
    options?: LocationSearchOptions
  ): LocationSearchResult[] {
    const qLower = query.toLowerCase().trim();
    const qTokens = qLower.split(/[^a-z0-9]+/).filter((t) => t.length > 2);
    const center = options?.mapCenter;

    return items
      .map((item) => {
        let score = 0;
        const nameLower = item.name.toLowerCase();
        const dispLower = item.displayName.toLowerCase();

        // 1. Exact name match
        if (nameLower === qLower) {
          score += 50;
        } else if (nameLower.startsWith(qLower)) {
          score += 35;
        } else if (nameLower.includes(qLower) || dispLower.includes(qLower)) {
          score += 22;
        }

        // 2. Query tokens overlap
        if (qTokens.length > 0) {
          const matchedCount = qTokens.filter((t) => nameLower.includes(t) || dispLower.includes(t)).length;
          score += (matchedCount / qTokens.length) * 30;
        }

        // 3. Mild proximity tie-breaker when mapCenter is available (never penalize global results)
        if (center) {
          const distToCenter = haversineDistanceKm(item.latitude, item.longitude, center.latitude, center.longitude);
          if (distToCenter < 10) {
            score += 8;
          } else if (distToCenter < 35) {
            score += 4;
          }
        }

        // 4. Result type specificity bonus
        const highValueTypes: LocationPlaceType[] = [
          'school',
          'college',
          'hospital',
          'square',
          'railway_station',
          'airport',
          'postal_area',
          'institute'
        ];
        if (highValueTypes.includes(item.type)) {
          score += 10;
        }

        // 5. Source confidence
        score += item.confidence * 10;

        // 6. Explicit city alignment bonus only when user explicitly included city name
        if (hasExplicitCity && item.city?.toLowerCase() === city.name.toLowerCase()) {
          score += 15;
        }

        return { item, score };
      })
      .sort((a, b) => b.score - a.score)
      .map((entry) => entry.item);
  }

  /**
   * Geocode a specific location string with the highest-ranked result
   */
  async geocode(query: string, options?: LocationSearchOptions): Promise<LocationSearchResult> {
    const results = await this.search(query, { ...options, limit: 3 });
    if (results.length > 0) {
      return results[0];
    }

    throw new Error(
      `Location not found: "${query}". Please check the spelling or select a location from suggestions.`
    );
  }
}

export const locationSearchService = new LocationSearchAggregator();
