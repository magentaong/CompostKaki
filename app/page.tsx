"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Progress } from "@/components/ui/progress"
import { Separator } from "@/components/ui/separator"
import {
  QrCode,
  Plus,
  Thermometer,
  Droplets,
  RotateCcw,
  Leaf,
  Coffee,
  MessageCircle,
  Star,
  Clock,
  Users,
  BookOpen,
  HelpCircle,
  Lightbulb,
  ArrowLeft,
  Send,
  Camera,
  MapPin,
  TrendingUp,
  Award,
  Search,
  Filter,
  Bell,
  Heart,
  Share2,
  Bookmark,
  Eye,
  Calendar,
  Target,
  Zap,
  CheckCircle2,
  Info,
  ArrowRight,
  Play,
  Download,
  ScaleIcon as Scales,
  Sun,
  CloudRain,
  Bug,
  Recycle,
  Home,
  Building,
  TreePine,
  AlertTriangle,
  CheckCircle,
} from "lucide-react"
import { supabase } from "@/lib/supabaseClient"
import GuideListComp from "@/app/components/GuideList"
import GuideDetailComp from "@/app/components/GuideDetail"
import { useRouter } from "next/navigation"

type Screen =
  | "home"
  | "scanner"
  | "journal"
  | "add-entry"
  | "forum"
  | "question"
  | "profile"
  | "guides"
  | "guide-detail"
  | "tips"

function getInitials(name?: string, email?: string) {
  if (name && name.trim().length > 0) {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase();
  }
  if (email && email.length > 0) {
    return email[0].toUpperCase();
  }
  return 'U';
}

