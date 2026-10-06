import React, { useState } from 'react';
import { ArrowRight, ChevronRight } from 'lucide-react';

interface OnboardingScreenProps {
  onComplete: () => void;
}

export const OnboardingScreen: React.FC<OnboardingScreenProps> = ({ onComplete }) => {
  const [currentSlide, setCurrentSlide] = useState(0);

  const slides = [
    {
      image: '/assets/images/cab1.jpg',
      title: 'Compare Prices of Cabs',
      description: 'Provides you with the best prices for your cab rides in town'
    },
    {
      image: '/assets/images/cab2.jpg',
      title: 'Seamless Comparisons',
      description: 'Compare prices of cabs from different companies in one place'
    },
    {
      image: '/assets/images/cab3.jpg',
      title: 'Integration with Maps',
      description: 'Get the best prices and navigate to your destination with ease'
    }
  ];

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide((prev) => prev + 1);
    } else {
      onComplete();
    }
  };

  return (
    <div className="flex min-h-screen flex-col justify-between bg-[#FBFBFB] p-6 max-w-md mx-auto">
      {/* Top Bar with Skip */}
      <div className="flex justify-end pt-2">
        <button
          onClick={onComplete}
          className="text-sm font-semibold text-gray-500 hover:text-blue-600 transition"
        >
          Skip
        </button>
      </div>

      {/* Slide Content */}
      <div className="flex flex-1 flex-col items-center justify-center text-center px-4">
        <div className="relative mb-8 h-64 w-full max-w-[280px] overflow-hidden rounded-3xl shadow-lg border border-gray-100 bg-white p-2">
          <img
            src={slides[currentSlide].image}
            alt={slides[currentSlide].title}
            className="h-full w-full object-cover rounded-2xl"
            onError={(e) => {
              // Fallback placeholder if image load encounters issues
              (e.target as HTMLElement).style.display = 'none';
            }}
          />
        </div>

        <h2 className="text-2xl font-extrabold text-[#222222] tracking-tight">
          {slides[currentSlide].title}
        </h2>
        <p className="mt-3 text-sm leading-relaxed text-[#96A7AF] max-w-xs font-medium">
          {slides[currentSlide].description}
        </p>
      </div>

      {/* Bottom Controls */}
      <div className="flex flex-col items-center gap-6 pb-6">
        {/* Indicators */}
        <div className="flex items-center gap-2">
          {slides.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setCurrentSlide(idx)}
              className={`h-2.5 rounded-full transition-all duration-300 ${
                currentSlide === idx
                  ? 'w-7 bg-[#0262FF]'
                  : 'w-2.5 bg-[#E7EAEB]'
              }`}
            />
          ))}
        </div>

        {/* Next Button with Blue Gradient */}
        <button
          onClick={handleNext}
          className="flex w-full items-center justify-center gap-2 rounded-2xl py-3.5 px-6 font-bold text-white shadow-lg shadow-blue-500/25 transition active:scale-[0.98]"
          style={{
            background: 'linear-gradient(to bottom, #0152FF, #0693FF)'
          }}
        >
          <span>{currentSlide === slides.length - 1 ? 'Get Started' : 'Next'}</span>
          {currentSlide === slides.length - 1 ? (
            <ChevronRight className="h-5 w-5" />
          ) : (
            <ArrowRight className="h-5 w-5" />
          )}
        </button>
      </div>
    </div>
  );
};
