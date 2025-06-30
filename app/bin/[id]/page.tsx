"use client";
import React from "react";
import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { ScrollArea } from "@/components/ui/scroll-area";
import { ArrowLeft, Share2, Thermometer, Droplets, RefreshCw, Users, Calendar, Plus, Clock, Filter, Send, QrCode, Shovel, Leaf } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
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

  // For share menu
  const [showShare, setShowShare] = useState(false);
  const [showQR, setShowQR] = useState(false);

  const [joinPrompt, setJoinPrompt] = useState(false);
  const [joining, setJoining] = useState(false);
  const [joined, setJoined] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  // Modal state: which log (by id) is open, or null
  const [openModalLogId, setOpenModalLogId] = useState<string | null>(null);
  // Client-side mount state for relative time
  const [mounted, setMounted] = useState(false);
  useEffect(() => { setMounted(true); }, []);

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

  // Share handlers
  const shareUrl = typeof window !== "undefined" ? window.location.href : "";
  const shareText = bin ? `Check out our compost bin '${bin.name}' on CompostConnect!` : "Check out this compost bin!";
  const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(shareText + ' ' + shareUrl)}`;
  const telegramUrl = `https://t.me/share/url?url=${encodeURIComponent(shareUrl)}&text=${encodeURIComponent(shareText)}`;

  // Stat tile helpers
  const temp = bin?.latest_temperature;
  const moisture = bin?.latest_moisture;

  let tempColor = "bg-white border-green-700 text-green-900";
  let tempWarning = "";
  if (temp !== undefined && temp !== null) {
    if (temp > 50) {
      tempColor = "bg-red-500 text-white border-0";
      tempWarning = "Too hot!";
    } else if (temp < 27) {
      tempColor = "bg-red-500 text-white border-0";
      tempWarning = "Too cold!";
    } else if (temp >= 45) {
      tempColor = "bg-yellow-300 text-yellow-900 border-0";
      tempWarning = "Getting hot!";
    }
  }

  let moistureColor = "bg-yellow-300 text-yellow-900 border-0";
  if (moisture === "Perfect") {
    moistureColor = "bg-white border-green-700 text-green-900";
  } else if (moisture === "Wet" || moisture === "Dry") {
    moistureColor = "bg-yellow-300 text-yellow-900 border-0";
  } else if (moisture === "Very Wet" || moisture === "Very Dry") {
    moistureColor = "bg-red-500 text-white border-0";
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
      color: "bg-white border-green-700 text-green-900",
      warning: "",
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Sticky Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3 mb-4">
            <Button variant="ghost" size="sm" onClick={() => router.push("/main")}> <ArrowLeft className="w-5 h-5" /> </Button>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-green-800">{bin?.name || "Bin"}</h2>
              {bin?.created_at && (
                <div className="text-sm text-green-600 mt-1">
                  Created on: {new Date(bin.created_at).toLocaleDateString('en-GB')}
                </div>
              )}
            </div>
            {bin?.qr_code && (
              <Button variant="ghost" size="sm" onClick={() => setShowQR(true)}>
                <QrCode className="w-5 h-5" />
              </Button>
            )}
            <div className="relative">
              <Button variant="ghost" size="sm" onClick={() => setShowShare(v => !v)}><Share2 className="w-4 h-4" /></Button>
              {showShare && (
                <div className="absolute right-0 mt-2 bg-white border rounded shadow-lg z-20 p-2 flex flex-col gap-2 min-w-[140px]">
                  <Button asChild variant="outline" size="sm" className="justify-start"><a href={whatsappUrl} target="_blank" rel="noopener noreferrer">Share on WhatsApp</a></Button>
                  <Button asChild variant="outline" size="sm" className="justify-start"><a href={telegramUrl} target="_blank" rel="noopener noreferrer">Share on Telegram</a></Button>
                  <Button variant="ghost" size="sm" onClick={() => setShowShare(false)}>Close</Button>
                </div>
              )}
            </div>
          </div>

          {/* Join Bin Prompt - moved up */}
          {joinPrompt && !joined && (
            <div className="mb-4 p-4 bg-green-100 rounded-xl flex flex-col items-center">
              <div className="mb-2 text-green-800 font-semibold">Do you want to join this bin?</div>
              <Button
                disabled={joining}
                onClick={async () => {
                  setJoining(true);
                  try {
                    const { data: { session } } = await supabase.auth.getSession();
                    const token = session?.access_token;
                    await fetch('/api/bins/join', {
                      method: 'POST',
                      headers: {
                        'Content-Type': 'application/json',
                        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
                      },
                      body: JSON.stringify({ binId })
                    });
                    setJoined(true);
                    setJoinPrompt(false);
                    window.location.reload();
                  } catch (e) {
                    setJoining(false);
                  }
                }}
                className="mt-2"
              >
                {joining ? 'Joining...' : 'Join Bin'}
              </Button>
            </div>
          )}
          {joined && (
            <div className="mb-4 p-4 bg-green-50 rounded-xl text-green-700 text-center">You have joined this bin!</div>
          )}

          {/* Stat Tiles */}
          <div className="grid grid-cols-3 gap-2 mb-4">
            {statTiles.map((tile, i) => (
              <Card key={tile.label} className={`${tile.color} rounded-xl border-2 p-0`}>
                <CardContent className="p-2 text-center flex flex-col items-center justify-center">
                  <div className="mb-0.5">{React.cloneElement(tile.icon, { className: "w-4 h-4" })}</div>
                  <div className="text-base font-bold leading-tight">{typeof tile.value === 'string' ? tile.value : String(tile.value)}</div>
                  {tile.warning && <div className="text-xs font-semibold mt-0.5">{tile.warning}</div>}
                  <div className="text-xs opacity-90 mt-0.5">{tile.label}</div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Compost Health Tag */}
          {bin?.health_status && (
            <div className="flex justify-center mb-4">
              <span className={`px-3 py-1 rounded-full font-semibold text-sm shadow-sm ${getHealthColor(bin.health_status)}`}>
                Compost Health: {bin.health_status}
              </span>
            </div>
          )}
        </div>

        {/* QR Code Modal */}
        {showQR && bin?.qr_code && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <div className="bg-white rounded-xl p-6 shadow-lg flex flex-col items-center relative">
              <img src={bin.qr_code} alt="Bin QR Code" className="w-56 h-56 mb-4" id="bin-qr-img" />
              <Button
                variant="secondary"
                size="sm"
                className="mb-2"
                onClick={() => {
                  const link = document.createElement('a');
                  link.href = bin.qr_code;
                  link.download = 'bin-qr.png';
                  link.click();
                }}
              >
                Download QR Code
              </Button>
              <Button variant="outline" size="sm" onClick={() => setShowQR(false)} className="mt-2">Close</Button>
            </div>
          </div>
        )}

        <div className="p-4 space-y-4">
          {/* Log New Activity Button */}
          <div className="flex justify-center mb-4">
            <Button
              onClick={() => router.push(`/bin/${binId}/logactivity`)}
              className="w-48 h-16 text-lg bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white rounded-xl shadow-lg hover:shadow-xl transition-all duration-200"
            >
              Log new activity
            </Button>
          </div>

          {/* Activity Timeline */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-green-800 flex items-center gap-2">
                <Clock className="w-5 h-5" />
                Activity Timeline
              </h3>
              <Button variant="ghost" size="sm">
                <Filter className="w-4 h-4" />
              </Button>
            </div>
            {loading && <div>Loading...</div>}
            {error && <div className="text-red-600 text-sm">{error}</div>}
            <ScrollArea className="h-96">
              <div className="flex flex-col items-center">
                {activities.length === 0 && !loading && <div>No activities yet.</div>}
                {activities.map((entry: any, idx: number) => {
                  // Determine temperature and moisture display for activity card
                  const temp = entry.temperature;
                  const moist = entry.moisture;
                  let tempStatus = '';
                  let tempColor = 'text-green-800';
                  if (temp !== undefined && temp !== null) {
                    if (temp > 50) {
                      tempStatus = 'Too hot!';
                      tempColor = 'text-red-600 font-bold';
                    } else if (temp < 27) {
                      tempStatus = 'Too cold!';
                      tempColor = 'text-red-600 font-bold';
                    } else if (temp >= 45) {
                      tempStatus = 'Getting hot!';
                      tempColor = 'text-yellow-700 font-semibold';
                    } else {
                      tempStatus = 'Optimal';
                    }
                  }
                  let moistStatus = '';
                  let moistColor = "text-green-800";
                  if (moist === "Perfect") {
                    moistStatus = "Perfect";
                    moistColor = "text-green-800";
                  } else if (moist === "Wet" || moist === "Dry") {
                    moistStatus = moist;
                    moistColor = "text-yellow-700 font-semibold";
                  } else if (moist === "Very Wet" || moist === "Very Dry") {
                    moistStatus = moist;
                    moistColor = "text-red-600 font-bold";
                  }
                  // Calculate 'x days ago'
                  const createdAt = new Date(entry.created_at);
                  const timeAgo = formatDistanceToNow(createdAt, { addSuffix: true });
                  // Highlight most recent log
                  const isMostRecent = idx === 0;
                  // Choose icon and color based on action/type
                  let ActionIcon = Shovel;
                  let iconColor = '#16a34a'; // default green
                  const actionText = (entry.action || entry.content || '').toLowerCase();
                  const typeText = (entry.type || '').toLowerCase();
                  if (actionText.includes('turn') || typeText.includes('turn')) {
                    ActionIcon = RefreshCw;
                    iconColor = '#2563eb'; // blue
                  } else if (actionText.includes('monitor') || actionText.includes('check') || typeText.includes('monitor') || typeText.includes('check')) {
                    ActionIcon = Thermometer;
                    iconColor = '#ea580c'; // orange
                  } else if (actionText.includes('greens') || typeText.includes('greens')) {
                    ActionIcon = Leaf;
                    iconColor = '#16a34a'; // green
                  } else if (actionText.includes('browns') || typeText.includes('browns')) {
                    ActionIcon = Plus;
                    iconColor = '#f59e42'; // amber
                  }
                  // Image preview logic
                  let imageUrl = null;
                  if (entry.image && Array.isArray(entry.image) && entry.image.length > 0) {
                    imageUrl = entry.image[0];
                  } else if (entry.image && typeof entry.image === 'string') {
                    imageUrl = entry.image;
                  }
                  return (
                    <div key={entry.id} className="flex items-stretch group w-full justify-center">
                      <Card className={`w-full max-w-2xl mb-3 ml-0 ${isMostRecent ? 'shadow-lg ring-2 ring-green-200' : 'shadow'} bg-white rounded-xl transition-all duration-200`} style={{ minHeight: '70px' }}>
                        <CardContent className="px-6 py-3 flex flex-col gap-0.5">
                          <div className="flex justify-between items-start mb-0.5">
                            <div className="flex items-center gap-2">
                              <Avatar className="w-10 h-10 border-2 border-white shadow-sm">
                                <AvatarImage src={entry.avatar || "/placeholder.svg"} />
                                <AvatarFallback className="bg-green-100 text-green-700">
                                  {(() => {
                                    if (entry.user_id === currentUserId) return "Y";
                                    const fn = entry.profiles?.first_name || "";
                                    const ln = entry.profiles?.last_name || "";
                                    const initials = (fn + ' ' + ln).trim().split(' ').map((n: string) => n[0]).join('');
                                    return initials || "U";
                                  })()}
                                </AvatarFallback>
                              </Avatar>
                              <div>
                                <div className="flex items-center gap-1 font-bold text-green-800 text-base">
                                  <ActionIcon className="w-5 h-5 mr-1" style={{ color: iconColor }} />
                                  {entry.type || entry.action || entry.content}
                                </div>
                                <div className="text-xs text-gray-600 mt-0.5">
                                  by {entry.user_id === currentUserId ? "You" : ((entry.profiles?.first_name || "") + (entry.profiles?.last_name ? " " + entry.profiles.last_name : "")).trim() || "Unnamed"}
                                </div>
                              </div>
                            </div>
                            <span className="text-xs text-gray-500 whitespace-nowrap mt-1">
                              {mounted ? timeAgo : new Date(entry.created_at).toLocaleString()}
                            </span>
                          </div>
                          <div className="flex items-center ml-12 gap-3">
                            <div className="text-gray-700 text-sm mb-1">{entry.content}</div>
                            {imageUrl && (
                              <img src={imageUrl} alt="Log image" className="w-12 h-12 object-cover rounded-md border ml-2" />
                            )}
                          </div>
                          <div className="flex gap-6 mt-1 ml-12">
                            {temp !== undefined && temp !== null && (
                              <span className={`flex items-center gap-1 text-sm ${tempColor}`}>
                                <Thermometer className="w-4 h-4" />
                                {temp}°C {tempStatus && <span className="ml-1">{tempStatus}</span>}
                              </span>
                            )}
                            {moist !== undefined && moist !== null && (
                              <span className={`flex items-center gap-1 text-sm ${moistColor}`}>
                                <Droplets className="w-4 h-4" />
                                {moistStatus === moist ? moist : `${moist} ${moistStatus && moistStatus}`}
                              </span>
                            )}
                          </div>
                          <div className="flex justify-end mt-1">
                            <button
                              className="text-green-700 hover:underline text-xs font-medium flex items-center gap-1"
                              onClick={() => setOpenModalLogId(entry.id)}
                            >
                              View details
                            </button>
                          </div>
                        </CardContent>
                      </Card>
                    </div>
                  );
                })}
                {/* Modal rendering outside the map for hydration safety */}
                {openModalLogId && (() => {
                  const entry = activities.find((e: any) => e.id === openModalLogId);
                  if (!entry) return null;
                  // icon logic
                  let ActionIcon = Shovel;
                  let iconColor = '#16a34a';
                  const actionText = (entry.action || entry.content || '').toLowerCase();
                  const typeText = (entry.type || '').toLowerCase();
                  if (actionText.includes('turn') || typeText.includes('turn')) {
                    ActionIcon = RefreshCw;
                    iconColor = '#2563eb';
                  } else if (actionText.includes('monitor') || actionText.includes('check') || typeText.includes('monitor') || typeText.includes('check')) {
                    ActionIcon = Thermometer;
                    iconColor = '#ea580c';
                  } else if (actionText.includes('greens') || typeText.includes('greens')) {
                    ActionIcon = Leaf;
                    iconColor = '#16a34a';
                  } else if (actionText.includes('browns') || typeText.includes('browns')) {
                    ActionIcon = Plus;
                    iconColor = '#f59e42';
                  }
                  let imageUrl = null;
                  if (entry.image && Array.isArray(entry.image) && entry.image.length > 0) {
                    imageUrl = entry.image[0];
                  } else if (entry.image && typeof entry.image === 'string') {
                    imageUrl = entry.image;
                  }
                  const temp = entry.temperature;
                  const moist = entry.moisture;
                  return (
                    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                      <div className="bg-white rounded-xl shadow-lg p-6 max-w-lg w-full relative">
                        <button
                          className="absolute top-3 right-3 text-gray-500 hover:text-gray-800 text-xl"
                          onClick={() => setOpenModalLogId(null)}
                          aria-label="Close"
                        >
                          ×
                        </button>
                        <div className="flex items-center gap-2 mb-2">
                          <ActionIcon className="w-6 h-6 mr-1" style={{ color: iconColor }} />
                          <span className="font-bold text-lg text-green-800">{entry.type || entry.action || entry.content}</span>
                        </div>
                        <div className="text-gray-700 text-base mb-2">{entry.content}</div>
                        {imageUrl && (
                          <div className="mb-3 flex flex-col items-center">
                            <img src={imageUrl} alt="Log image" className="max-h-64 rounded-md border mb-2" />
                            <a
                              href={imageUrl}
                              download
                              className="text-green-700 hover:underline text-xs font-medium"
                            >
                              Download image
                            </a>
                          </div>
                        )}
                        <div className="flex flex-col gap-1 text-sm text-gray-700 mt-2">
                          <div>
                            <span className="font-semibold">User:</span> {entry.user_id === currentUserId ? "You" : ((entry.profiles?.first_name || "") + (entry.profiles?.last_name ? " " + entry.profiles.last_name : "")).trim() || "Unnamed"}
                          </div>
                          {entry.created_at && <div><span className="font-semibold">Time:</span> {new Date(entry.created_at).toLocaleString()}</div>}
                          {temp !== undefined && temp !== null && <div><span className="font-semibold">Temperature:</span> {temp}°C</div>}
                          {moist !== undefined && moist !== null && <div><span className="font-semibold">Moisture:</span> {moist}</div>}
                        </div>
                      </div>
                    </div>
                  );
                })()}
              </div>
            </ScrollArea>
          </div>
        </div>
      </div>
    </div>
  );
}
// TODO: Add ability to edit bin name, show last flip time, and more status details as needed.
