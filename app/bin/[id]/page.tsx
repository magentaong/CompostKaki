"use client";
import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { ScrollArea } from "@/components/ui/scroll-area";
import { ArrowLeft, Share2, Thermometer, Droplets, RefreshCw, Users, Calendar, Plus, Clock, Filter, Send, QrCode } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";

function getHealthColor(status: string) {
  switch (status) {
    case "Critical": return "bg-red-100 text-red-700";
    case "Healthy": return "bg-green-100 text-green-700";
    case "Needs Help": return "bg-yellow-100 text-yellow-800";
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
  const statTiles = [
    {
      label: "Temperature",
      value: bin?.latest_temperature !== undefined && bin?.latest_temperature !== null ? `${bin.latest_temperature}°C` : "New bin: temperature not taken",
      icon: <Thermometer className="w-5 h-5" />, 
      color: "from-orange-500 to-red-500",
    },
    {
      label: "Moisture",
      value: bin?.latest_moisture !== undefined && bin?.latest_moisture !== null ? String(bin.latest_moisture) : "New bin: moisture not taken",
      icon: <Droplets className="w-5 h-5" />, 
      color: "from-blue-500 to-cyan-500",
    },
    {
      label: "Flipping",
      value: bin?.latest_flips !== undefined && bin?.latest_flips !== null ? String(bin.latest_flips) : "New bin: not flipped yet",
      icon: <RefreshCw className="w-5 h-5" />, 
      color: "from-purple-500 to-fuchsia-500",
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
              <div className="flex items-center gap-1 text-sm text-green-600">
                <Calendar className="w-3 h-3" />
                {bin?.created_at ? new Date(bin.created_at).toLocaleDateString() : "-"}
              </div>
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

          {/* Compost Health Tag (floating, no container) */}
          {bin?.health_status && (
            <div className="flex justify-center mb-4">
              <span className={`px-3 py-1 rounded-full font-semibold text-sm shadow-sm ${getHealthColor(bin.health_status)}`}>
                Compost Health: {bin.health_status}
              </span>
            </div>
          )}

          {/* Stat Tiles */}
          <div className="grid grid-cols-3 gap-3 mb-4">
            {statTiles.map((tile, i) => (
              <Card key={tile.label} className={`bg-gradient-to-br ${tile.color} text-white border-0`}>
                <CardContent className="p-3 text-center flex flex-col items-center justify-center">
                  <div className="mb-1">{tile.icon}</div>
                  <div className="text-lg font-bold leading-tight">{typeof tile.value === 'string' ? tile.value : String(tile.value)}</div>
                  <div className="text-xs opacity-90 mt-1">{tile.label}</div>
                </CardContent>
              </Card>
            ))}
          </div>
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
              <div className="space-y-4">
                {activities.length === 0 && !loading && <div>No activities yet.</div>}
                {activities.map((entry: any) => (
                  <Card key={entry.id} className="bg-white/80 backdrop-blur-sm border-green-100 hover:shadow-md transition-shadow">
                    <CardContent className="p-4">
                      <div className="flex items-start gap-3">
                        <Avatar className="w-10 h-10 border-2 border-white shadow-sm">
                          <AvatarImage src={entry.avatar || "/placeholder.svg"} />
                          <AvatarFallback className="bg-green-100 text-green-700">
                            {entry.user?.split(" ").map((n: string) => n[0]).join("") || "U"}
                          </AvatarFallback>
                        </Avatar>
                        <div className="flex-1 min-w-0">
                          <div className="flex justify-between items-start mb-2">
                            <div>
                              <h4 className="font-semibold text-green-800 text-sm">{entry.action || entry.content}</h4>
                              <p className="text-xs text-gray-600">by {entry.user || "You"}</p>
                            </div>
                            <span className="text-xs text-gray-500">{new Date(entry.created_at).toLocaleString()}</span>
                          </div>
                          <p className="text-sm text-gray-700 mb-3">{entry.details || entry.content}</p>
                          {/* TODO: Add more fields, images, likes, etc. */}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </ScrollArea>
          </div>
        </div>
      </div>
    </div>
  );
}
// TODO: Add ability to edit bin name, show last flip time, and more status details as needed.
