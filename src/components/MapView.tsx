import React, { useEffect, useRef } from 'react';
import L from 'leaflet';
import { LocationCoordinate } from '../types';

interface MapViewProps {
  origin?: LocationCoordinate | null;
  destination?: LocationCoordinate | null;
  routeCoordinates?: LocationCoordinate[];
  isLoadingRoute?: boolean;
  routeError?: string | null;
  originLabel?: string;
  destinationLabel?: string;
  onMapClick?: (coord: LocationCoordinate) => void;
}

export const MapView: React.FC<MapViewProps> = ({
  origin,
  destination,
  routeCoordinates = [],
  isLoadingRoute = false,
  routeError = null,
  originLabel,
  destinationLabel
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);
  const routePolylineRef = useRef<L.Polyline | null>(null);

  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      // Default initial view
      const map = L.map(mapContainerRef.current, {
        center: [21.1458, 79.0882],
        zoom: 12,
        zoomControl: false,
        attributionControl: false
      });

      // Add OpenStreetMap tile layer
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19
      }).addTo(map);

      // Add top-right zoom control
      L.control.zoom({ position: 'topright' }).addTo(map);

      const markersLayer = L.layerGroup().addTo(map);
      markersLayerRef.current = markersLayer;
      mapInstanceRef.current = map;
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // Update markers, polyline, and viewport whenever coordinates change
  useEffect(() => {
    const map = mapInstanceRef.current;
    const markersLayer = markersLayerRef.current;
    if (!map || !markersLayer) return;

    // 1. Immediately clear old markers & polyline
    markersLayer.clearLayers();

    if (routePolylineRef.current) {
      routePolylineRef.current.remove();
      routePolylineRef.current = null;
    }

    const boundsLatLngs: L.LatLngExpression[] = [];

    // 2. Add Origin Marker (Green)
    if (origin) {
      const originIcon = L.divIcon({
        className: 'custom-map-icon',
        html: `
          <div style="background-color: #10B981; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 10px rgba(0,0,0,0.3); border: 2.5px solid white;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>
              <circle cx="12" cy="10" r="3"/>
            </svg>
          </div>
        `,
        iconSize: [34, 34],
        iconAnchor: [17, 34],
        popupAnchor: [0, -34]
      });

      const originMarker = L.marker([origin.latitude, origin.longitude], {
        icon: originIcon
      }).bindPopup(`<b>Pickup:</b> ${originLabel || 'From'}`);
      markersLayer.addLayer(originMarker);
      boundsLatLngs.push([origin.latitude, origin.longitude]);
    }

    // 3. Add Destination Marker (Red)
    if (destination) {
      const destIcon = L.divIcon({
        className: 'custom-map-icon',
        html: `
          <div style="background-color: #EF4444; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 10px rgba(0,0,0,0.3); border: 2.5px solid white;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/>
              <line x1="4" x2="4" y1="22" y2="15"/>
            </svg>
          </div>
        `,
        iconSize: [34, 34],
        iconAnchor: [17, 34],
        popupAnchor: [0, -34]
      });

      const destMarker = L.marker([destination.latitude, destination.longitude], {
        icon: destIcon
      }).bindPopup(`<b>Destination:</b> ${destinationLabel || 'To'}`);
      markersLayer.addLayer(destMarker);
      boundsLatLngs.push([destination.latitude, destination.longitude]);
    }

    // Ensure map container dimensions are calibrated
    map.invalidateSize();

    // 4. Draw Route Polyline & Fit Bounds
    if (routeCoordinates && routeCoordinates.length > 0) {
      const latlngs: [number, number][] = routeCoordinates.map((c) => [
        c.latitude,
        c.longitude
      ]);
      const polyline = L.polyline(latlngs, {
        color: '#0262FF',
        weight: 5,
        opacity: 0.85,
        lineCap: 'round',
        lineJoin: 'round'
      }).addTo(map);

      routePolylineRef.current = polyline;
      map.fitBounds(polyline.getBounds(), {
        padding: [60, 60],
        maxZoom: 16,
        animate: true
      });
    } else if (boundsLatLngs.length > 1) {
      map.fitBounds(L.latLngBounds(boundsLatLngs), {
        padding: [60, 60],
        maxZoom: 16,
        animate: true
      });
    } else if (boundsLatLngs.length === 1) {
      map.setView(boundsLatLngs[0], 14, { animate: true });
    }
  }, [origin, destination, routeCoordinates, originLabel, destinationLabel]);

  return (
    <div className="relative w-full h-full min-h-[300px] overflow-hidden rounded-b-2xl shadow-inner bg-slate-100">
      <div ref={mapContainerRef} className="w-full h-full" />

      {/* Floating Status Indicators */}
      {isLoadingRoute && (
        <div className="absolute top-16 left-1/2 -translate-x-1/2 z-30 flex items-center gap-2 rounded-full bg-slate-950/90 backdrop-blur-md px-4 py-2 text-xs font-black text-white shadow-xl border border-slate-700 animate-in fade-in duration-200">
          <div className="h-3.5 w-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
          <span>Calculating route...</span>
        </div>
      )}

      {routeError && !isLoadingRoute && (
        <div className="absolute top-16 left-1/2 -translate-x-1/2 z-30 flex items-center gap-2 rounded-full bg-red-600/90 backdrop-blur-md px-4 py-2 text-xs font-bold text-white shadow-xl animate-in fade-in duration-200">
          <span>⚠️ {routeError}</span>
        </div>
      )}
    </div>
  );
};
