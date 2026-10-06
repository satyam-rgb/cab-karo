import React, { useState } from 'react';
import { OnboardingScreen } from './screens/OnboardingScreen';
import { LoginScreen } from './screens/LoginScreen';
import { HomeScreen } from './screens/HomeScreen';
import { storageService } from './services/storageService';

export const App: React.FC = () => {
  const [isOnboarded, setIsOnboarded] = useState<boolean>(() =>
    storageService.isOnboardingCompleted()
  );

  const [userProfile, setUserProfile] = useState(() =>
    storageService.getUserProfile()
  );

  const handleCompleteOnboarding = () => {
    storageService.setOnboardingCompleted(true);
    setIsOnboarded(true);
  };

  const handleLoginSuccess = () => {
    const profile = storageService.getUserProfile();
    setUserProfile(profile);
  };

  const handleLogout = () => {
    storageService.logoutUser();
    setUserProfile(null);
  };

  // 1. Show Onboarding Carousel for new visitors
  if (!isOnboarded) {
    return <OnboardingScreen onComplete={handleCompleteOnboarding} />;
  }

  // 2. Show Login Screen if not logged in
  if (!userProfile) {
    return <LoginScreen onLoginSuccess={handleLoginSuccess} />;
  }

  // 3. Show Main HomeScreen
  return <HomeScreen onLogout={handleLogout} />;
};

export default App;
