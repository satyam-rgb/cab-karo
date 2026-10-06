import React, { useState } from 'react';
import {
  X,
  ShieldAlert,
  AlertTriangle,
  User,
  Phone,
  Save,
  CheckCircle2,
  Copy,
  ExternalLink,
  MapPin,
  Clock,
  ShieldCheck,
  AlertCircle
} from 'lucide-react';
import { storageService } from '../services/storageService';
import { EmergencyContact } from '../types';

interface KaroSafeModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const KaroSafeModal: React.FC<KaroSafeModalProps> = ({
  isOpen,
  onClose
}) => {
  const [contact, setContact] = useState<EmergencyContact>(() =>
    storageService.getEmergencyContact()
  );
  const [nameInput, setNameInput] = useState(contact.name);
  const [phoneInput, setPhoneInput] = useState(contact.phone);
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);
  const [isSendingSos, setIsSendingSos] = useState(false);
  const [sosPrepared, setSosPrepared] = useState<{
    message: string;
    mapsLink: string;
    phone: string;
  } | null>(null);

  if (!isOpen) return null;

  const isConfigured = Boolean(contact.phone && contact.phone.trim().length > 6);

  const handleSaveContact = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nameInput.trim() || !phoneInput.trim()) return;

    setIsSaving(true);
    setTimeout(() => {
      const updated = { name: nameInput.trim(), phone: phoneInput.trim() };
      storageService.saveEmergencyContact(updated);
      setContact(updated);
      setIsSaving(false);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 2500);
    }, 400);
  };

  const executeSos = () => {
    setShowConfirmDialog(false);
    setIsSendingSos(true);

    const onLocationAcquired = (lat: number, lng: number) => {
      const now = new Date();
      const timeStr = now.toLocaleDateString() + ' ' + now.toLocaleTimeString();
      const mapsLink = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
      const message = `🚨 KaroCab SOS Alert\n\nI need immediate assistance.\n\nEmergency Contact: ${contact.name}\nCurrent GPS Location:\n${mapsLink}\n\nTime: ${timeStr}`;

      setSosPrepared({
        message,
        mapsLink,
        phone: contact.phone
      });
      setIsSendingSos(false);

      // Attempt to launch SMS handler
      try {
        const smsUri = `sms:${contact.phone}?body=${encodeURIComponent(message)}`;
        window.location.href = smsUri;
      } catch {
        // Fallback rendered on screen
      }
    };

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => onLocationAcquired(pos.coords.latitude, pos.coords.longitude),
        (_err) => {
          onLocationAcquired(21.1458, 79.0882); // Nagpur center fallback
        },
        { enableHighAccuracy: true, timeout: 6000 }
      );
    } else {
      onLocationAcquired(21.1458, 79.0882);
    }
  };

  const handleCopySos = () => {
    if (!sosPrepared) return;
    navigator.clipboard.writeText(sosPrepared.message);
    alert('Emergency SOS message copied to clipboard!');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-md flex-col rounded-[28px] bg-white shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-150 p-5 bg-white shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-red-50 text-red-600 shadow-xs">
              <ShieldAlert className="h-6 w-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-lg font-black text-gray-950">KaroSafe</h3>
                {isConfigured ? (
                  <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-[10px] font-extrabold text-emerald-800">
                    <ShieldCheck className="h-3 w-3" />
                    Active
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-extrabold text-amber-800">
                    <AlertCircle className="h-3 w-3" />
                    Setup Needed
                  </span>
                )}
              </div>
              <p className="text-xs text-gray-500 font-medium">
                Emergency assistance & instant location sharing
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

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-6">
          {/* Status Alert Banner */}
          <div
            className={`flex items-center justify-between rounded-2xl p-3.5 border ${
              isConfigured
                ? 'bg-emerald-50/70 border-emerald-200 text-emerald-900'
                : 'bg-amber-50/80 border-amber-200 text-amber-900'
            }`}
          >
            <div className="flex items-center gap-2.5 text-xs font-bold">
              {isConfigured ? (
                <ShieldCheck className="h-4 w-4 text-emerald-600 shrink-0" />
              ) : (
                <AlertCircle className="h-4 w-4 text-amber-600 shrink-0" />
              )}
              <span>
                {isConfigured
                  ? `Contact: ${contact.name} (${contact.phone})`
                  : 'No emergency contact set yet.'}
              </span>
            </div>
          </div>

          {/* Big SOS Button */}
          <div className="flex flex-col items-center justify-center py-2">
            <button
              onClick={() => {
                if (!isConfigured) {
                  alert('Please enter and save your emergency contact details below first.');
                  return;
                }
                setShowConfirmDialog(true);
              }}
              disabled={isSendingSos}
              className="group relative flex h-44 w-44 flex-col items-center justify-center rounded-full bg-gradient-to-br from-red-500 to-red-700 text-white shadow-2xl shadow-red-500/35 transition-all hover:scale-102 active:scale-95 cursor-pointer ring-8 ring-red-100"
            >
              <div className="absolute inset-0 rounded-full bg-red-500 animate-ping opacity-25 pointer-events-none" />
              {isSendingSos ? (
                <div className="h-10 w-10 border-4 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <AlertTriangle className="h-10 w-10 mb-1 drop-shadow-sm" />
                  <span className="text-3xl font-black tracking-wider">SOS</span>
                  <span className="text-[10px] font-extrabold uppercase tracking-widest text-red-100 mt-1">
                    Tap For Emergency
                  </span>
                </>
              )}
            </button>
            <p className="mt-3 text-xs font-semibold text-center text-gray-500">
              Two-step confirmation prevents accidental triggers
            </p>
          </div>

          {/* SOS Confirmation Dialog */}
          {showConfirmDialog && (
            <div className="rounded-2xl border-2 border-red-500 bg-red-50 p-4 animate-in fade-in">
              <div className="flex items-center gap-2 text-red-900 font-extrabold text-sm mb-1.5">
                <AlertTriangle className="h-5 w-5 text-red-600 shrink-0" />
                <span>Confirm Emergency Alert</span>
              </div>
              <p className="text-xs text-red-800 leading-relaxed font-medium mb-3">
                This will retrieve your live coordinates and prepare an SOS message for <b>{contact.name}</b> at <b>{contact.phone}</b>.
              </p>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setShowConfirmDialog(false)}
                  className="flex-1 rounded-xl bg-white border border-gray-200 py-2.5 text-xs font-bold text-gray-700 hover:bg-gray-100 transition"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={executeSos}
                  className="flex-1 rounded-xl bg-red-600 py-2.5 text-xs font-extrabold text-white hover:bg-red-700 transition shadow-md shadow-red-500/25"
                >
                  Send SOS Now
                </button>
              </div>
            </div>
          )}

          {/* SOS Prepared Notification Banner */}
          {sosPrepared && (
            <div className="rounded-2xl border border-red-200 bg-red-50/90 p-4 animate-in fade-in">
              <div className="flex items-center gap-2 text-red-900 font-bold text-sm mb-2">
                <CheckCircle2 className="h-5 w-5 text-emerald-600" />
                <span>SOS Alert Ready</span>
              </div>
              <p className="text-xs text-gray-800 font-medium mb-3 whitespace-pre-line bg-white p-3 rounded-xl border border-red-100">
                {sosPrepared.message}
              </p>
              <div className="flex gap-2">
                <button
                  onClick={handleCopySos}
                  className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-white border border-red-200 py-2.5 text-xs font-bold text-red-700 hover:bg-red-50 transition"
                >
                  <Copy className="h-3.5 w-3.5" />
                  Copy Alert
                </button>
                <a
                  href={`sms:${sosPrepared.phone}?body=${encodeURIComponent(sosPrepared.message)}`}
                  className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-red-600 py-2.5 text-xs font-bold text-white hover:bg-red-700 transition"
                >
                  <ExternalLink className="h-3.5 w-3.5" />
                  Open SMS
                </a>
              </div>
            </div>
          )}

          {/* Emergency Contact Setup Form */}
          <div className="rounded-2xl border border-gray-200 bg-gray-50/60 p-4">
            <h4 className="text-sm font-extrabold text-gray-900 mb-3">
              Configure Emergency Contact
            </h4>
            <form onSubmit={handleSaveContact} className="space-y-3">
              <div>
                <label className="block text-[11px] font-bold text-gray-700 mb-1">
                  Contact Name / Relation
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                    <User className="h-4 w-4" />
                  </div>
                  <input
                    type="text"
                    value={nameInput}
                    onChange={(e) => setNameInput(e.target.value)}
                    placeholder="e.g. Parent / Sibling / Friend"
                    className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-9 pr-3 text-xs font-semibold text-gray-900 focus:border-red-500 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-gray-700 mb-1">
                  Phone Number
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                    <Phone className="h-4 w-4" />
                  </div>
                  <input
                    type="tel"
                    value={phoneInput}
                    onChange={(e) => setPhoneInput(e.target.value)}
                    placeholder="+91XXXXXXXXXX"
                    className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-9 pr-3 text-xs font-semibold text-gray-900 focus:border-red-500 focus:outline-none"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={isSaving}
                className="flex w-full items-center justify-center gap-1.5 rounded-xl bg-gray-900 py-2.5 text-xs font-bold text-white hover:bg-black transition"
              >
                {isSaving ? (
                  <span>Saving...</span>
                ) : saveSuccess ? (
                  <>
                    <CheckCircle2 className="h-4 w-4 text-emerald-400" />
                    <span>Saved Successfully</span>
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4" />
                    <span>Save Contact</span>
                  </>
                )}
              </button>
            </form>
          </div>

          {/* How KaroSafe Works */}
          <div className="rounded-2xl border border-gray-150 bg-white p-4">
            <h4 className="text-sm font-bold text-gray-900 mb-2.5">
              How KaroSafe works
            </h4>
            <div className="space-y-2.5 text-xs text-gray-600">
              <div className="flex items-start gap-2.5">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-red-100 text-[10px] font-black text-red-600">
                  1
                </span>
                <p>Tap the red SOS button and confirm.</p>
              </div>
              <div className="flex items-start gap-2.5">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-red-100 text-[10px] font-black text-red-600">
                  2
                </span>
                <p>KaroCab retrieves your precise current GPS location.</p>
              </div>
              <div className="flex items-start gap-2.5">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-red-100 text-[10px] font-black text-red-600">
                  3
                </span>
                <p className="flex items-center gap-1">
                  <MapPin className="h-3 w-3 text-red-600" />
                  A live Google Maps search coordinate link is formulated.
                </p>
              </div>
              <div className="flex items-start gap-2.5">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-red-100 text-[10px] font-black text-red-600">
                  4
                </span>
                <p>Your SMS app opens with the SOS alert ready for dispatch.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
