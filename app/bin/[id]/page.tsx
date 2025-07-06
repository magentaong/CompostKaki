"use client";
import React from "react";
import { useEffect, useState, useRef } from "react";
import { useRouter, useParams } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { ScrollArea } from "@/components/ui/scroll-area";
import { ArrowLeft, Share2, Thermometer, Droplets, RefreshCw, Users, Calendar, Plus, Clock, Filter, Send, QrCode, Shovel, Leaf } from "lucide-react";
import { differenceInDays, formatDistanceToNow } from 'date-fns';

function getHealthColor(status: string) {
  switch (status) {
    case "Critical": return "bg-red-100 text-red-700";
    case "Healthy": return "bg-green-100 text-green-700";
    case "Needs Attention": return "bg-yellow-100 text-yellow-800";
    default: return "bg-gray-100 text-gray-700";
  }
}

export default function BinDetailPage() {
  const router = useRouter();
  const params = useParams();
  const binId = params?.id as string;

  const [bin, setBin] = useState<any>(null);
  const [activities, setActivities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // For editing health status
  const [editingHealth, setEditingHealth] = useState(false);
  const [newHealth, setNewHealth] = useState(bin?.health_status || "Healthy");

  // For share menu
  const [showShare, setShowShare] = useState(false);
  const [showQR, setShowQR] = useState(false);

  const [joinPrompt, setJoinPrompt] = useState(false);
  const [joining, setJoining] = useState(false);
  const [joined, setJoined] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  const [session, setSession] = useState(null);

  // Modal state: which log (by id) is open, or null
  const [openModalLogId, setOpenModalLogId] = useState<string | null>(null);
  // Client-side mount state for relative time
  const [mounted, setMounted] = useState(false);
  useEffect(() => { setMounted(true); }, []);

  // Ask for Help modal state
  const [showHelpModal, setShowHelpModal] = useState(false);
  const [helpUrgency, setHelpUrgency] = useState('Normal');
  const [helpEffort, setHelpEffort] = useState('Medium');
  const [helpDescription, setHelpDescription] = useState('');
  const [helpTimeSensitive, setHelpTimeSensitive] = useState(false);
  const [helpDueDate, setHelpDueDate] = useState('');
  const [helpPhoto, setHelpPhoto] = useState<File | null>(null);
  const [helpLoading, setHelpLoading] = useState(false);
  const [helpError, setHelpError] = useState('');
  const [helpSuccess, setHelpSuccess] = useState(false);

  const [joinInput, setJoinInput] = useState("");
  const [joinBinId, setJoinBinId] = useState("");

  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleHelpPhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setHelpPhoto(e.target.files[0]);
    }
  };

  const handleHelpSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setHelpLoading(true);
    setHelpError('');
    setHelpSuccess(false);
    let photoUrl = null;
    try {
      const user = await supabase.auth.getUser();
      const userId = user.data.user?.id;
      if (!userId) throw new Error("Not logged in");
      if (!binId) throw new Error("No bin");
      if (!helpDescription.trim()) throw new Error("Description required");
      if (helpPhoto) {
        const fileExt = helpPhoto.name.split('.').pop();
        const filePath = `help_${userId}_${Date.now()}.${fileExt}`;
        const { error: uploadError } = await supabase.storage.from('bin-logs').upload(filePath, helpPhoto, { upsert: true });
        if (uploadError) throw new Error(uploadError.message || "Failed to upload photo");
        const { data: publicUrlData } = supabase.storage.from('bin-logs').getPublicUrl(filePath);
        photoUrl = publicUrlData.publicUrl;
      }
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;
      const response = await fetch('/api/tasks', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {})
        },
        body: JSON.stringify({
          bin_id: binId,
          urgency: helpUrgency,
          effort: helpEffort,
          description: helpDescription,
          is_time_sensitive: helpTimeSensitive,
          due_date: helpTimeSensitive && helpDueDate ? helpDueDate : null,
          photo_url: photoUrl,
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || "Failed to create help request");
      setHelpSuccess(true);
      setTimeout(() => {
        setShowHelpModal(false);
        setHelpSuccess(false);
        setHelpDescription('');
        setHelpPhoto(null);
        setHelpDueDate('');
        setHelpTimeSensitive(false);
      }, 1200);
    } catch (err: any) {
      setHelpError(err.message || "Failed to create help request");
    }
    setHelpLoading(false);
  };

  useEffect(() => {
    if (!binId) return;
    setLoading(true);
    setError("");
    // Fetch bin details
    fetch(`/api/bins/${binId}`)
      .then(res => res.json())
      .then(data => {
        if (data.error) throw new Error(data.error);
        setBin(data.bin);
      })
      .catch(e => setError(e.message || "Failed to load bin"));
    // Fetch bin activities (logs)
    fetch(`/api/bins/logs?bin_id=${binId}`)
      .then(async res => {
        try {
          const data = await res.json();
          if (data.error) throw new Error(data.error);
          setActivities(data.entries);
        } catch (err) {
          setError("Failed to load activities: " + ((err instanceof Error ? err.message : "Invalid JSON")));
        }
      })
      .catch(e => setError(e.message || "Failed to load activities"))
      .finally(() => setLoading(false));
    // Get current user
    supabase.auth.getUser().then(({ data }) => {
      setCurrentUserId(data.user?.id || null);
    });
  }, [binId]);

  useEffect(() => {
    if (bin && currentUserId && bin.user_id !== currentUserId && !(bin.contributors_list || []).includes(currentUserId)) {
      setJoinPrompt(true);
    } else {
      setJoinPrompt(false);
    }
  }, [bin, currentUserId]);

  useEffect(() => {
    setNewHealth(bin?.health_status || "Healthy");
  }, [bin]);

  // Share handlers
  const shareUrl = typeof window !== "undefined" ? window.location.href : "";
  const shareText = bin ? `Check out our compost bin '${bin.name}' on CompostConnect!` : "Check out this compost bin!";
  const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(shareText + ' ' + shareUrl)}`;
  const telegramUrl = `https://t.me/share/url?url=${encodeURIComponent(shareUrl)}&text=${encodeURIComponent(shareText)}`;

  // Stat tile helpers
  const temp = bin?.latest_temperature;
  const moisture = bin?.latest_moisture;

  let tempColor = "bg-[#80B543] border-green-700 text-[#2B2B2B]";
  let tempWarning = "";

  if (temp !== undefined && temp !== null) {
    if (temp > 50) {
      tempColor = "bg-[#E04F4F] text-[#2B2B2B] border-[#991B1B]";
      tempWarning = "Too hot!";
    } else if (temp < 27) {
      tempColor = "bg-[#E04F4F] text-[#2B2B2B] border-[#991B1B]";
      tempWarning = "Too cold!";
    } else if (temp >= 45) {
      tempColor = "bg-[#FEF3C7] text-[#92400E] border-[#991B1B]";
      tempWarning = "Getting hot!";
    }
  }

  let moistureColor = "bg-[#FEF3C7] text-[#2B2B2B] border-[#FEF3C7]"; // Default "okay" warning

  if (moisture === "Perfect") {
    moistureColor = "bg-[#80B543] border-green-700 text-[#2B2B2B]";
  } else if (moisture === "Wet" || moisture === "Dry") {
    moistureColor = "bg-[#FFD479] text-[#92400E] border-[#92400E]";
  } else if (moisture === "Very Wet" || moisture === "Very Dry") {
    moistureColor = "bg-[#E04F4F] text-[#2B2B2B] border-[#991B1B]";
  }



  const statTiles = [
    {
      label: "Temperature",
      value: temp !== undefined && temp !== null ? `${temp}°C` : "New bin: temperature not taken",
      icon: <Thermometer className="w-5 h-5" />,
      color: tempColor,
      warning: tempWarning,
    },
    {
      label: "Moisture",
      value: moisture !== undefined && moisture !== null ? String(moisture) : "New bin: moisture not taken",
      icon: <Droplets className="w-5 h-5" />,
      color: moistureColor,
    },
    {
      label: "Flipping",
      value: bin?.latest_flips !== undefined && bin?.latest_flips !== null ? String(bin.latest_flips) : "New bin: not flipped yet",
      icon: <RefreshCw className="w-5 h-5" />,
      color: "bg-white border-green-700 text-[#2B2B2B]",
      warning: "",
    },
  ];

  const handleJoinInput = (val: string) => {
    setJoinInput(val);
    // Extract full UUID from link or QR code
    const match = val.match(/bin\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})/);
    if (match) setJoinBinId(match[1]);
    else setJoinBinId("");
  };

  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-md mx-auto">
        {/* Top section: softer off-white background */}
        <div className="bg-[#FFFEFA] pb-6">
          {/* Header: Back button and pile image */}
          <div className="flex flex-col items-center pt-4 pb-2">
            <div className="w-full flex items-center justify-between px-2 mb-2">
              <Button variant="ghost" size="icon" onClick={() => router.push('/main')}>
                <ArrowLeft className="w-6 h-6 text-black" />
              </Button>
              <div className="flex items-center gap-2">
                <Button variant="ghost" size="icon" onClick={() => setShowShare(true)}>
                  <Share2 className="w-6 h-6 text-[#00796B]" />
              </Button>
                <Button variant="ghost" size="icon" onClick={() => setShowQR(true)}>
                  <QrCode className="w-6 h-6 text-[#00796B]" />
                  </Button>
                </div>
            </div>
            <img
              src={bin?.image || "/default_compost_image.jpg"}
              alt={bin?.name || "Compost pile"}
              className="w-24 h-24 object-cover rounded-xl mb-2 border border-gray-200 bg-gray-100"
            />
          </div>
          {/* Bin Name */}
          <h2 className="text-2xl font-bold text-center mb-2">{bin?.name || "Bin"}</h2>
          {/* Health Status */}
          {bin?.health_status && (
            <div className="flex justify-center mb-4">
              <span className={`px-4 py-1 rounded-full font-semibold text-sm bg-[#E6F4EA] text-[#00796B]`}>{bin.health_status}</span>
            </div>
          )}
          {/* Stat Tiles Row */}
          <div className="grid grid-cols-3 gap-3 mb-4 px-4">
            <div className="flex flex-col items-center justify-center rounded-xl min-h-[90px] min-w-[90px] px-0 py-6" style={{ background: '#F3F3F3' }}>
              <div className="text-3xl text-black">{bin?.latest_temperature ?? '-'}</div>
              <div className="text-base text-gray-600 mt-1">Temp</div>
            </div>
            <div className="flex flex-col items-center justify-center rounded-xl min-h-[90px] min-w-[90px] px-0 py-6" style={{ background: '#FFEDFF' }}>
              <div className="text-3xl text-black">{bin?.latest_moisture ?? '-'}</div>
              <div className="text-base text-gray-600 mt-1">Moisture Level</div>
        </div>
            <div className="flex flex-col items-center justify-center rounded-xl min-h-[90px] min-w-[90px] px-0 py-6" style={{ background: '#F2FF9C' }}>
              <div className="text-3xl text-black">{bin?.latest_flips ?? '-'}</div>
              <div className="text-base text-gray-600 mt-1">Flips</div>
            </div>
          </div>
        </div>
        {/* Action Buttons and rest of page: white background */}
        <div className="bg-white">
          <div className="flex gap-3 justify-center mb-6 px-4">
            <Button
              className="bg-[#00796B] text-white font-semibold rounded-lg px-6 py-2 flex-1"
              onClick={() => router.push(`/bin/${binId}/logactivity`)}
            >
              + Activity
            </Button>
            <Button
              variant="outline"
              className="border-[#00796B] text-[#00796B] font-semibold rounded-lg px-6 py-2 flex-1 bg-transparent hover:bg-[#F3F3F3]"
              onClick={() => setShowHelpModal(true)}
            >
              💪 Ask for Help
            </Button>
          </div>
          {/* Activity Timeline - vertical timeline style */}
          <div className="px-4">
            <h3 className="font-bold text-lg mb-3">Activity Timeline</h3>
            {loading && <div>Loading...</div>}
            {error && <div className="text-red-600 text-sm">{error}</div>}
            <div className="relative ml-4">
              {/* Vertical line */}
              <div className="absolute left-0 top-0 w-0.5 h-full bg-gray-200" style={{ zIndex: 0 }} />
              <div className="flex flex-col gap-8">
                {activities.length === 0 && !loading && <div className="text-gray-500">No activities yet.</div>}
                {activities.map((entry: any, idx: number) => (
                  <div key={entry.id} className="relative flex items-start gap-4">
                    {/* Dot - perfectly aligned to the line */}
                    <div className="relative ml-[-5px] top-[4px] w-3 h-3 rounded-full bg-gray-200 border-2 border-white z-10" />
                    <div className="flex-1 pl-3">
                      <div className="text-xs text-gray-400 mb-1">
                        {new Date(entry.created_at).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })}, {new Date(entry.created_at).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}
                      </div>
                      <div className="text-lg font-semibold text-gray-900 mb-1">{entry.type || entry.action || entry.content}</div>
                      {/* Posted by and avatar */}
                      <div className="flex items-center gap-2 mb-2">
                        <Avatar className="w-7 h-7">
                          <AvatarImage src={entry.profiles?.avatar_url || undefined} />
                          <AvatarFallback className="bg-[#F3F3F3] text-[#00796B] text-base">
                            {((entry.profiles?.first_name || '') + ' ' + (entry.profiles?.last_name || '')).split(' ').map(n => n[0]).join('').toUpperCase()}
                                </AvatarFallback>
                              </Avatar>
                        <span className="text-sm text-gray-700 font-medium">
                          Posted by {entry.profiles?.first_name || 'Unknown'} {entry.profiles?.last_name || ''}
                            </span>
                          </div>
                      <div className="text-base text-gray-600 mb-2">{entry.content}</div>
                      {/* Show log image if present */}
                      {entry.image && (
                        Array.isArray(entry.image) ? (
                          entry.image.length > 0 ? <img src={entry.image[0]} alt="Log" className="w-full max-h-48 object-contain rounded-lg border mb-2" /> : null
                        ) : (
                          <img src={entry.image} alt="Log" className="w-full max-h-48 object-contain rounded-lg border mb-2" />
                        )
                      )}
                      <Button 
                        variant="outline" 
                        size="sm" 
                        className="border-gray-300 text-gray-700 rounded-lg px-4 py-1 text-sm font-medium bg-transparent"
                              onClick={() => setOpenModalLogId(entry.id)}
                            >
                        Learn more &rarr;
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
            {/* Modal for activity details */}
                {openModalLogId && (() => {
                  const entry = activities.find((e: any) => e.id === openModalLogId);
                  if (!entry) return null;
              // Image logic
                  let imageUrl = null;
                  if (entry.image && Array.isArray(entry.image) && entry.image.length > 0) {
                    imageUrl = entry.image[0];
                  } else if (entry.image && typeof entry.image === 'string') {
                    imageUrl = entry.image;
                  }
                  return (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
                  <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative">
                        <button
                      className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
                          onClick={() => setOpenModalLogId(null)}
                          aria-label="Close"
                      style={{ fontSize: '2rem', lineHeight: '2rem' }}
                        >
                          ×
                        </button>
                    <div className="mb-2 text-xs text-gray-400">{new Date(entry.created_at).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })}</div>
                    {/* Posted by and avatar in modal */}
                    <div className="flex items-center gap-2 mb-3">
                      <Avatar className="w-8 h-8">
                        <AvatarImage src={entry.profiles?.avatar_url || undefined} />
                        <AvatarFallback className="bg-[#F3F3F3] text-[#00796B] text-base">
                          {((entry.profiles?.first_name || '') + ' ' + (entry.profiles?.last_name || '')).split(' ').map(n => n[0]).join('').toUpperCase()}
                        </AvatarFallback>
                      </Avatar>
                      <span className="text-sm text-gray-700 font-medium">
                        Posted by {entry.profiles?.first_name || 'Unknown'} {entry.profiles?.last_name || ''}
                      </span>
                        </div>
                    <div className="mb-2 text-xl font-semibold text-gray-900">{entry.type || entry.action || entry.content}</div>
                    <div className="mb-3 text-base text-gray-700">{entry.content}</div>
                        {imageUrl && (
                      <img src={imageUrl} alt="Log image" className="w-full max-h-72 object-contain rounded-lg border mb-2" />
                    )}
                      </div>
                    </div>
                  );
                })()}
              </div>
        </div>
      </div>
      {/* Ask for Help Modal */}
      {showHelpModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative">
            <button
              className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
              onClick={() => setShowHelpModal(false)}
              aria-label="Close"
              style={{ fontSize: '2rem', lineHeight: '2rem' }}
            >
              ×
            </button>
            <h2 className="text-xl font-bold mb-4 text-[#00796B]">Ask for Help</h2>
            <form onSubmit={handleHelpSubmit} className="space-y-4">
              {/* Urgency Pills */}
              <div>
                <div className="mb-1 font-semibold text-[#00796B]">Urgency</div>
                <div className="flex gap-2 flex-wrap">
                  {["High Priority", "Normal", "Low Priority"].map(opt => (
                    <button
                      type="button"
                      key={opt}
                      className={`px-3 py-1 rounded-full border text-sm font-medium ${helpUrgency === opt ? 'bg-[#00796B] text-white border-[#00796B]' : 'bg-white text-[#00796B] border-[#00796B]'}`}
                      onClick={() => setHelpUrgency(opt)}
                    >
                      {opt}
                    </button>
                  ))}
                </div>
              </div>
              {/* Effort Pills */}
              <div>
                <div className="mb-1 font-semibold text-[#00796B]">Effort</div>
                <div className="flex gap-2 flex-wrap">
                  {["Low", "Medium", "High"].map(opt => (
                    <button
                      type="button"
                      key={opt}
                      className={`px-3 py-1 rounded-full border text-sm font-medium ${helpEffort === opt ? 'bg-[#00796B] text-white border-[#00796B]' : 'bg-white text-[#00796B] border-[#00796B]'}`}
                      onClick={() => setHelpEffort(opt)}
                    >
                      {opt}
                    </button>
                  ))}
                </div>
              </div>
              {/* Description */}
              <div>
                <div className="mb-1 font-semibold text-[#00796B]">Description</div>
                <textarea
                  className="w-full border-2 border-[#00796B] rounded-xl px-4 py-2 text-base focus:outline-none focus:ring-2 focus:ring-[#00796B] bg-white text-[#00796B] placeholder:text-gray-400"
                  placeholder="Describe what you need help with..."
                  value={helpDescription}
                  onChange={e => setHelpDescription(e.target.value)}
                  rows={3}
                  required
                />
              </div>
              {/* Time Sensitive */}
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="help-time-sensitive"
                  checked={helpTimeSensitive}
                  onChange={e => setHelpTimeSensitive(e.target.checked)}
                />
                <label htmlFor="help-time-sensitive" className="text-[#00796B] font-medium">Time Sensitive</label>
                {helpTimeSensitive && (
                  <input
                    type="datetime-local"
                    className="ml-2 border border-[#00796B] rounded px-2 py-1 text-[#00796B]"
                    value={helpDueDate}
                    onChange={e => setHelpDueDate(e.target.value)}
                    required
                  />
                )}
              </div>
              {/* Photo Upload */}
              <div>
                <label className="block text-[#00796B] font-semibold mb-1">Add Photo (Optional)</label>
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="flex items-center gap-2 px-4 py-2 border border-[#00796B] rounded-lg text-[#00796B] font-medium bg-white hover:bg-[#F3F3F3] transition"
                >
                  <span role="img" aria-label="camera">📷</span> Choose Image
                </button>
                <input
                  type="file"
                  accept="image/*"
                  ref={fileInputRef}
                  onChange={handleHelpPhotoChange}
                  className="hidden"
                />
                {helpPhoto && (
                  <div className="mt-2 flex items-center gap-2">
                    <img src={URL.createObjectURL(helpPhoto)} alt="Preview" className="w-12 h-12 object-cover rounded border" />
                    <span className="text-xs text-[#00796B]">{helpPhoto.name}</span>
                  </div>
                )}
              </div>
              {helpError && <div className="text-red-600 text-sm">{helpError}</div>}
              {helpSuccess && <div className="text-green-700 font-bold text-center">Help request posted!</div>}
              <div className="flex gap-2 mt-4">
                <button
                  type="submit"
                  className="flex-1 bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base disabled:opacity-60"
                  disabled={helpLoading}
                >
                  {helpLoading ? 'Posting...' : 'Submit'}
                </button>
                <button
                  type="button"
                  className="flex-1 border border-[#00796B] text-[#00796B] rounded-lg py-2 font-semibold text-base bg-transparent"
                  onClick={() => setShowHelpModal(false)}
                  disabled={helpLoading}
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {showQR && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative flex flex-col items-center">
            <button
              className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
              onClick={() => setShowQR(false)}
              aria-label="Close"
              style={{ fontSize: '2rem', lineHeight: '2rem' }}
            >
              ×
            </button>
            <h2 className="text-xl font-bold mb-4 text-[#00796B]">Share Bin QR Code</h2>
            <img
              src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(shareUrl)}`}
              alt="QR Code"
              className="mb-4"
            />
            <div className="text-center text-sm text-gray-600 break-all">{shareUrl}</div>
          </div>
        </div>
      )}
      {showShare && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative flex flex-col items-center">
            <button
              className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
              onClick={() => setShowShare(false)}
              aria-label="Close"
              style={{ fontSize: '2rem', lineHeight: '2rem' }}
            >
              ×
            </button>
            <h2 className="text-xl font-bold mb-4 text-[#00796B]">Share Bin</h2>
            <div className="flex gap-4 mb-4">
              <a
                href={whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-[#25D366] text-white px-4 py-2 rounded-lg font-semibold flex items-center"
              >
                WhatsApp
              </a>
              <a
                href={telegramUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-[#0088cc] text-white px-4 py-2 rounded-lg font-semibold flex items-center"
              >
                Telegram
              </a>
            </div>
            <div className="text-center text-sm text-gray-600 break-all">{shareUrl}</div>
        </div>
      </div>
      )}
    </div>
  );
}
// TODO: Add ability to edit bin name, show last flip time, and more status details as needed.