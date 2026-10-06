import React, { useState } from 'react';
import { Phone, Lock, ArrowRight, ShieldCheck, ArrowLeftRight, Sparkles, PiggyBank, Car } from 'lucide-react';
import { storageService } from '../services/storageService';

interface LoginScreenProps {
  onLoginSuccess: () => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({ onLoginSuccess }) => {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSendOtp = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    let cleaned = phone.replace(/[\s-]/g, '');
    if (/^\d{10}$/.test(cleaned)) {
      cleaned = '+91' + cleaned;
    }

    if (!/^\+[1-9]\d{9,14}$/.test(cleaned)) {
      setError('Enter a valid 10-digit mobile number, e.g. 9876543210');
      return;
    }

    setError('');
    setIsLoading(true);

    setTimeout(() => {
      setIsLoading(false);
      setOtpSent(true);
      // Pre-fill demo OTP code for smooth testing
      setOtp('123456');
    }, 600);
  };

  const handleVerifyOtp = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (otp.length !== 6) {
      setError('Please enter the 6-digit OTP code');
      return;
    }

    setIsLoading(true);
    setError('');

    setTimeout(() => {
      setIsLoading(false);
      let cleanedPhone = phone.replace(/[\s-]/g, '');
      if (/^\d{10}$/.test(cleanedPhone)) {
        cleanedPhone = '+91' + cleanedPhone;
      }
      storageService.saveUserProfile({
        phone: cleanedPhone || '+919876543210'
      });
      onLoginSuccess();
    }, 500);
  };

  return (
    <div className="min-h-screen bg-[#F7F9FC] flex flex-col justify-between p-5 max-w-md mx-auto">
      <div className="pt-6">
        {/* Logo Card */}
        <div className="flex justify-center">
          <div className="h-28 w-28 overflow-hidden rounded-[28px] bg-white p-2.5 shadow-xl shadow-blue-500/10 border border-gray-100 flex items-center justify-center">
            <img
              src="/assets/images/karocab.jpg"
              alt="KaroCab Logo"
              className="h-full w-full object-cover rounded-[20px]"
              onError={(e) => {
                // Fallback icon
                (e.target as HTMLElement).style.display = 'none';
              }}
            />
          </div>
        </div>

        {/* Title & Tagline */}
        <div className="mt-6 text-center">
          <h1 className="text-2xl font-black text-[#111827] tracking-tight">
            Welcome to KaroCab
          </h1>
          <p className="mt-1 text-sm font-semibold text-[#6B7280]">
            Compare. Choose. Ride smarter.
          </p>
        </div>

        {/* Main Login Card */}
        <div className="mt-8 rounded-[28px] border border-[#E5E7EB] bg-white p-6 shadow-sm">
          <div className="flex items-center gap-3.5 mb-5">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#EFF6FF] text-[#1463FF]">
              <Phone className="h-5 w-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-[#111827]">
                Login to continue
              </h2>
              <p className="text-xs text-[#6B7280]">
                Access your smarter ride experience
              </p>
            </div>
          </div>

          {error && (
            <div className="mb-4 rounded-xl bg-red-50 p-3 text-xs font-semibold text-red-600 border border-red-100">
              {error}
            </div>
          )}

          <form onSubmit={otpSent ? handleVerifyOtp : handleSendOtp} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Mobile Number
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                  <Phone className="h-4 w-4" />
                </div>
                <input
                  type="tel"
                  disabled={otpSent || isLoading}
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="Enter 10-digit mobile number"
                  className="w-full rounded-2xl border border-gray-200 bg-gray-50/50 py-3.5 pl-10 pr-4 text-sm font-semibold text-gray-900 placeholder:text-gray-400 focus:border-[#1463FF] focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-75"
                />
              </div>
            </div>

            {otpSent && (
              <div className="animate-in fade-in duration-200">
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Enter 6-digit OTP
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                    <Lock className="h-4 w-4" />
                  </div>
                  <input
                    type="text"
                    maxLength={6}
                    disabled={isLoading}
                    value={otp}
                    onChange={(e) => setOtp(e.target.value)}
                    placeholder="Enter 6-digit OTP"
                    className="w-full rounded-2xl border border-gray-200 bg-gray-50/50 py-3.5 pl-10 pr-4 text-sm font-semibold text-gray-900 tracking-widest placeholder:text-gray-400 focus:border-[#1463FF] focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                  />
                </div>
                <div className="mt-1 flex justify-between items-center text-[11px] text-gray-500">
                  <span>Demo OTP: <b>123456</b></span>
                  <button
                    type="button"
                    onClick={() => {
                      setOtpSent(false);
                      setOtp('');
                    }}
                    className="text-blue-600 font-semibold hover:underline"
                  >
                    Change phone
                  </button>
                </div>
              </div>
            )}

            <button
              type="submit"
              disabled={isLoading}
              className="mt-2 flex w-full items-center justify-center gap-2 rounded-2xl bg-[#1463FF] hover:bg-blue-600 active:scale-[0.98] py-4 font-bold text-white shadow-md shadow-blue-500/20 transition disabled:opacity-60"
            >
              {isLoading ? (
                <div className="h-5 w-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : otpSent ? (
                <>
                  <span>Verify OTP</span>
                  <ArrowRight className="h-4 w-4" />
                </>
              ) : (
                <>
                  <span>Continue with Phone</span>
                  <ArrowRight className="h-4 w-4" />
                </>
              )}
            </button>
          </form>

          <div className="mt-4 flex items-center justify-center gap-1.5 text-xs text-gray-500 font-medium">
            <ShieldCheck className="h-4 w-4 text-emerald-600" />
            <span>Your login is secure</span>
          </div>
        </div>

        {/* Why KaroCab Section */}
        <div className="mt-8">
          <h3 className="text-base font-bold text-[#111827] mb-3">
            Why KaroCab?
          </h3>
          <div className="grid grid-cols-3 gap-2.5">
            <div className="rounded-2xl border border-[#E8EBF0] bg-white p-3 text-center shadow-xs">
              <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-xl bg-[#F0F5FF] text-[#1463FF] mb-2">
                <ArrowLeftRight className="h-5 w-5" />
              </div>
              <div className="text-xs font-bold text-[#111827]">Compare</div>
              <div className="text-[10px] text-[#8A919D] font-medium">Multiple rides</div>
            </div>

            <div className="rounded-2xl border border-[#E8EBF0] bg-white p-3 text-center shadow-xs">
              <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-xl bg-[#F0F5FF] text-[#1463FF] mb-2">
                <Sparkles className="h-5 w-5" />
              </div>
              <div className="text-xs font-bold text-[#111827]">KaroScore</div>
              <div className="text-[10px] text-[#8A919D] font-medium">Smarter choice</div>
            </div>

            <div className="rounded-2xl border border-[#E8EBF0] bg-white p-3 text-center shadow-xs">
              <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-xl bg-[#F0F5FF] text-[#1463FF] mb-2">
                <PiggyBank className="h-5 w-5" />
              </div>
              <div className="text-xs font-bold text-[#111827]">Save</div>
              <div className="text-[10px] text-[#8A919D] font-medium">Money & time</div>
            </div>
          </div>
        </div>

        {/* Tagline Banner */}
        <div className="mt-6 flex items-center gap-3 rounded-2xl bg-[#EEF5FF] p-4 text-[#174EA6]">
          <Car className="h-6 w-6 text-[#1463FF] shrink-0" />
          <p className="text-xs font-bold leading-snug">
            Don’t just compare. Decide smarter.
          </p>
        </div>
      </div>

      {/* Footer Terms */}
      <p className="mt-8 text-center text-[11px] leading-relaxed text-gray-400 font-medium">
        By continuing, you agree to KaroCab’s Terms & Privacy Policy.
      </p>
    </div>
  );
};
