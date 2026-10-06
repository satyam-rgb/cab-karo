import React, { useState } from 'react';
import { X, ChevronRight, Compass, Search, MapPin, Tag } from 'lucide-react';

interface DestinationExplorerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectDestination: (name: string) => void;
}

export const DestinationExplorerModal: React.FC<DestinationExplorerModalProps> = ({
  isOpen,
  onClose,
  onSelectDestination
}) => {
  const [activeCategory, setActiveCategory] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState<string>('');

  if (!isOpen) return null;

  const destinations = [
    {
      name: 'Nagpur Railway Station',
      subtitle: 'Main railway hub with express & local connectivity',
      icon: '🚆',
      category: 'Transit'
    },
    {
      name: 'Nagpur Airport (NAG)',
      subtitle: 'Dr. Babasaheb Ambedkar International Airport',
      icon: '✈️',
      category: 'Transit'
    },
    {
      name: 'Sitabuldi Fort',
      subtitle: 'Historic hilltop fort and bustling retail hub',
      icon: '🏛️',
      category: 'Heritage'
    },
    {
      name: 'Futala Lake',
      subtitle: 'Waterfront promenade with illuminated fountains & dining',
      icon: '🌊',
      category: 'Leisure'
    },
    {
      name: 'Deekshabhoomi',
      subtitle: 'Sacred architectural monument & Buddhist stupa',
      icon: '🛕',
      category: 'Heritage'
    },
    {
      name: 'VNIT Nagpur',
      subtitle: 'Premier technology & research campus in South Ambazari',
      icon: '🎓',
      category: 'Campus'
    },
    {
      name: 'Dharampeth',
      subtitle: 'Popular commercial, shopping & upscale cafe district',
      icon: '🛍️',
      category: 'Commercial'
    },
    {
      name: 'Ambazari Lake & Garden',
      subtitle: 'Sprawling lake garden and recreation park',
      icon: '🌳',
      category: 'Leisure'
    },
    {
      name: 'MIHAN / IT Park',
      subtitle: 'Major corporate & aerospace hub in South Nagpur',
      icon: '💼',
      category: 'Commercial'
    }
  ];

  const categories = ['All', 'Transit', 'Heritage', 'Leisure', 'Campus', 'Commercial'];

  const filtered = destinations.filter((dest) => {
    const matchesCat = activeCategory === 'All' || dest.category === activeCategory;
    const matchesSearch =
      dest.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      dest.subtitle.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCat && matchesSearch;
  });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
      <div className="flex max-h-[90vh] w-full max-w-lg flex-col rounded-[28px] bg-white shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-150 p-5 bg-white shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600 shadow-xs">
              <Compass className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-lg font-black text-gray-950">
                Destination Explorer
              </h3>
              <p className="text-xs text-gray-500 font-medium">
                Popular Nagpur travel destinations
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-full p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-700 transition"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Search & Category Filter */}
        <div className="p-4 border-b border-gray-100 bg-gray-50/50 space-y-3 shrink-0">
          <div className="relative">
            <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
              <Search className="h-4 w-4" />
            </div>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search airport, station, fort, campus..."
              className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-9 pr-4 text-xs font-semibold text-gray-900 placeholder:text-gray-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
            />
          </div>

          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar">
            {categories.map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => setActiveCategory(cat)}
                className={`shrink-0 rounded-full px-3 py-1 text-xs font-bold transition ${
                  activeCategory === cat
                    ? 'bg-blue-600 text-white shadow-xs'
                    : 'bg-white border border-gray-200 text-gray-600 hover:border-gray-300'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>

        {/* Destination List Content */}
        <div className="flex-1 overflow-y-auto p-4 space-y-2">
          {filtered.length === 0 ? (
            <div className="py-12 text-center text-xs text-gray-400 font-medium">
              No destinations match your filter criteria. Try searching for &quot;Airport&quot; or &quot;Station&quot;.
            </div>
          ) : (
            filtered.map((item) => (
              <div
                key={item.name}
                onClick={() => {
                  onSelectDestination(item.name);
                  onClose();
                }}
                className="group flex items-center justify-between rounded-2xl border border-gray-200/80 bg-white p-3.5 hover:border-blue-400 hover:bg-blue-50/30 transition cursor-pointer shadow-2xs"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-gray-100/80 text-2xl group-hover:scale-105 transition">
                    {item.icon}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-extrabold text-gray-950 group-hover:text-blue-600 transition">
                        {item.name}
                      </span>
                      <span className="rounded-md bg-gray-100 px-1.5 py-0.5 text-[9px] font-bold text-gray-600 uppercase">
                        {item.category}
                      </span>
                    </div>
                    <div className="text-xs text-gray-500 font-medium mt-0.5">
                      {item.subtitle}
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-1 text-xs font-bold text-blue-600 opacity-0 group-hover:opacity-100 transition">
                  <span className="hidden sm:inline">Compare</span>
                  <ChevronRight className="h-4 w-4" />
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
