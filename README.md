# KaroCab (React)

KaroCab is a cab price comparison, recommendation, and travel intelligence web application rewritten in React, TypeScript, Vite, and Tailwind CSS from the original Flutter repository.

## Features Preserved & Ported

- **Onboarding Carousel**: 3-step carousel with indicators highlighting cab price comparison, multi-provider transparency, and map integration.
- **Phone Authentication & Profile**: Phone number and OTP verification with persistent session storage.
- **Interactive Map Experience**: Real-time interactive map with pickup/drop-off pins, Nagpur city landmark defaults, geocoding, and OSRM route lines.
- **Cab Comparison & Pricing**:
  - Compares **Uber Cab**, **Uber Auto**, **Ola Cab**, and **Ola Auto**.
  - Dynamic fares based on distance, duration, traffic, demand, and time of day.
- **KaroScore Engine**: Multi-factor scoring evaluating price (40%), ETA (10%), duration (10%), safety (15%), comfort (10%), and reliability (15%).
- **Smart Recommendations**:
  - 🏆 Best Overall
  - 💰 Best Budget
  - ⚡ Fastest
  - 💡 Budget but Not Slowest
  - ⚖️ Balanced Choice
  - Trade-offs analysis (extra cost vs. time saved)
- **ML Fare Prediction**: Linear Regression baseline estimating trend (up/down/stable) and expected fare variance.
- **KaroAI Assistant**: Context-aware ride advisor that analyzes routes, fares, and KaroScore metrics.
- **KaroSafe / Emergency SOS**: Quick SOS dispatch generating coordinates, Google Maps location links, and prepared SMS alert messages.
- **Price Alerts**: Set target fares for specific routes and monitor fare adjustments.
- **Monthly Transport Budget Dashboard**: Track spending, manage completed ride expenses, and compute daily spending guidelines.
- **Destination Explorer**: Quick discovery and one-tap selection of popular city hubs.

## Tech Stack

- **Framework**: React 18, TypeScript, Vite
- **Styling**: Tailwind CSS
- **Maps & Routing**: Leaflet, OpenStreetMap, OSRM (Open Source Routing Machine)
- **Icons**: Lucide React
