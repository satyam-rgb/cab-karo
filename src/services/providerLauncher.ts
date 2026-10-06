import { LocationCoordinate } from '../types';

export interface ProviderLaunchOptions {
  provider: 'Uber' | 'Ola' | string;
  category?: 'Cab' | 'Auto' | string;
  pickupCoord?: LocationCoordinate | null;
  dropCoord?: LocationCoordinate | null;
  pickupAddress?: string;
  dropAddress?: string;
}

export interface LaunchResult {
  provider: string;
  method: 'universal_link' | 'deep_link' | 'web_fallback';
  url: string;
  platform: 'android' | 'ios' | 'desktop_web';
}

/**
 * Detects client environment to choose between native mobile app intent or web experience
 */
export function detectPlatform(): 'android' | 'ios' | 'desktop_web' {
  if (typeof window === 'undefined' || !navigator) {
    return 'desktop_web';
  }
  const ua = navigator.userAgent || navigator.vendor || (window as unknown as { opera?: string }).opera || '';
  if (/android/i.test(ua)) {
    return 'android';
  }
  if (/iPad|iPhone|iPod/.test(ua) && !(window as unknown as { MSStream?: unknown }).MSStream) {
    return 'ios';
  }
  return 'desktop_web';
}

/**
 * Generates official Uber deep link / universal link with fallback
 */
export function getUberLinks(options: ProviderLaunchOptions) {
  const { pickupCoord, dropCoord, pickupAddress, dropAddress } = options;

  const pLat = pickupCoord ? pickupCoord.latitude : 21.1458;
  const pLng = pickupCoord ? pickupCoord.longitude : 79.0882;
  const dLat = dropCoord ? dropCoord.latitude : 21.0922;
  const dLng = dropCoord ? dropCoord.longitude : 79.0474;

  const pNick = encodeURIComponent(pickupAddress || 'Pickup');
  const dNick = encodeURIComponent(dropAddress || 'Destination');

  // Official Uber Universal Link (Works on iOS, Android, and Web)
  const universalLink = `https://m.uber.com/ul/?action=setPickup&pickup[latitude]=${pLat}&pickup[longitude]=${pLng}&pickup[nickname]=${pNick}&dropoff[latitude]=${dLat}&dropoff[longitude]=${dLng}&dropoff[nickname]=${dNick}`;

  // Native app protocol scheme
  const deepLink = `uber://?action=setPickup&pickup[latitude]=${pLat}&pickup[longitude]=${pLng}&dropoff[latitude]=${dLat}&dropoff[longitude]=${dLng}`;

  // Web desktop fallback
  const webFallback = `https://m.uber.com/looking`;

  return { universalLink, deepLink, webFallback };
}

/**
 * Generates official Ola deep link / universal link with fallback
 */
export function getOlaLinks(options: ProviderLaunchOptions) {
  const { pickupCoord, dropCoord, category } = options;

  const pLat = pickupCoord ? pickupCoord.latitude : 21.1458;
  const pLng = pickupCoord ? pickupCoord.longitude : 79.0882;
  const dLat = dropCoord ? dropCoord.latitude : 21.0922;
  const dLng = dropCoord ? dropCoord.longitude : 79.0474;

  const isAuto = category?.toLowerCase().includes('auto');
  const catParam = isAuto ? '&category=auto' : '&category=prime';

  // Official Ola mobile deep link format
  const deepLink = `olacabs://app/launch?lat=${pLat}&lng=${pLng}&drop_lat=${dLat}&drop_lng=${dLng}${catParam}`;

  // Official Ola booking web fallback
  const webFallback = `https://book.olacabs.com/?pickup_lat=${pLat}&pickup_lng=${pLng}&drop_lat=${dLat}&drop_lng=${dLng}`;

  return { deepLink, webFallback };
}

/**
 * Unified provider launch handler that launches native apps on mobile devices
 * and cleanly falls back to web portals in browser/preview environments.
 */
export function launchProvider(options: ProviderLaunchOptions): LaunchResult {
  const platform = detectPlatform();
  const isMobile = platform === 'android' || platform === 'ios';
  const providerName = options.provider.toLowerCase();

  if (providerName.includes('uber')) {
    const { universalLink, deepLink, webFallback } = getUberLinks(options);

    if (isMobile) {
      // In mobile apps / Cordova / Capacitor / PWA:
      // Try universal link first, with app intent fallback
      window.location.href = universalLink;
      return {
        provider: 'Uber',
        method: 'universal_link',
        url: universalLink,
        platform
      };
    } else {
      // In web desktop preview: open official web booking
      window.open(webFallback, '_blank', 'noopener,noreferrer');
      return {
        provider: 'Uber',
        method: 'web_fallback',
        url: webFallback,
        platform
      };
    }
  }

  if (providerName.includes('ola')) {
    const { deepLink, webFallback } = getOlaLinks(options);

    if (isMobile) {
      // On mobile, trigger custom scheme with fallback timeout
      const start = Date.now();
      window.location.href = deepLink;

      setTimeout(() => {
        if (Date.now() - start < 1500) {
          // App not installed, navigate to web fallback
          window.location.href = webFallback;
        }
      }, 800);

      return {
        provider: 'Ola',
        method: 'deep_link',
        url: deepLink,
        platform
      };
    } else {
      // Web desktop preview: open official web booking
      window.open(webFallback, '_blank', 'noopener,noreferrer');
      return {
        provider: 'Ola',
        method: 'web_fallback',
        url: webFallback,
        platform
      };
    }
  }

  // Generic fallback
  const genericFallback = `https://www.google.com/search?q=${encodeURIComponent(options.provider + ' cab booking')}`;
  window.open(genericFallback, '_blank', 'noopener,noreferrer');
  return {
    provider: options.provider,
    method: 'web_fallback',
    url: genericFallback,
    platform
  };
}
