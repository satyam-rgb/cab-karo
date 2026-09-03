import express, { json } from 'express';
const app = express();
app.use(json());

// Function to estimate fare based on additional parameters
function calculateFare(baseFare, costPerKm, distance, costPerMinute, timeTaken, surgeMultiplier, traffic, demand, tolls, timeOfDay, route, historicData) {
    // Adjust fare based on traffic conditions
    let trafficMultiplier = 1;
    if (traffic === 'heavy') trafficMultiplier = 1.5;
    else if (traffic === 'moderate') trafficMultiplier = 1.2;

    // Adjust fare based on demand
    let demandMultiplier = 1;
    if (demand === 'high') demandMultiplier = 1.4;
    else if (demand === 'medium') demandMultiplier = 1.2;

    // Adjust fare based on time of day
    let timeOfDayMultiplier = 1;
    if (timeOfDay === 'night') timeOfDayMultiplier = 1.3;

    // Base fare calculation
    let fare = (baseFare + (costPerKm * distance) + (costPerMinute * timeTaken)) * surgeMultiplier;

    // Apply multipliers
    fare *= trafficMultiplier;
    fare *= demandMultiplier;
    fare *= timeOfDayMultiplier;

    // Add tolls and fees
    fare += tolls;

    // Adjust fare based on historic data (simplified example)
    if (historicData === 'high_demand_area') fare *= 1.2;

    return fare;
}

// Pricing models for Uber and Ola (simplified for example)
const pricingModels = {
    uberCab: {
        baseFare: 50,
        costPerKm: 12,
        costPerMinute: 1.2,
        surgeMultiplier: 1.5 // For peak hours
    },
    uberAuto: {
        baseFare: 30,
        costPerKm: 8,
        costPerMinute: 1,
        surgeMultiplier: 1.3 // For peak hours
    },
    olaCab: {
        baseFare: 40,
        costPerKm: 10,
        costPerMinute: 1.5,
        surgeMultiplier: 1.2 // For peak hours
    },
    olaAuto: {
        baseFare: 25,
        costPerKm: 7,
        costPerMinute: 0.8,
        surgeMultiplier: 1.1 // For peak hours
    }
};

// Default route
app.get('/', (req, res) => {
    res.send('API is Working');
});

// Endpoint to compare Uber and Ola fares
app.post('/estimate', (req, res) => {
    const { distance, timeTaken, traffic, demand, tolls, timeOfDay, route, historicData } = req.body;

    if (!distance || !timeTaken || !traffic || !demand || !tolls || !timeOfDay || !route || !historicData) {
        return res.status(400).json({ error: 'Please provide all required parameters.' });
    }

    // Calculate fares
    const uberCabFare = calculateFare(
        pricingModels.uberCab.baseFare,
        pricingModels.uberCab.costPerKm,
        distance,
        pricingModels.uberCab.costPerMinute,
        timeTaken,
        pricingModels.uberCab.surgeMultiplier,
        traffic,
        demand,
        tolls,
        timeOfDay,
        route,
        historicData
    );

    const uberAutoFare = calculateFare(
        pricingModels.uberAuto.baseFare,
        pricingModels.uberAuto.costPerKm,
        distance,
        pricingModels.uberAuto.costPerMinute,
        timeTaken,
        pricingModels.uberAuto.surgeMultiplier,
        traffic,
        demand,
        tolls,
        timeOfDay,
        route,
        historicData
    );

    const olaCabFare = calculateFare(
        pricingModels.olaCab.baseFare,
        pricingModels.olaCab.costPerKm,
        distance,
        pricingModels.olaCab.costPerMinute,
        timeTaken,
        pricingModels.olaCab.surgeMultiplier,
        traffic,
        demand,
        tolls,
        timeOfDay,
        route,
        historicData
    );

    const olaAutoFare = calculateFare(
        pricingModels.olaAuto.baseFare,
        pricingModels.olaAuto.costPerKm,
        distance,
        pricingModels.olaAuto.costPerMinute,
        timeTaken,
        pricingModels.olaAuto.surgeMultiplier,
        traffic,
        demand,
        tolls,
        timeOfDay,
        route,
        historicData
    );

    // Return fare comparison
    return res.json({
        uberCabFare: uberCabFare.toFixed(2),
        uberAutoFare: uberAutoFare.toFixed(2),
        olaCabFare: olaCabFare.toFixed(2),
        olaAutoFare: olaAutoFare.toFixed(2),
    });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});