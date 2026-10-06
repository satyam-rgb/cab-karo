import React, { useState, useRef, useEffect } from 'react';
import { X, Send, Bot, User, Sparkles, Navigation, Copy, RotateCcw, Check } from 'lucide-react';
import { PricingResponse } from '../types';

interface Message {
  id: string;
  sender: 'user' | 'ai';
  text: string;
  time: string;
}

interface ChatScreenModalProps {
  isOpen: boolean;
  onClose: () => void;
  pricingContext: PricingResponse | null;
  fromAddress: string;
  toAddress: string;
}

export const ChatScreenModal: React.FC<ChatScreenModalProps> = ({
  isOpen,
  onClose,
  pricingContext,
  fromAddress,
  toAddress
}) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  const suggestedQuestions = [
    'Which ride is cheapest?',
    'Which is fastest?',
    'Which ride should I take?',
    'Is an Auto or Cab better for this trip?',
    'How is KaroScore calculated?'
  ];

  useEffect(() => {
    if (messages.length === 0) {
      const best = pricingContext?.recommendations.bestOverall;
      const bestRide = pricingContext?.rides.find((r) => r.id === best);

      let initialGreeting =
        'Hello! I am **KaroAI**, your mobility advisor. I evaluate live rates, driver ETAs, safety records, and KaroScore metrics across Uber & Ola.';

      if (pricingContext && bestRide) {
        initialGreeting += `\n\nFor your **${pricingContext.distance} km** trip from *${fromAddress || 'Pickup'}* to *${toAddress || 'Destination'}*, our top pick is **${bestRide.provider} ${bestRide.category}** (₹${bestRide.fare.toFixed(2)}, KaroScore ${bestRide.karoScore}/100).\n\nTap a question below or ask anything!`;
      }

      setMessages([
        {
          id: 'msg-0',
          sender: 'ai',
          text: initialGreeting,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }
      ]);
    }
  }, [pricingContext, fromAddress, toAddress]);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, isTyping]);

  if (!isOpen) return null;

  const generateAiReply = (query: string): string => {
    const q = query.toLowerCase().trim();

    if (q.includes('cheapest') || q.includes('lowest fare') || q.includes('budget')) {
      if (!pricingContext || !pricingContext.rides.length) {
        return 'Please input your pickup and drop points on the home map so I can compute actual fare estimates!';
      }
      const sortedByFare = [...pricingContext.rides].sort((a, b) => a.fare - b.fare);
      const cheapest = sortedByFare[0];
      const secondCheapest = sortedByFare[1];
      const diff = secondCheapest ? (secondCheapest.fare - cheapest.fare).toFixed(2) : '0';

      return `💰 **Cheapest Ride:**\n\n**${cheapest.provider} ${cheapest.category}** at estimated **₹${cheapest.fare.toFixed(2)}** (ETA: ${cheapest.eta} min, KaroScore: ${cheapest.karoScore}/100).\n\nIt saves you ₹${diff} compared to the next lowest option (${secondCheapest?.provider} ${secondCheapest?.category}).`;
    }

    if (q.includes('fastest') || q.includes('quickest') || q.includes('hurry') || q.includes('eta')) {
      if (!pricingContext || !pricingContext.rides.length) {
        return 'Please select a route first to check live arrival ETAs!';
      }
      const fastest = [...pricingContext.rides].sort((a, b) => a.eta - b.eta)[0];
      return `⚡ **Fastest Arrival:**\n\n**${fastest.provider} ${fastest.category}** is closest with an estimated pickup in **${fastest.eta} minutes** (Fare: ₹${fastest.fare.toFixed(2)}, Duration: ${fastest.duration} min).`;
    }

    if (q.includes('which ride should i take') || q.includes('which ride should') || q.includes('recommend')) {
      if (!pricingContext || !pricingContext.rides.length) {
        return 'Please calculate a route first so I can assess available options for you!';
      }
      const rec = pricingContext.recommendations;
      const overall = pricingContext.rides.find((r) => r.id === rec.bestOverall);
      const cheapest = pricingContext.rides.find((r) => r.id === rec.cheapest || r.id === rec.bestBudget);

      return `🎯 **Smart Recommendation:**\n\n• **Top Overall Choice:** **${overall?.provider} ${overall?.category}** (KaroScore ${overall?.karoScore}/100, ₹${overall?.fare.toFixed(2)})\n• **Most Economical:** **${cheapest?.provider} ${cheapest?.category}** (₹${cheapest?.fare.toFixed(2)})\n\n${rec.balancedExplanation || ''}`;
    }

    if (q.includes('sedan') || q.includes('mini') || q.includes('xl')) {
      if (!pricingContext) {
        return 'Please input your route to see Mini, Sedan, and XL options!';
      }
      const cat = q.includes('sedan') ? 'Sedan' : q.includes('xl') ? 'XL' : 'Mini';
      const matching = pricingContext.rides.filter((r) => r.vehicleCategory === cat);
      if (matching.length) {
        const best = [...matching].sort((a, b) => b.karoScore - a.karoScore)[0];
        return `🚗 **${cat} Options for this Route:**\n\n• Top ${cat}: **${best.provider} ${best.category}** (₹${best.fare.toFixed(2)}, ETA: ${best.eta} min, KaroScore: ${best.karoScore}/100)\n• Total available options: ${matching.length} (Uber & Ola)\n\nYou can also use the new "${cat}" filter pill in the Cab Comparison sheet to narrow down options!`;
      }
    }

    if (q.includes('auto') || q.includes('cab')) {
      if (!pricingContext) {
        return 'Autos are 25-35% more economical for short and medium intra-city hops, whereas Cabs provide superior weather protection, air-conditioning, and luggage capacity.';
      }
      const autos = pricingContext.rides.filter((r) => r.category.toLowerCase().includes('auto'));
      const cabs = pricingContext.rides.filter((r) => r.category.toLowerCase().includes('cab'));
      const minAuto = autos.sort((a, b) => a.fare - b.fare)[0];
      const minCab = cabs.sort((a, b) => a.fare - b.fare)[0];

      return `🚖 **Auto vs Cab Analysis for this Route:**\n\n• Lowest Auto: **${minAuto?.provider} Auto** at **₹${minAuto?.fare.toFixed(2)}** (ETA: ${minAuto?.eta} min)\n• Lowest Cab: **${minCab?.provider} Cab** at **₹${minCab?.fare.toFixed(2)}** (ETA: ${minCab?.eta} min)\n\nSaving with Auto is ₹${(minCab.fare - minAuto.fare).toFixed(2)}. If weather is pleasant and you have light luggage, the Auto is your best value.`;
    }

    if (q.includes('karoscore') || q.includes('calculated') || q.includes('methodology')) {
      return `📊 **KaroScore Methodology:**\n\nWe normalize all factors to a 0–100 scale using min-max normalization across all active options:\n\n• **Fare Economy (30-40%)**: Lower fare = higher score\n• **Pickup ETA (10-30%)**: Shorter wait = higher score\n• **Trip Duration (10-25%)**: Faster commute time\n• **Safety Rating (15%)**: Vehicle age, driver verification & safety standards\n• **Comfort (10%)**: Vehicle ergonomics & AC comfort\n• **Reliability (10-15%)**: Historical driver acceptance & completion\n\nYou can also switch between **Balanced**, **Budget**, and **Hurry** optimization modes in the comparison sheet!`;
    }

    return `I can help you analyze fares, compare Uber vs Ola, explain KaroScores, or find the best trade-off between price and speed. What specific details would you like to explore?`;
  };

  const handleSendMessage = (textToSend?: string) => {
    const text = (textToSend || inputValue).trim();
    if (!text) return;

    const userMsg: Message = {
      id: 'msg-' + Date.now(),
      sender: 'user',
      text,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputValue('');
    setIsTyping(true);

    setTimeout(() => {
      const replyText = generateAiReply(text);
      const aiMsg: Message = {
        id: 'msg-ai-' + Date.now(),
        sender: 'ai',
        text: replyText,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      setMessages((prev) => [...prev, aiMsg]);
      setIsTyping(false);
    }, 400);
  };

  const handleCopyMessage = (id: string, text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 1500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
      <div className="flex h-[90vh] w-full max-w-lg flex-col rounded-[28px] bg-[#F7F9FC] shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-200 bg-white p-4 shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-600 text-white shadow-xs">
              <Bot className="h-5 w-5" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <h3 className="text-base font-black text-gray-950">KaroAI</h3>
                <span className="flex h-2 w-2 rounded-full bg-emerald-500" />
              </div>
              <p className="text-[11px] text-gray-500 font-medium">
                Context-aware ride decision advisor
              </p>
            </div>
          </div>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setMessages([])}
              title="Reset conversation"
              className="rounded-full p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-700 transition"
            >
              <RotateCcw className="h-4 w-4" />
            </button>
            <button
              onClick={onClose}
              className="rounded-full p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-700 transition"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        {/* Route Context Bar */}
        {pricingContext && (
          <div className="flex items-center gap-2 border-b border-blue-100 bg-blue-50/80 px-4 py-2 text-xs font-semibold text-blue-900 shrink-0">
            <Navigation className="h-3.5 w-3.5 text-blue-600 shrink-0" />
            <span className="truncate">
              {fromAddress || 'Pickup'} → {toAddress || 'Destination'} (
              {pricingContext.distance} km • {pricingContext.duration} min)
            </span>
          </div>
        )}

        {/* Messages Stream */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((m) => (
            <div
              key={m.id}
              className={`flex gap-2.5 ${m.sender === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              {m.sender === 'ai' && (
                <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-blue-100 text-blue-600 mt-0.5">
                  <Bot className="h-4 w-4" />
                </div>
              )}

              <div
                className={`group relative max-w-[85%] rounded-2xl p-3.5 text-xs font-medium leading-relaxed whitespace-pre-line shadow-xs ${
                  m.sender === 'user'
                    ? 'bg-blue-600 text-white rounded-tr-xs'
                    : 'bg-white text-gray-800 border border-gray-150 rounded-tl-xs'
                }`}
              >
                {m.text}

                <div className="mt-1 flex items-center justify-between gap-3 text-[10px] opacity-75">
                  <span className={m.sender === 'user' ? 'text-blue-100' : 'text-gray-400'}>
                    {m.time}
                  </span>
                  {m.sender === 'ai' && (
                    <button
                      onClick={() => handleCopyMessage(m.id, m.text)}
                      className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-700 transition"
                      title="Copy message"
                    >
                      {copiedId === m.id ? (
                        <Check className="h-3 w-3 text-emerald-600" />
                      ) : (
                        <Copy className="h-3 w-3" />
                      )}
                    </button>
                  )}
                </div>
              </div>

              {m.sender === 'user' && (
                <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-blue-600 text-white mt-0.5">
                  <User className="h-4 w-4" />
                </div>
              )}
            </div>
          ))}

          {isTyping && (
            <div className="flex items-center gap-2 text-xs text-gray-400 font-medium pl-9">
              <Sparkles className="h-3.5 w-3.5 text-blue-600 animate-pulse" />
              <span>Analyzing live ride options...</span>
            </div>
          )}
        </div>

        {/* Suggested Prompt Chips */}
        <div className="flex items-center gap-1.5 overflow-x-auto px-4 py-2 border-t border-gray-100 bg-white/90 shrink-0 no-scrollbar">
          {suggestedQuestions.map((q) => (
            <button
              key={q}
              onClick={() => handleSendMessage(q)}
              className="shrink-0 rounded-full border border-gray-200 bg-white px-3 py-1.5 text-xs font-bold text-gray-700 hover:border-blue-400 hover:text-blue-600 transition shadow-2xs"
            >
              {q}
            </button>
          ))}
        </div>

        {/* Input Form */}
        <div className="border-t border-gray-200 bg-white p-3 shrink-0">
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSendMessage();
            }}
            className="flex items-center gap-2"
          >
            <input
              type="text"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              placeholder="Ask about pricing, speed, or KaroScore..."
              className="flex-1 rounded-2xl border border-gray-200 bg-gray-50 px-4 py-3 text-xs font-semibold text-gray-900 placeholder:text-gray-400 focus:border-blue-600 focus:bg-white focus:outline-none"
            />
            <button
              type="submit"
              disabled={!inputValue.trim()}
              className="flex h-10 w-10 items-center justify-center rounded-2xl bg-blue-600 text-white shadow-md shadow-blue-500/20 hover:bg-blue-700 disabled:opacity-40 transition"
            >
              <Send className="h-4 w-4" />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
