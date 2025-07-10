"use client";
import { useEffect, useState, useRef } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { MapPin, TrendingUp, Filter, QrCode, Plus, Thermometer, Droplets, Users, Award, BookOpen, Lightbulb, MessageCircle, Star, HelpCircle, Heart, Eye, Search, CheckCircle2, Share2, Bell, RefreshCw, User, Camera, Copy } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Html5Qrcode } from "html5-qrcode";
import { apiFetch } from "@/lib/apiFetch";

export default function MainPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [bins, setBins] = useState<any[]>([]);
  const [userLogCount, setUserLogCount] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [tab, setTab] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('mainTab') || 'journal';
    }
    return 'journal';
  });
  const handleTabChange = (val: string) => {
    setTab(val);
    if (typeof window !== 'undefined') {
      localStorage.setItem('mainTab', val);
    }
  };
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
  // Add state for task modal
  const [openTask, setOpenTask] = useState<any | null>(null);
  // Add logic to fetch currentUserProfile (if you have profile info)
  const [currentUserProfile, setCurrentUserProfile] = useState<any>(null);

  // QR Scanner states
  const [showScanner, setShowScanner] = useState(false);
  const [scanning, setScanning] = useState(false);
  const [scanError, setScanError] = useState("");
  const qrRegionId = "qr-reader-region";
  const html5QrCodeRef = useRef<InstanceType<typeof Html5Qrcode> | null>(null);

  // Welcome modal and spotlight state
  const [showWelcomeModal, setShowWelcomeModal] = useState(false);
  const [showSpotlight, setShowSpotlight] = useState(false);
  const confettiRef = useRef<HTMLDivElement>(null);
  const actionButtonsRef = useRef<HTMLDivElement>(null);
  const [spotlightRect, setSpotlightRect] = useState<{top:number,left:number,width:number,height:number}|null>(null);

  // Filter bins by search
  const filteredBins = bins.filter(
    (bin) =>
      bin.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      bin.location?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Sort filteredBins by health_status: Critical > Needs Attention > Healthy > others
  const healthPriority = (status: string) => {
    if (status === 'Critical') return 0;
    if (status === 'Needs Attention') return 1;
    if (status === 'Healthy') return 2;
    return 3;
  };
  const sortedBins = [...filteredBins].sort((a, b) => healthPriority(a.health_status) - healthPriority(b.health_status));

  // Add state for community intro modal
  const [showCommunityIntro, setShowCommunityIntro] = useState(false);
  const prevTab = useRef(tab);
  console.log(sortedBins.length, tab, prevTab.current, communityTasks.length);
  useEffect(() => {
    if (
      !loading &&
      !communityLoading &&
      sortedBins.length === 0 &&
      tab === 'community' &&
      prevTab.current !== 'community' &&
      communityTasks.length === 0
    ) {
      setShowCommunityIntro(true);
    } else {
      setShowCommunityIntro(false);
    }
    prevTab.current = tab;
  }, [tab, sortedBins.length, communityTasks.length, loading, communityLoading]);

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user) router.replace("/");
    });
  }, [router]);

  useEffect(() => {
    if (searchParams.get("join") === "1") {
      setShowJoinModal(true);
    }
  }, [searchParams]);

  useEffect(() => {
    const tabParam = searchParams.get("tab");
    if (tabParam && (tabParam === "journal" || tabParam === "community")) {
      setTab(tabParam);
      if (typeof window !== 'undefined') {
        localStorage.setItem('mainTab', tabParam);
      }
    }
  }, [searchParams]);

  // Start camera scan
  const startCamera = async () => {
    setScanError("");
    setScanning(true);
    try {
      if (!html5QrCodeRef.current) {
        html5QrCodeRef.current = new Html5Qrcode(qrRegionId);
      }
      await html5QrCodeRef.current.start(
        { facingMode: "environment" },
        {
          fps: 10,
          qrbox: { width: 250, height: 250 },
        },
        (decodedText: string) => {
          // Extract bin ID from the scanned URL
          const match = decodedText.match(/\/bin\/([a-zA-Z0-9\-]+)/);
          if (match && match[1]) {
            setJoinBinId(match[1]);
            setJoinInput(decodedText);
            setShowScanner(false);
            setScanning(false);
            html5QrCodeRef.current?.stop();
          } else {
            setScanError("Invalid QR code format");
            setScanning(false);
          }
        },
        (err: unknown) => {
          // Ignore scan errors (happens frequently)
        }
      );
    } catch (err: any) {
      setScanError("Camera error: " + (err?.message || err));
      setScanning(false);
    }
  };

  // Stop camera scan
  const stopCamera = async () => {
    setScanning(false);
    try {
      await html5QrCodeRef.current?.stop();
    } catch {}
  };

  // Clean up on unmount
  useEffect(() => {
    return () => {
      html5QrCodeRef.current?.stop().catch(() => {});
      html5QrCodeRef.current?.clear().catch(() => {});
    };
  }, []);

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
      fetchCommunityTasks();
    }
  }, [tab]);

  // Helper to capitalize status
  const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);
  //Helper for Urgency 
  const getUrgencyStyle = (urgency: string) => {
  switch (urgency?.toLowerCase()) {
    case 'high':
      return 'bg-[#E8B5B5] text-[#6D2222]';
    case 'normal':
      return 'bg-[#F0E1A6] text-[#694F00]';
    case 'low':
    default:
      return 'bg-[#DCE8E1] text-[#2B2B2B]';
  }
};

  // Helper to get status color
  const statusColor = (status: string) => {
  if (status === 'open') return 'bg-[#FAD4D4] text-[#6D2222]';          // soft red
  if (status === 'accepted') return 'bg-[#CBE7B5] text-[#2B2B2B]';      // soft green
  return 'bg-[#F3F3F3] text-[#5A5A5A]';                                 // neutral gray
};

  // Accept/Complete logic (API calls)
  const handleAcceptTask = async (taskId: string) => {
    const { data: { session } } = await supabase.auth.getSession();
    const token = session?.access_token;
    await fetch(`/api/tasks/${taskId}/accept`, {
      method: 'POST',
      headers: {
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      }
    });
    if (tab === 'community') fetchCommunityTasks();
  };
  const handleCompleteTask = async (taskId: string) => {
    const { data: { session } } = await supabase.auth.getSession();
    const token = session?.access_token;
    await fetch(`/api/tasks/${taskId}/complete`, {
      method: 'POST',
      headers: {
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      }
    });
    if (tab === 'community') fetchCommunityTasks();
  };

  // Add fetchCommunityTasks function
  const fetchCommunityTasks = async () => {
    setCommunityLoading(true);
    setCommunityError("");
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
    const memberBinIds = memberships?.map((m: any) => m.bin_id) || [];
    
    // ALSO get bins user owns
    const { data: ownedBins } = await supabase
      .from("bins")
      .select("id")
      .eq("user_id", user.data.user.id);
    const ownedBinIds = ownedBins?.map((b: any) => b.id) || [];

    // Combine and deduplicate
    const binIds = Array.from(new Set([...memberBinIds, ...ownedBinIds]));
    // const binIds = memberships?.map((m: any) => m.bin_id) || [];
    // Get tasks for those bins
    let tasks: any[] = [];
    if (binIds.length > 0) {
      const { data: binTasks, error: taskError } = await supabase
        .from("tasks")
        .select("*, profiles:user_id(id, first_name, last_name), accepted_by_profile:accepted_by(id, first_name, last_name)")
        .in("bin_id", binIds)
        .order("created_at", { ascending: false });
      if (taskError) {
        setCommunityError(taskError.message);
        setCommunityLoading(false);
        return;
      }
      tasks = binTasks || [];
    }
    // Always fetch all tasks posted by the user, regardless of membership
    const { data: myTasks, error: myTasksError } = await supabase
      .from("tasks")
      .select("*, profiles:user_id(id, first_name, last_name), accepted_by_profile:accepted_by(id, first_name, last_name)")
      .eq("user_id", user.data.user.id)
      .order("created_at", { ascending: false });
    if (myTasksError) {
      setCommunityError(myTasksError.message);
      setCommunityLoading(false);
      return;
    }
    // Merge and deduplicate by task id
    const allTasks = [...tasks, ...myTasks].reduce((acc, t) => {
      if (!acc.find((x: any) => x.id === t.id)) acc.push(t);
      return acc;
    }, []);
    setCommunityTasks(allTasks);
    setCommunityLoading(false);
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
      // Force a full reload after joining
      window.location.reload();
    } catch (e: any) {
      setJoinError(e.message || "Failed to join bin");
    }
    setJoinLoading(false);
  };

  // Split tasks
  const newTasks = communityTasks.filter(t => t.status === 'open');
  const ongoingTasks = communityTasks.filter(t => t.status === 'accepted' && t.accepted_by === currentUserId);

  // 1. Add a helper to filter tasks posted by the current user
  const myTasks = communityTasks.filter(t => t.user_id === currentUserId);

  // 2. Add a delete handler
  const handleDeleteTask = async (taskId: string) => {
    if (!window.confirm('Are you sure you want to delete this task? This action cannot be undone.')) return;
    const { data: { session } } = await supabase.auth.getSession();
    const token = session?.access_token;
    await fetch(`/api/tasks?id=${taskId}`, {
      method: 'DELETE',
      headers: {
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      }
    });
    if (tab === 'community') fetchCommunityTasks();
    setOpenTask(null);
  };

  // Add logic to fetch currentUserProfile (if you have profile info)
  useEffect(() => {
    const fetchProfile = async () => {
      const user = await supabase.auth.getUser();
      const userId = user.data.user?.id;
      if (userId) {
        const { data } = await supabase.from('profiles').select('*').eq('id', userId).single();
        setCurrentUserProfile(data);
      }
    };
    fetchProfile();
  }, []);

  // Add a helper to get bin name from ID
  const [fetchedBinName, setFetchedBinName] = useState<string | null>(null);

  // Watch joinBinId and fetch name if not found locally
  useEffect(() => {
    if (!joinBinId) {
      setFetchedBinName(null);
      return;
    }
    const localName = bins.find(b => b.id === joinBinId)?.name;
    if (localName) {
      setFetchedBinName(null);
      return;
    }
    // Fetch from backend
    const fetchName = async () => {
      const { data, error } = await supabase.from('bins').select('name').eq('id', joinBinId).single();
      if (data && data.name) setFetchedBinName(data.name);
      else setFetchedBinName(null);
    };
    fetchName();
  }, [joinBinId, bins]);

  const getBinNameById = (id: string) => {
    const bin = bins.find(b => b.id === id);
    return bin ? bin.name : fetchedBinName;
  };

  const [copiedQR, setCopiedQR] = useState(false);
  const [copiedShare, setCopiedShare] = useState(false);
  const handleCopyQR = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedQR(true);
    setTimeout(() => setCopiedQR(false), 1200);
  };
  const handleCopyShare = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedShare(true);
    setTimeout(() => setCopiedShare(false), 1200);
  };

  // Show modal when user has no bins (but only after loading is false)
  useEffect(() => {
    if (!loading && sortedBins.length === 0) {
      setShowWelcomeModal(true);
    } else {
      setShowWelcomeModal(false);
      setShowSpotlight(false);
    }
  }, [loading, sortedBins.length]);

  // Confetti burst when modal appears (3s, staggered)
  useEffect(() => {
    if (showWelcomeModal && confettiRef.current) {
      const el = confettiRef.current;
      el.innerHTML = '';
      for (let i = 0; i < 36; i++) {
        setTimeout(() => {
          const span = document.createElement('span');
          span.textContent = ['🎉','🌱','🥳','🪱','🍃','🪴'][Math.floor(Math.random()*6)];
          span.style.position = 'absolute';
          span.style.left = Math.random()*100 + '%';
          span.style.top = Math.random()*40 + 20 + '%';
          span.style.fontSize = (Math.random()*1.5+1.5) + 'rem';
          span.style.transform = `rotate(${Math.random()*360}deg)`;
          span.style.opacity = '0.85';
          el.appendChild(span);
          setTimeout(() => { span.style.transition = 'all 2.2s cubic-bezier(.4,2,.6,1)'; span.style.top = (parseFloat(span.style.top)+30)+'%'; span.style.opacity = '0'; }, 50);
          setTimeout(() => { el.removeChild(span); }, 2300);
        }, Math.random()*2200);
      }
    }
  }, [showWelcomeModal]);

  // Calculate spotlight position after modal closes and on scroll/resize
  useEffect(() => {
    function updateSpotlight() {
      if (showSpotlight && actionButtonsRef.current) {
        const rect = actionButtonsRef.current.getBoundingClientRect();
        setSpotlightRect({
          top: rect.top - 24,
          left: rect.left - 16,
          width: rect.width + 32,
          height: rect.height + 48
        });
      } else {
        setSpotlightRect(null);
      }
    }
    updateSpotlight();
    if (showSpotlight) {
      window.addEventListener('scroll', updateSpotlight);
      window.addEventListener('resize', updateSpotlight);
      return () => {
        window.removeEventListener('scroll', updateSpotlight);
        window.removeEventListener('resize', updateSpotlight);
      };
    }
  }, [showSpotlight]);

  // Add a helper for health status pill color