export default function CompostKaki() {
  const [currentScreen, setCurrentScreen] = useState<Screen>("home")
  const [selectedPile, setSelectedPile] = useState<string>("")
  const [selectedGuide, setSelectedGuide] = useState<string>("")
  const [isLoading, setIsLoading] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")
  const [authView, setAuthView] = useState<'sign-in' | 'sign-up'>("sign-in")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [firstName, setFirstName] = useState("")
  const [lastName, setLastName] = useState("")
  const [session, setSession] = useState<any>(null)
  const [authError, setAuthError] = useState<string>("")
  const [journalEntries, setJournalEntries] = useState<any[]>([])
  const [newEntryContent, setNewEntryContent] = useState("")
  const [journalLoading, setJournalLoading] = useState(false)
  const [journalError, setJournalError] = useState("")
  const [pilesLoading, setPilesLoading] = useState(false)
  const [pilesError, setPilesError] = useState("")
  const [forumLoading, setForumLoading] = useState(false)
  const [forumError, setForumError] = useState("")
  const [pileEntries, setPileEntries] = useState<any[]>([])
  const [pileEntriesLoading, setPileEntriesLoading] = useState(false)
  const [pileEntriesError, setPileEntriesError] = useState("")
  const [newPileName, setNewPileName] = useState("")
  const [newPileLocation, setNewPileLocation] = useState("")
  const [newPileImage, setNewPileImage] = useState("")
  const [newPileDescription, setNewPileDescription] = useState("")
  const [addPileLoading, setAddPileLoading] = useState(false)
  const [addPileError, setAddPileError] = useState("")
  const [newForumTitle, setNewForumTitle] = useState("")
  const [newForumContent, setNewForumContent] = useState("")
  const [addForumLoading, setAddForumLoading] = useState(false)
  const [addForumError, setAddForumError] = useState("")
  const [piles, setPiles] = useState<any[]>([])
  const [forumPosts, setForumPosts] = useState<any[]>([])
  const [guides, setGuides] = useState<any[]>([]);
  const [tips, setTips] = useState<any[]>([]);
  const [guidesLoading, setGuidesLoading] = useState(false);
  const [tipsLoading, setTipsLoading] = useState(false);
  const [guidesError, setGuidesError] = useState("");
  const [tipsError, setTipsError] = useState("");
  // Add state for guide search, filter, and like
  const [guideSearch, setGuideSearch] = useState("");
  const [guideFilter, setGuideFilter] = useState("All");
  const [guideLikes, setGuideLikes] = useState<{ [id: string]: number }>({});
  const [showNotifications, setShowNotifications] = useState(false);
  const [step, setStep] = useState<"email" | "signin" | "signup">("email");
  const [emailExists, setEmailExists] = useState<boolean | null>(null);

  const router = useRouter();

  // Redirect logged-in users to /main
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (data.user) router.replace('/main');
    });
  }, [router]);

  const handleEmailCheck = async () => {
    setIsLoading(true);
    setAuthError("");

    try {
      const res = await fetch("/api/check-email", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });

      const result = await res.json();

      if (result.exists) {
        setStep("signin");
      } else {
        setStep("signup");
      }
    } catch (e) {
      setAuthError("Something went wrong. Try again.");
      setStep("signup");
    }

    setIsLoading(false);
  };


    const handleSignUp = async () => {
      setIsLoading(true)
      setAuthError("")
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { first_name: firstName, last_name: lastName }
        }
      });
      if (error) {
        setAuthError(error.message);
        setIsLoading(false);
        return;
      }
      // Insert into profiles table
      const userId = data?.user?.id;
      if (userId) {
        await supabase.from('profiles').upsert({
          id: userId,
          first_name: firstName,
          last_name: lastName
        });
      }
      setIsLoading(false);
      if (!error) router.push("/main")
    }

    const handleSignIn = async () => {
      setIsLoading(true)
      setAuthError("")
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) setAuthError(error.message)
      setIsLoading(false)
      if (!error) router.push("/main")
    }

    const handleSignOut = async () => {
      await supabase.auth.signOut()
      setSession(null)
  }

  // Fetch journal entries from backend API
  const fetchJournalEntries = async () => {
    if (!session?.access_token) return
    setJournalLoading(true)
    setJournalError("")
    try {
      const res = await fetch("/api/journal", {
        headers: { Authorization: `Bearer ${session.access_token}` },
      })
      const data = await res.json()
      if (res.ok) {
        setJournalEntries(data.entries)
      } else {
        setJournalError(data.error || "Failed to fetch journal entries")
      }
    } catch (e) {
      setJournalError("Network error")
    }
    setJournalLoading(false)
  }

  useEffect(() => {
    if (session?.access_token) {
      fetchJournalEntries()
    }
    // eslint-disable-next-line
  }, [session])

  // Add new journal entry via backend API
  const handleAddJournalEntry = async () => {
    if (!session?.access_token || !newEntryContent.trim()) return
    setJournalLoading(true)
    setJournalError("")
    try {
      const res = await fetch("/api/journal", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ content: newEntryContent }),
      })
      const data = await res.json()
      if (res.ok) {
        setNewEntryContent("")
        fetchJournalEntries()
        setCurrentScreen("journal")
      } else {
        setJournalError(data.error || "Failed to add entry")
      }
    } catch (e) {
      setJournalError("Network error")
    }
    setJournalLoading(false)
  }

  // Fetch piles
  const fetchPiles = async () => {
    setPilesLoading(true)
    setPilesError("")
    try {
      const res = await fetch("/api/piles")
      const data = await res.json()
      if (res.ok) {
        setPiles(data.piles)
      } else {
        setPilesError(data.error || "Failed to fetch piles")
      }
    } catch (e) {
      setPilesError("Network error")
    }
    setPilesLoading(false)
  }

  // Fetch forum posts
  const fetchForumPosts = async () => {
    setForumLoading(true)
    setForumError("")
    try {
      const res = await fetch("/api/community/posts")
      const data = await res.json()
      if (res.ok) {
        setForumPosts(data.posts)
      } else {
        setForumError(data.error || "Failed to fetch forum posts")
      }
    } catch (e) {
      setForumError("Network error")
    }
    setForumLoading(false)
  }

  // Fetch pile entries for selected pile
  const fetchPileEntries = async (pileId: string) => {
    setPileEntriesLoading(true)
    setPileEntriesError("")
    try {
      const res = await fetch(`/api/piles/entries?pile_id=${pileId}`)
      const data = await res.json()
      if (res.ok) {
        setPileEntries(data.entries)
      } else {
        setPileEntriesError(data.error || "Failed to fetch pile entries")
      }
    } catch (e) {
      setPileEntriesError("Network error")
    }
    setPileEntriesLoading(false)
  }

  // Add new pile
  const handleAddPile = async () => {
    if (!session?.access_token || !newPileName.trim()) return
    setAddPileLoading(true)
    setAddPileError("")
    try {
      const res = await fetch("/api/piles", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ name: newPileName, location: newPileLocation, image: newPileImage, description: newPileDescription }),
      })
      const data = await res.json()
      if (res.ok) {
        setNewPileName("")
        setNewPileLocation("")
        setNewPileImage("")
        setNewPileDescription("")
        fetchPiles()
      } else {
        setAddPileError(data.error || "Failed to add pile")
      }
    } catch (e) {
      setAddPileError("Network error")
    }
    setAddPileLoading(false)
  }

  // Add new forum post
  const handleAddForumPost = async () => {
    if (!session?.access_token || !newForumTitle.trim() || !newForumContent.trim()) return
    setAddForumLoading(true)
    setAddForumError("")
    try {
      const res = await fetch("/api/community/posts", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ title: newForumTitle, content: newForumContent }),
      })
      const data = await res.json()
      if (res.ok) {
        setNewForumTitle("")
        setNewForumContent("")
        fetchForumPosts()
      } else {
        setAddForumError(data.error || "Failed to add post")
      }
    } catch (e) {
      setAddForumError("Network error")
    }
    setAddForumLoading(false)
  }

  // Fetch data on mount
  useEffect(() => {
    fetchPiles()
    fetchForumPosts()
    fetchGuides()
    fetchTips()
  }, [])

  // Fetch pile entries when selectedPile changes
  useEffect(() => {
    if (selectedPile) fetchPileEntries(selectedPile)
  }, [selectedPile])

  // Fetch guides
  const fetchGuides = async () => {
    setGuidesLoading(true);
    setGuidesError("");
    try {
      const res = await fetch("/api/guides");
      const data = await res.json();
      if (res.ok) {
        setGuides(data.guides);
      } else {
        setGuidesError(data.error || "Failed to fetch guides");
      }
    } catch (e) {
      setGuidesError("Network error");
    }
    setGuidesLoading(false);
  };

  // Fetch tips
  const fetchTips = async () => {
    setTipsLoading(true);
    setTipsError("");
    try {
      const res = await fetch("/api/tips");
      const data = await res.json();
      if (res.ok) {
        setTips(data.tips);
      } else {
        setTipsError(data.error || "Failed to fetch tips");
      }
    } catch (e) {
      setTipsError("Network error");
    }
    setTipsLoading(false);
  };

  const handleScan = () => {
    // TODO: Implement scan logic or leave empty for now
  };

  // Like handler for guides
  const handleGuideLike = (id: string) => {
    setGuideLikes((prev) => ({ ...prev, [id]: (prev[id] || 0) + 1 }));
    // TODO: Call backend API to persist like
  };

  // Compose guides with local like state
  const guidesWithLikes = guides.map((g) => ({
    ...g,
    likes: guideLikes[g.id] !== undefined ? guideLikes[g.id] : g.likes,
  }));

  // In CompostKaki, extract user info from session:
  const userName = session?.user?.user_metadata?.name;
  const userEmail = session?.user?.email;
  const userAvatar = session?.user?.user_metadata?.avatar_url;

  if (!session) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#E6FFF3] to-[#F3F3F3]">
        <div className="w-full max-w-md bg-white rounded-xl shadow-lg p-8 flex flex-col items-center">
          <img src="/favicon.ico" alt="Logo" className="w-8 h-8 mb-2" />
          <h1 className="text-3xl font-bold text-[#00796B] mb-2">CompostKaki</h1>
          <div className="text-[#00796B] text-base mb-6 font-medium">Grow your community, one compost at a time!</div>
          

          <CardContent>
            {(step === "email" || step === "signin") && (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  step === "email" ? handleEmailCheck() : handleSignIn();
                }}
                className="space-y-4 w-full"
              >
                <div>
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    autoFocus
                  />
                </div>

                {step === "signin" && (
                  <div
                    className={`transition-all duration-300 overflow-hidden ${
                      step === "signin" ? "max-h-32 opacity-100" : "max-h-0 opacity-0"
                    }`}
                  >
                    <Label htmlFor="password" className="block mt-2">Password</Label>
                    <Input
                      id="password"
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                    />
                  </div>
                )}

                {authError && (
                  <div className="text-sm text-red-600 bg-red-50 px-2 py-1 rounded">
                    {authError}
                  </div>
                )}

                <Button
                  type="submit"
                  className="w-full bg-[#00796B] text-white hover:bg-[#005A4B] transition font-semibold"
                  disabled={isLoading}
                >
                  {isLoading
                    ? step === "email"
                      ? "Checking..."
                      : "Signing in..."
                    : step === "email"
                      ? "Continue"
                      : "Sign In"}
                </Button>

                {step === "signin" && (
                  <button
                    type="button"
                    className="mt-2 text-sm text-[#00796B] underline"
                    onClick={() => {
                      setStep("email");
                      setPassword("");
                      setAuthError("");
                    }}
                  >
                    ← Back to email
                  </button>
                )}
              </form>
            )}

            {step === "signup" && (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  handleSignUp();
                }}
                className="space-y-4 w-full"
              >
                <div className="flex gap-2">
                  <Input
                    placeholder="First Name"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    required
                  />
                  <Input
                    placeholder="Last Name"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    required
                  />
                </div>
                <div>
                  <Label htmlFor="password">Password</Label>
                  <Input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>
                {authError && <div className="text-sm text-red-600">{authError}</div>}
                <Button
                  type="submit"
                  className="w-full bg-[#00796B] text-white hover:bg-[#005A4B]"
                  disabled={isLoading}
                >
                  {isLoading ? "Signing up..." : "Sign Up"}
                </Button>
                <button
                  type="button"
                  className="mt-2 text-sm text-[#00796B] underline"
                  onClick={() => {
                    setStep("email");
                    setPassword("");
                    setAuthError("");
                  }}
                >
                  ← Back to email
                </button>
              </form>
            )}
          </CardContent>



        </div>
      </div>
    )
  }

  const renderHomeScreen = () => (
    <p> yes</p>
  )

  const renderGuidesScreen = () => (
   <p> yes</p>
  );

  const renderGuideDetailScreen = () => {
    <p> yes</p>
  };

  const renderTipsScreen = () => (
    <p> yes</p>
  )

  const renderScannerScreen = () => (
   <p> yes</p>
  )

  const renderJournalScreen = () => (
    <p> yes </p>)

  const renderAddEntryScreen = () => (
   <p> yes </p>
  )

  const renderQuestionScreen = () => (
    <p> yes</p>
  )

  const screens = {
    home: renderHomeScreen,
    scanner: renderScannerScreen,
    journal: renderJournalScreen,
    "add-entry": renderAddEntryScreen,
    forum: renderHomeScreen,
    question: renderQuestionScreen,
    profile: renderHomeScreen,
    guides: renderGuidesScreen,
    "guide-detail": renderGuideDetailScreen,
    tips: renderTipsScreen,
  }

  return screens[currentScreen]()
}
