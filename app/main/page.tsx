"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { MapPin, TrendingUp, Filter, QrCode, Plus, Thermometer, Droplets, Users, Award, BookOpen, Lightbulb, MessageCircle, Star, HelpCircle, Heart, Eye, Search, CheckCircle2, Share2, Bell, RefreshCw } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

export default function MainPage() {
  const router = useRouter();
  const [bins, setBins] = useState<any[]>([]);
  const [userLogCount, setUserLogCount] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [tab, setTab] = useState("journal");
  // Community tab state
  const [forumPosts, setForumPosts] = useState<any[]>([]);
  const [forumLoading, setForumLoading] = useState(false);
  const [forumError, setForumError] = useState("");
  const [guides, setGuides] = useState<any[]>([]);
  const [tips, setTips] = useState<any[]>([]);
  const [guidesLoading, setGuidesLoading] = useState(false);
  const [tipsLoading, setTipsLoading] = useState(false);
  const [guidesError, setGuidesError] = useState("");
  const [tipsError, setTipsError] = useState("");
  // Community tasks state
  const [communityTasks, setCommunityTasks] = useState<any[]>([]);
  const [communityLoading, setCommunityLoading] = useState(false);
  const [communityError, setCommunityError] = useState("");
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  
  // future implementation for notifs
  const notificationCount = 3;
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [joinInput, setJoinInput] = useState("");
  const [joinBinId, setJoinBinId] = useState("");
  const [joinPrompt, setJoinPrompt] = useState(false);
  const [joinLoading, setJoinLoading] = useState(false);
  const [joinError, setJoinError] = useState("");

  const fetchBins = async () => {
    setLoading(true);
    setError("");
    const user = await supabase.auth.getUser();
    const userId = user.data.user?.id;
    if (!userId) {
      setError("Not logged in");
      setLoading(false);
      return;
    }
    // Fetch bins where user is the owner
    const { data: ownedBins, error: ownedError } = await supabase
      .from("bins")
      .select("*")
      .eq("user_id", userId);

    // Fetch bin memberships
    const { data: memberRows, error: memberError } = await supabase
      .from("bin_members")
      .select("bin_id")
      .eq("user_id", userId);

    const memberBinIds = memberRows?.map(row => row.bin_id) || [];

    let memberBins = [];
    if (memberBinIds.length > 0) {
      const { data: memberBinsData } = await supabase
        .from("bins")
        .select("*")
        .in("id", memberBinIds);
      memberBins = memberBinsData || [];
    }

    // Combine and deduplicate
    const allBins = [
      ...(ownedBins || []),
      ...memberBins.filter(b => !(ownedBins || []).some(ob => ob.id === b.id))
    ];

    if (ownedError || memberError) setError(ownedError?.message || memberError?.message || "");
    else setBins(allBins);
    // Fetch logs count for current user
    const { count: logCount, error: logError } = await supabase
      .from("bin_logs")
      .select("*", { count: "exact", head: true })
      .eq("user_id", userId);

    if (logError) {
      console.error("Error fetching user log count:", logError);
    } else {
      setUserLogCount(logCount ?? 0);
    }

    setLoading(false);
  };

  useEffect(() => {
    fetchBins();
  }, []);

  useEffect(() => {
    if (tab === "community") {
      setForumLoading(true);
      setForumError("");
      fetch("/api/community/posts")
        .then(res => res.json())
        .then(data => {
          if (data.error) setForumError(data.error);
          else setForumPosts(data.posts || []);
        })
        .catch(() => setForumError("Network error"))
        .finally(() => setForumLoading(false));
      setGuidesLoading(true);
      setGuidesError("");
      fetch("/api/guides")
        .then(res => res.json())
        .then(data => {
          if (data.error) setGuidesError(data.error);
          else setGuides(data.guides || []);
        })
        .catch(() => setGuidesError("Network error"))
        .finally(() => setGuidesLoading(false));
      setTipsLoading(true);
      setTipsError("");
      fetch("/api/tips")
        .then(res => res.json())
        .then(data => {
          if (data.error) setTipsError(data.error);
          else setTips(data.tips || []);
        })
        .catch(() => setTipsError("Network error"))
        .finally(() => setTipsLoading(false));
    }
  }, [tab]);

  useEffect(() => {
    if (tab === "community") {
      setCommunityLoading(true);
      setCommunityError("");
      // Get current user and their bin memberships
      (async () => {
        const user = await supabase.auth.getUser();
        setCurrentUserId(user.data.user?.id || null);
        if (!user.data.user) {
          setCommunityError("Not logged in");
          setCommunityLoading(false);
          return;
        }
        // Get bins user is a member of
        const { data: memberships, error: memberError } = await supabase
          .from("bin_members")
          .select("bin_id")
          .eq("user_id", user.data.user.id);
        if (memberError) {
          setCommunityError(memberError.message);
          setCommunityLoading(false);
          return;
        }
        const binIds = memberships?.map((m: any) => m.bin_id) || [];
        if (binIds.length === 0) {
          setCommunityTasks([]);
          setCommunityLoading(false);
          return;
        }
        // Get tasks for those bins
        const { data: tasks, error: taskError } = await supabase
          .from("tasks")
          .select("*, profiles:user_id(id, first_name, last_name)")
          .in("bin_id", binIds)
          .order("created_at", { ascending: false });
        if (taskError) {
          setCommunityError(taskError.message);
          setCommunityLoading(false);
          return;
        }
        setCommunityTasks(tasks || []);
        setCommunityLoading(false);
      })();
    }
  }, [tab]);

  // Accept/Complete logic (API calls)
  const handleAcceptTask = async (taskId: string) => {
    // Call API to update task status and accepted_by
    await fetch(`/api/tasks/${taskId}/accept`, { method: 'POST' });
    setCommunityTasks(tasks => tasks.map(t => t.id === taskId ? { ...t, status: 'accepted', accepted_by: currentUserId } : t));
  };
  const handleCompleteTask = async (taskId: string) => {
    await fetch(`/api/tasks/${taskId}/complete`, { method: 'POST' });
    setCommunityTasks(tasks => tasks.map(t => t.id === taskId ? { ...t, status: 'completed' } : t));
  };

  // Filter bins by search
  const filteredBins = bins.filter(
    (bin) =>
      bin.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      bin.location?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const [showQR, setShowQR] = useState(false);
  const [showShare, setShowShare] = useState(false);
  const [shareUrl, setShareUrl] = useState("");
  const [whatsappUrl, setWhatsappUrl] = useState("");
  const [telegramUrl, setTelegramUrl] = useState("");

  const handleShowShare = () => {
    if (filteredBins.length > 0) {
      const url = `${window.location.origin}/bin/${filteredBins[0].id}`;
      setShareUrl(url);
      setWhatsappUrl(`https://wa.me/?text=${encodeURIComponent('Check out our compost bin on CompostKaki! ' + url)}`);
      setTelegramUrl(`https://t.me/share/url?url=${encodeURIComponent(url)}&text=${encodeURIComponent('Check out our compost bin on CompostKaki!')}`);
      setShowShare(true);
    } else {
      alert('No bins to share!');
    }
  };
  const handleShowQR = () => {
    if (filteredBins.length > 0) {
      const url = `${window.location.origin}/bin/${filteredBins[0].id}`;
      setShareUrl(url);
      setShowQR(true);
    } else {
      alert('No bins to show QR for!');
    }
  };

  const handleJoinInput = (val: string) => {
    setJoinInput(val);
    // Strict UUID regex
    const uuidRegex = /([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})/;
    let match = val.match(uuidRegex);
    if (match) {
      setJoinBinId(match[1]);
    } else {
      setJoinBinId("");
    }
  };
  const handleJoinConfirm = async () => {
    setJoinLoading(true);
    setJoinError("");
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;
      const res = await fetch('/api/bins/join', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {})
        },
        body: JSON.stringify({ binId: joinBinId })
      });
      const result = await res.json();
      if (!res.ok || result.error) throw new Error(result.error || 'Failed to join bin');
      setShowJoinModal(false);
      setJoinInput("");
      setJoinBinId("");
      setJoinPrompt(false);
      // Refresh bins
      if (typeof fetchBins === 'function') fetchBins();
      else window.location.reload();
    } catch (e: any) {
      setJoinError(e.message || "Failed to join bin");
    }
    setJoinLoading(false);
  };

  return (
    <div className="min-h-screen bg-white">
      <div className="relative max-w-md mx-auto">
        <div className="bg-[#F3F3F3] border-b border-[#E0E0E0] p-4 sticky top-0 z-10 flex items-center justify-between">
          <div className="flex-1 flex flex-col items-center">
            <div className="flex items-center gap-2 justify-center">
              <img src="/favicon.ico" alt="CompostKaki Logo" className="w-8 h-8" />
              <h1 className="text-2xl font-bold text-[#00796B]">CompostKaki</h1>
            </div>
          </div>
          <div className="flex items-center gap-2 ml-2">
            <Button
              className="bg-[#00796B] text-white px-4 py-2 rounded-lg font-semibold hover:bg-[#005B4F] ml-2"
              onClick={() => setShowJoinModal(true)}
            >
              Join Bin
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => router.push("/profile-settings")}
              className="p-0 hover:bg-gray-300/50 transition"
            >
              <div className="w-8 h-8 rounded-full bg-gray-200" />
            </Button>
          </div>
        </div>
        <Tabs value={tab} onValueChange={setTab} className="w-full mt-2">
          <div className="flex w-full justify-center">
            <TabsList className="flex w-full max-w-xs bg-[#F3F3F3] border border-[#E0E0E0] rounded-full p-1">
              <TabsTrigger
                value="journal"
                className="flex-1 rounded-full px-0 py-2 text-base font-semibold transition-all shadow-none border-none focus:outline-none focus:ring-0 data-[state=active]:bg-white data-[state=active]:text-[#00796B] data-[state=inactive]:bg-transparent data-[state=inactive]:text-gray-500"
              >
                Journal
              </TabsTrigger>
              <TabsTrigger
                value="community"
                className="flex-1 rounded-full px-0 py-2 text-base font-semibold transition-all shadow-none border-none focus:outline-none focus:ring-0 data-[state=active]:bg-white data-[state=active]:text-[#00796B] data-[state=inactive]:bg-transparent data-[state=inactive]:text-gray-500"
              >
                Community
              </TabsTrigger>
            </TabsList>
          </div>
        </Tabs>
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsContent value="journal">
            <div className="p-4 space-y-6 bg-white min-h-screen">
              <div className="grid grid-cols-2 gap-3">
                <div className="flex flex-col items-center justify-center bg-[#F3F3F3] rounded-lg p-4">
                  <div className="text-2xl font-bold text-[#00796B]">{bins.length}</div>
                  <div className="text-xs text-[#00796B] mt-1">Active Bins</div>
                </div>
                <div className="flex flex-col items-center justify-center bg-[#F3F3F3] rounded-lg p-4">
                  <div className="text-2xl font-bold text-[#00796B]">{userLogCount}</div>
                  <div className="text-xs text-[#00796B] mt-1">Logs</div>
                </div>
              </div>
              <div className="flex justify-between items-center mt-2 mb-2">
                <h2 className="text-[#00796B] text-base font-semibold">Active Piles</h2>
                <Button
                  className="bg-[#00796B] text-white px-4 py-2 rounded-lg font-semibold hover:bg-[#005B4F]"
                  onClick={() => router.push('/add-bin')}
                >
                  Add New Piles
                </Button>
              </div>
              <div className="bg-white rounded-lg border border-[#E0E0E0] divide-y divide-[#F3F3F3]">
                {loading && <div className="p-4 text-center">Loading bins...</div>}
                {error && <div className="p-4 text-red-600 text-sm text-center">{error}</div>}
                {filteredBins.map((bin) => (
                  <div
                    key={bin.id}
                    className="flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-[#F3F3F3] transition"
                    onClick={() => router.push(`/bin/${bin.id}`)}
                  >
                    <img
                      src={bin.image || "/default_compost_image.jpg"}
                      alt={bin.name}
                      className="w-10 h-10 object-cover rounded-md border border-[#E0E0E0]"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="font-semibold text-[#00796B] truncate">{bin.name}</div>
                      <div className="text-xs text-gray-500 truncate">{bin.location}</div>
                    </div>
                    <div className="flex flex-col items-end gap-1">
                      <span className="text-xs text-[#00796B] font-medium">{bin.health_status || 'Healthy'}</span>
                      <span className="text-xs text-gray-400">{bin.latest_temperature ? `${bin.latest_temperature}°C` : '-'}</span>
                    </div>
                  </div>
                ))}
                {filteredBins.length === 0 && !loading && <div className="p-4 text-gray-500 text-center">No bins found.</div>}
              </div>
            </div>
          </TabsContent>
          <TabsContent value="community">
            <div className="p-4 space-y-4">
              {communityLoading && <div className="text-center">Loading tasks...</div>}
              {communityError && <div className="text-red-600 text-center">{communityError}</div>}
              {!communityLoading && !communityError && communityTasks.length === 0 && (
                <div className="text-center text-gray-500">No tasks available. Relax for now :)</div>
              )}
              {communityTasks.map(task => (
                <div
                  key={task.id}
                  className="bg-white border border-[#E0E0E0] rounded-lg p-4 mb-2 shadow-sm"
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-semibold text-[#00796B]">{task.description}</div>
                      <div className="text-xs text-gray-500 mt-1">
                        Bin: {task.bin_id} &middot; Status: {task.status}
                      </div>
                    </div>
                    <span className="ml-2 px-2 py-1 rounded-full text-xs font-medium bg-[#E0F2F1] text-[#00796B]">
                      {task.urgency}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </div>
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
      {showJoinModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative flex flex-col items-center">
            <button
              className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
              onClick={() => setShowJoinModal(false)}
              aria-label="Close"
              style={{ fontSize: '2rem', lineHeight: '2rem' }}
            >
              ×
            </button>
            <h2 className="text-xl font-bold mb-4 text-[#00796B]">Join a Bin</h2>
            <input
              className="w-full border-2 border-[#00796B] rounded-xl px-4 py-2 text-base focus:outline-none focus:ring-2 focus:ring-[#00796B] bg-white text-[#00796B] placeholder:text-gray-400 mb-4"
              placeholder="Paste bin link or scan QR code"
              value={joinInput}
              onChange={e => handleJoinInput(e.target.value)}
            />
            {joinBinId && !joinPrompt && (
              <Button className="bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base w-full" onClick={() => setJoinPrompt(true)}>
                Join Bin
              </Button>
            )}
            {joinPrompt && (
              <div className="w-full flex flex-col items-center">
                <div className="mb-2 text-[#00796B]">Join bin <span className="font-bold">{joinBinId}</span>?</div>
                <Button className="bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base w-full mb-2" onClick={handleJoinConfirm} disabled={joinLoading}>
                  {joinLoading ? 'Joining...' : 'Confirm'}
                </Button>
                <Button variant="outline" className="w-full" onClick={() => setJoinPrompt(false)} disabled={joinLoading}>Cancel</Button>
              </div>
            )}
            {joinError && <div className="text-red-600 text-sm mt-2">{joinError}</div>}
          </div>
        </div>
      )}
    </div>
  );
} 