function getHealthColor(status: string): React.CSSProperties {
  switch (status) {
    case "Critical":
      return { background: '#E8B5B5', color: '#6D2222' };
    case "Healthy":
      return { background: '#CBE7B5', color: '#2B2B2B' }; 
    case "Needs Attention":
      return { background: '#F0E1A6', color: '#694F00' }; 
    default:
      return { background: '#E6E6E6', color: '#5A5A5A' };
  }
}

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
          {/* Only show header buttons if user has bins */}
          {sortedBins.length > 0 && (
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
                <Avatar className="w-8 h-8 border-2 border-[#00796B] rounded-full">
                  <AvatarImage src={currentUserProfile?.avatar_url || "/default-profile.png"} alt="Profile" />
                  <AvatarFallback><User className="w-5 h-5 text-gray-400" /></AvatarFallback>
                </Avatar>
              </Button>
            </div>
          )}
        </div>
        <Tabs value={tab} onValueChange={handleTabChange} className="w-full mt-2">
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
        <Tabs value={tab} onValueChange={handleTabChange} className="w-full">
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
                {/* Only show Add New Piles if user has bins */}
                {sortedBins.length > 0 && (
                  <Button
                    className="bg-[#00796B] text-white px-4 py-2 rounded-lg font-semibold hover:bg-[#005B4F]"
                    onClick={() => router.push('/add-bin')}
                  >
                    Add New Bin
                  </Button>
                )}
              </div>
              <div className="bg-white rounded-lg border border-[#E0E0E0] divide-y divide-[#F3F3F3]">
                {loading && <div className="p-4 text-center">Loading bins...</div>}
                {error && <div className="p-4 text-red-600 text-sm text-center">{error}</div>}
                {sortedBins.map((bin) => (
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
                          {/* Health status badge */}
                          <span
                            className="px-2 py-1 rounded-full font-semibold text-xs"
                            style={getHealthColor(bin.health_status)}
                          >
                            {bin.health_status || 'Healthy'}
                          </span>

                          {/* Stat readings, commented out portion is in case we need it*/}
                          <div className="flex flex-wrap justify-end gap-2 text-xs text-gray-500 px-2">
                            <div className="flex items-center gap-1">
                              {/* <Thermometer className="w-3 h-3 text-gray-400" /> */}
                              <span className="ml-0.5">{bin.latest_temperature ? `${bin.latest_temperature}°C` : '-°C'}</span>
                            </div>
                            {/* <div className="flex items-center gap-1">
                              <Droplets className="w-3 h-3 text-gray-400" />
                              <span className="ml-0.5">{bin.latest_moisture || '-'}</span>
                            </div>
                            <div className="flex items-center gap-1">
                              <RefreshCw className="w-3 h-3 text-gray-400" />
                              <span className="ml-0.5">{bin.latest_flips ?? '-'}</span>
                            </div> */}
                          </div>
                        </div>

                  </div>
                ))}
                {sortedBins.length === 0 && !loading && (
                  <div className="flex flex-col items-center justify-center pt-2 pb-16 gap-6 min-h-[350px]">
                    <img
                      src="/default_compost_image.jpg"
                      alt="Wow, it's empty!"
                      className="w-80 h-80 object-contain mb-2 opacity-80"
                    />
                    <div className="text-xl font-bold text-[#00796B] mb-1">Wow, it's empty!</div>
                    <div className="text-gray-500 text-center max-w-xs mb-4">
                      You don't have any compost bins yet.<br/>
                      <span className="font-semibold">Get started by joining an existing bin or creating a new one!</span>
                    </div>
                    <div ref={actionButtonsRef} className="flex flex-col items-center gap-2 w-full max-w-xs">
                      <Button
                        className="bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base w-full"
                        onClick={() => setShowJoinModal(true)}
                      >
                        Join an Existing Bin
                      </Button>
                      <div className="text-gray-400 font-semibold my-1">OR</div>
                      <Button
                        variant="outline"
                        className="border-[#00796B] text-[#00796B] rounded-lg py-2 font-semibold text-base w-full bg-transparent hover:bg-[#F3F3F3]"
                        onClick={() => router.push('/add-bin')}
                      >
                        Create a New Bin
                      </Button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </TabsContent>
          <TabsContent value="community">
  <div className="p-4 space-y-8">

    <div className="text-xs text-gray-500 mb-2">
      Click on a task to see more details.
    </div>

    {/* New Tasks */}
    <div>
      <h3 className="text-lg font-bold mb-2 text-[#00796B]">New Tasks</h3>
      {newTasks.length === 0 ? (
        <div className="text-gray-400 text-sm">No new tasks.</div>
      ) : (
        newTasks.map(task => {
          const bin = bins.find(b => b.id === task.bin_id);
          return (
            <div
              key={task.id}
              className="bg-white border border-[#E0E0E0] rounded-xl p-4 mb-3 shadow-sm hover:shadow-md transition cursor-pointer"
              onClick={() => setOpenTask(task)}
            >
              <div className="flex justify-between items-start gap-4">
                <div className="flex-1 space-y-1">
                  <div className="font-semibold text-sm text-[#00796B]">{task.description}</div>
                  <div className="text-xs text-gray-500">
                    Bin: {bin ? bin.name : 'Unknown'}
                    {task.user_id === currentUserId && (
                      <>
                        {' '}• Status: <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-[#DCE8E1] text-[#2B2B2B]">
                          {capitalize(task.status)}
                        </span>
                      </>
                    )}
                  </div>
                  <div className="text-xs text-gray-500">
                    Posted by: {task.user_id === currentUserId ? 'You' : task.profiles?.first_name || 'Unknown'}
                  </div>
                </div>

                <div className="flex flex-col items-end gap-1 text-xs">
                  <span className="text-[11px] text-gray-400">Urgency</span>
                  <span className={`px-2 py-1 rounded-full font-medium ${getUrgencyStyle(task.urgency)}`}>
                    {capitalize(task.urgency)}
                  </span>
                </div>
              </div>
            </div>
          );
        })
      )}
    </div>

    {/* Ongoing Tasks */}
    <div>
      <h3 className="text-lg font-bold mb-2 text-[#00796B]">Ongoing Tasks</h3>
      {ongoingTasks.length === 0 ? (
        <div className="text-gray-400 text-sm">No ongoing tasks.</div>
      ) : (
        ongoingTasks.map(task => {
          const bin = bins.find(b => b.id === task.bin_id);
          return (
            <div
              key={task.id}
              className="bg-white border border-[#E0E0E0] rounded-xl p-4 mb-3 shadow-sm hover:shadow-md transition cursor-pointer"
              onClick={() => setOpenTask(task)}
            >
              <div className="flex justify-between items-start gap-4">
                <div className="flex-1 space-y-1">
                  <div className="font-semibold text-sm text-[#00796B]">{task.description}</div>
                  <div className="text-xs text-gray-500">
                    Bin: {bin ? bin.name : 'Unknown'}
                    {task.user_id === currentUserId && (
                      <>
                        {' '}• Status: <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-[#DCE8E1] text-[#2B2B2B]">
                          {capitalize(task.status)}
                        </span>
                      </>
                    )}
                  </div>
                  <div className="text-xs text-gray-500">
                    Posted by: {task.user_id === currentUserId ? 'You' : task.profiles?.first_name || 'Unknown'}
                  </div>
                  <div className="text-xs text-[#00796B] font-medium">Accepted by: You</div>
                </div>

                <div className="flex flex-col items-end gap-1 text-xs">
                  <span className="text-[11px] text-gray-400">Urgency</span>
                  <span className={`px-2 py-1 rounded-full font-medium ${getUrgencyStyle(task.urgency)}`}>
                    {capitalize(task.urgency)}
                  </span>
                </div>
              </div>
            </div>
          );
        })
      )}
    </div>

    {/* My Tasks */}
    <div>
      <h3 className="text-lg font-bold mb-2 text-[#00796B]">Tasks posted by me</h3>
      {myTasks.length === 0 ? (
        <div className="text-gray-400 text-sm">You haven't posted any tasks.</div>
      ) : (
        myTasks.map(task => {
          const bin = bins.find(b => b.id === task.bin_id);
          return (
            <div
              key={task.id}
              className="bg-white border border-[#E0E0E0] rounded-xl p-4 mb-3 shadow-sm hover:shadow-md transition flex justify-between items-start"
              onClick={() => setOpenTask(task)}
            >
              <div className="flex-1 space-y-1">
                <div className="font-semibold text-sm text-[#00796B]">{task.description}</div>
                <div className="text-xs text-gray-500">
                  Bin: {bin ? bin.name : 'Unknown'} • Status:{" "}
                  <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-[#DCE8E1] text-[#2B2B2B]">
                    {capitalize(task.status)}
                  </span>
                </div>
              </div>
              <div className="flex items-start gap-2 ml-2">
                <span className={`px-2 py-1 rounded-full font-medium text-xs ${getUrgencyStyle(task.urgency)}`}>
                  {capitalize(task.urgency)}
                </span>
                <button
                  className="text-red-500 hover:text-red-700 mt-1"
                  title="Delete Task"
                  onClick={(e) => {
                    e.stopPropagation();
                    handleDeleteTask(task.id);
                  }}
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none"
                    viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 
                      4v6m4-6v6M1 7h22M8 7V5a2 2 0 012-2h4a2 2 0 012 2v2" />
                  </svg>
                </button>
              </div>
            </div>
          );
        })
      )}
    </div>

  </div>
</TabsContent>


        </Tabs>
      </div>
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
              placeholder="Paste bin link here"
              value={joinInput}
              onChange={e => handleJoinInput(e.target.value)}
            />
            <div className="flex gap-2 mb-4">
              <Button 
                className="flex-1 bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base flex items-center justify-center gap-2"
                onClick={() => setShowScanner(true)}
              >
                <Camera className="w-4 h-4" />
                Scan QR Code
              </Button>
            </div>
            {joinBinId && !joinPrompt && (
              <Button className="bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base w-full" onClick={() => setJoinPrompt(true)}>
                Join Bin
              </Button>
            )}
            {joinPrompt && (
              <div className="w-full flex flex-col items-center">
                <div className="mb-2 text-[#00796B]">
                  Join bin <span className="font-bold">{getBinNameById(joinBinId) || joinBinId}</span>
                  {getBinNameById(joinBinId) && (
                    <span className="text-xs text-gray-500 ml-2">({joinBinId})</span>
                  )}?
                </div>
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
      {showScanner && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative flex flex-col items-center">
            <button
              className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
              onClick={() => {
                setShowScanner(false);
                stopCamera();
              }}
              aria-label="Close"
              style={{ fontSize: '2rem', lineHeight: '2rem' }}
            >
              ×
            </button>
            <h2 className="text-xl font-bold mb-4 text-[#00796B]">Scan QR Code</h2>
            <div className="mb-4">
              {!scanning ? (
                <Button className="flex items-center gap-2 justify-center mb-4" onClick={startCamera}>
                  <Camera className="w-4 h-4" /> Start Camera Scan
                </Button>
              ) : (
                <Button className="flex items-center gap-2 justify-center mb-4" onClick={stopCamera} variant="destructive">
                  Stop Camera
                </Button>
              )}
            </div>
            <div id={qrRegionId} className="mb-4 mx-auto" style={{ width: 260, minHeight: 260 }} />
            {scanError && <div className="text-red-600 text-sm mt-2">{scanError}</div>}
            <div className="text-center text-sm text-gray-600 mt-2">
              Point your camera at a compost bin QR code
            </div>
          </div>
        </div>
      )}
      {openTask && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative flex flex-col items-center">
            <button
              className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
              onClick={() => setOpenTask(null)}
              aria-label="Close"
              style={{ fontSize: '2rem', lineHeight: '2rem' }}
            >
              ×
            </button>
            <h2 className="text-xl font-bold mb-2 text-[#00796B]">{openTask.description}</h2>
            <div className="mb-2 text-gray-600 text-sm">Bin: {bins.find(b => b.id === openTask.bin_id)?.name || 'Unknown'}</div>
            <div className="mb-2 text-gray-600 text-sm">Urgency: {openTask.urgency}</div>
            <div className="mb-2 text-gray-600 text-sm">Effort: {openTask.effort}</div>
            <div className="mb-2 text-gray-600 text-sm">Status: <span className={`px-2 py-1 rounded-full text-xs font-medium ${statusColor(openTask.status)}`}>{capitalize(openTask.status)}</span></div>
            <div className="mb-2 text-gray-600 text-sm">Posted: {openTask.created_at ? new Date(openTask.created_at).toLocaleString() : 'Unknown'}</div>
            <div className="mb-2 text-gray-600 text-sm">
              Posted by: {
                openTask.user_id === currentUserId
                  ? 'You'
                  : (openTask.profiles?.first_name || openTask.user_id)
              }
            </div>
            {openTask.accepted_by && openTask.accepted_at && (
              <div className="mb-2 text-gray-600 text-sm">
                Accepted by: {
                  openTask.accepted_by === currentUserId
                    ? 'You'
                    : (openTask.accepted_by_profile?.first_name || openTask.accepted_by)
                } on {new Date(openTask.accepted_at).toLocaleString()}
              </div>
            )}
            {openTask.photo_url && <img src={openTask.photo_url} alt="Task" className="mb-2 rounded-lg max-h-40" />}
            <div className="flex gap-2 mt-4">
              {openTask.status === 'open' && openTask.accepted_by !== currentUserId && (
                <Button className="bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base" onClick={() => { handleAcceptTask(openTask.id); setOpenTask(null); }}>
                  Accept
                </Button>
              )}
              {openTask.status === 'accepted' && openTask.accepted_by === currentUserId && (
                <Button className="bg-green-700 text-white rounded-lg py-2 font-semibold text-base" onClick={() => { handleCompleteTask(openTask.id); setOpenTask(null); }}>
                  Mark as Completed
                </Button>
              )}
              {/* Show Delete button for any status if user is owner */}
              {openTask.user_id === currentUserId && (
                <Button className="bg-red-600 text-white rounded-lg py-2 font-semibold text-base" onClick={() => handleDeleteTask(openTask.id)}>
                  Delete
                </Button>
              )}
              <Button variant="outline" className="rounded-lg py-2 font-semibold text-base" onClick={() => setOpenTask(null)}>
                Close
              </Button>
            </div>
          </div>
        </div>
      )}
      {/* Community Intro Modal */}
      {showCommunityIntro && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-6 shadow-lg max-w-md w-full relative flex flex-col items-center">
            <button
              className="absolute top-3 right-3 text-3xl text-gray-500 hover:text-gray-800 focus:outline-none"
              onClick={() => setShowCommunityIntro(false)}
              aria-label="Close"
              style={{ fontSize: '2rem', lineHeight: '2rem' }}
            >
              ×
            </button>
            <h2 className="text-xl font-bold mb-4 text-[#00796B]">Welcome to the Community!</h2>
            <div className="text-gray-700 text-base mb-6 text-center">
              Here you can help other composters by accepting and completing tasks, or post your own tasks for others to assist with.<br/>
              <span className="font-semibold">Join or create a bin to start participating!</span>
            </div>
            <Button className="bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base w-full" onClick={() => setShowCommunityIntro(false)}>
              Got it!
            </Button>
          </div>
        </div>
      )}
      {/* Welcome Modal */}
      {!loading && showWelcomeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl p-8 shadow-lg max-w-md w-full relative flex flex-col items-center">
            <div ref={confettiRef} style={{position:'absolute',left:0,top:0,width:'100%',height:'100%',pointerEvents:'none',zIndex:2}} />
            <h2 className="text-2xl font-bold mb-4 text-[#00796B] text-center">Welcome to CompostKaki!</h2>
            <div className="text-gray-700 text-base mb-6 text-center max-w-xs">
              CompostKaki helps you track, manage, and collaborate on composting projects with your community.<br/><br/>
              <span className="font-semibold">To get started, join an existing bin or create a new one below!</span>
            </div>
            <Button className="bg-[#00796B] text-white rounded-lg py-2 font-semibold text-base w-full z-10" onClick={() => { setShowWelcomeModal(false); setShowSpotlight(true); }}>
              Let's Go!
            </Button>
          </div>
        </div>
      )}
      {/* Spotlight Overlay */}
      {showSpotlight && sortedBins.length === 0 && spotlightRect && (
        <div className="fixed inset-0 z-40 pointer-events-auto" onClick={() => setShowSpotlight(false)}>
          <div style={{
            position: 'fixed',
            top: 0, left: 0, width: '100vw', height: '100vh',
            background: `radial-gradient(circle at ${spotlightRect.left+spotlightRect.width/2}px ${spotlightRect.top+spotlightRect.height/2}px, rgba(0,0,0,0) 0, rgba(0,0,0,0) ${(spotlightRect.width+spotlightRect.height)/3}px, rgba(0,0,0,0.7) ${(spotlightRect.width+spotlightRect.height)/2.2}px, rgba(0,0,0,0.7) 100%)`,
            transition: 'background 0.3s',
            pointerEvents: 'auto',
            zIndex: 40
          }} />
          <div style={{
            position: 'fixed',
            top: spotlightRect.top,
            left: spotlightRect.left,
            width: spotlightRect.width,
            height: spotlightRect.height,
            borderRadius: '1rem',
            border: '4px solid #FFD600',
            boxShadow: '0 0 32px 8px #FFD60099',
            pointerEvents: 'none',
            transition: 'all 0.3s',
            zIndex: 41,
            animation: 'pulse 1.2s infinite alternate'
          }} />
          <style>{`@keyframes pulse { 0% { box-shadow: 0 0 32px 8px #FFD60099; } 100% { box-shadow: 0 0 48px 16px #FFD60055; } }`}</style>
        </div>
      )}
    </div>
  );
} 