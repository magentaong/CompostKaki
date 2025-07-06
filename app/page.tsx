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

export default function CompostConnect() {
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
  const router = useRouter();

  // Redirect logged-in users to /main
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (data.user) router.replace('/main');
    });
  }, [router]);

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

  // In CompostConnect, extract user info from session:
  const userName = session?.user?.user_metadata?.name;
  const userEmail = session?.user?.email;
  const userAvatar = session?.user?.user_metadata?.avatar_url;

  if (!session) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-lime-50 via-emerald-50 to-green-50">
      <Card className="max-w-sm w-full p-6 border border-green-200 shadow-md">
        <CardHeader>
          
          <h2 className="flex justify-center items-center gap-2 text-xl font-bold mb-2 bg-gradient-to-r from-green-700 to-emerald-600 bg-clip-text text-transparent">
            <img src="/favicon.ico" alt="Logo" className="w-8 h-8" />
            CompostConnect
          </h2>
            <Tabs
              value={authView}
              onValueChange={(v) => setAuthView(v as 'sign-in' | 'sign-up')}
              className="w-full"
            >
              <div className="flex justify-center">
                <TabsList className="grid grid-cols-2 mb-4 bg-green-100/50 p-1 rounded-lg gap-2">
                  <TabsTrigger
                    value="sign-in"
                    className="data-[state=active]:bg-white data-[state=active]:text-green-800 data-[state=active]:shadow"
                  >
                    Sign In
                  </TabsTrigger>
                  <TabsTrigger
                    value="sign-up"
                    className="data-[state=active]:bg-white data-[state=active]:text-green-800 data-[state=active]:shadow"
                  >
                    Sign Up
                  </TabsTrigger>
                </TabsList>
              </div>
            </Tabs>
          
        </CardHeader>

        <CardContent>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              authView === 'sign-in' ? handleSignIn() : handleSignUp();
            }}
            className="space-y-4"
          >
            {authView === 'sign-up' && (
              <div className="flex gap-2">
                <div className="flex-1">
                  <Label htmlFor="firstName">First Name</Label>
                  <Input
                    id="firstName"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    required
                    placeholder="First Name"
                  />
                </div>
                <div className="flex-1">
                  <Label htmlFor="lastName">Last Name</Label>
                  <Input
                    id="lastName"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    required
                    placeholder="Last Name"
                  />
                </div>
              </div>
            )}

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

            {authError && (
              <div className="text-sm text-red-600 bg-red-50 px-2 py-1 rounded">
                {authError}
              </div>
            )}

            <Button
              type="submit"
              className="w-full bg-[#96CC4F] text-white hover:bg-[#7AA840] transition font-semibold"
              disabled={isLoading}
            >
              {isLoading ? 'Loading...' : authView === 'sign-in' ? 'Sign In' : 'Sign Up'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>

    )
  }

  const renderHomeScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-emerald-50 to-teal-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-green-700 to-emerald-600 bg-clip-text text-transparent">
                CompostConnect
              </h1>
              <p className="text-sm text-green-600 font-medium">Singapore Community Network</p>
            </div>
            <div className="flex items-center gap-2">
              <Button variant="ghost" size="sm" className="relative" onClick={() => setShowNotifications(true)}>
                <Bell className="w-5 h-5 text-green-700" />
                <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full flex items-center justify-center">
                  <span className="text-xs text-white font-bold">3</span>
                </div>
              </Button>
              <Button variant="ghost" size="sm" onClick={() => router.push("/profile-settings")}>
                <Avatar className="w-6 h-6">
                  <AvatarImage src={userAvatar || undefined} />
                  <AvatarFallback className="bg-green-100 text-green-700 text-xs">
                    {getInitials(userName, userEmail)}
                  </AvatarFallback>
                </Avatar>
              </Button>
            </div>
          </div>

          <Tabs defaultValue="journal" className="w-full">
            <TabsList className="grid w-full grid-cols-2 bg-green-100/50 p-1">
              <TabsTrigger
                value="journal"
                className="flex items-center gap-2 data-[state=active]:bg-white data-[state=active]:shadow-sm"
              >
                <BookOpen className="w-4 h-4" />
                <span className="font-medium">Journal</span>
              </TabsTrigger>
              <TabsTrigger
                value="community"
                className="flex items-center gap-2 data-[state=active]:bg-white data-[state=active]:shadow-sm"
              >
                <MessageCircle className="w-4 h-4" />
                <span className="font-medium">Community</span>
              </TabsTrigger>
            </TabsList>

            <TabsContent value="journal" className="mt-0">
              <div className="p-4 space-y-6">
                {/* Quick Stats */}
                <div className="grid grid-cols-3 gap-3">
                  <Card className="bg-gradient-to-br from-green-500 to-emerald-600 text-white border-0">
                    <CardContent className="p-3 text-center">
                      <div className="text-2xl font-bold">12</div>
                      <div className="text-xs opacity-90">Active Piles</div>
                    </CardContent>
                  </Card>
                  <Card className="bg-gradient-to-br from-blue-500 to-cyan-600 text-white border-0">
                    <CardContent className="p-3 text-center">
                      <div className="text-2xl font-bold">156</div>
                      <div className="text-xs opacity-90">Volunteers</div>
                    </CardContent>
                  </Card>
                  <Card className="bg-gradient-to-br from-amber-500 to-orange-600 text-white border-0">
                    <CardContent className="p-3 text-center">
                      <div className="text-2xl font-bold">2.4T</div>
                      <div className="text-xs opacity-90">Composted</div>
                    </CardContent>
                  </Card>
                </div>

                {/* QR Scanner Button */}
                <Button
                  onClick={() => setCurrentScreen("scanner")}
                  className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-6 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200"
                >
                  <QrCode className="w-6 h-6 mr-3" />
                  <div className="text-left">
                    <div className="font-semibold">Scan QR Code</div>
                    <div className="text-sm opacity-90">Access pile journal instantly</div>
                  </div>
                </Button>

                {/* Search Bar */}
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    placeholder="Search compost piles..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-10 bg-white/70 backdrop-blur-sm border-green-200 focus:border-green-400"
                  />
                </div>

                {/* Pile Cards */}
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="font-bold text-green-800 flex items-center gap-2">
                      <TrendingUp className="w-5 h-5" />
                      Your Active Piles
                    </h3>
                    <Button variant="ghost" size="sm">
                      <Filter className="w-4 h-4" />
                    </Button>
                  </div>

                  {piles.map((pile: any) => (
                    <Card
                      key={pile.id}
                      className="cursor-pointer hover:shadow-lg transition-all duration-200 bg-white/80 backdrop-blur-sm border-green-100 hover:border-green-200"
                      onClick={() => {
                        setSelectedPile(pile.id)
                        setCurrentScreen("journal")
                      }}
                    >
                      <CardContent className="p-0">
                        <div className="flex">
                          <img
                            src={pile.image || "/placeholder.svg"}
                            alt={pile.name}
                            className="w-24 h-24 object-cover rounded-l-lg"
                          />
                          <div className="flex-1 p-4">
                            <div className="flex justify-between items-start mb-2">
                              <div>
                                <h4 className="font-semibold text-green-800">{pile.name}</h4>
                                <div className="flex items-center gap-1 text-sm text-gray-600">
                                  <MapPin className="w-3 h-3" />
                                  {pile.location}
                                </div>
                              </div>
                              <Badge
                                variant={pile.status === "active" ? "default" : "secondary"}
                                className={
                                  pile.status === "active"
                                    ? "bg-green-100 text-green-700"
                                    : "bg-amber-100 text-amber-700"
                                }
                              >
                                {pile.status === "active" ? "Active" : "Needs Attention"}
                              </Badge>
                            </div>

                            <div className="space-y-2">
                              <div className="flex items-center justify-between text-sm">
                                <span className="text-gray-600">Progress</span>
                                <span className="font-medium text-green-700">{pile.progress}%</span>
                              </div>
                              <Progress value={pile.progress} className="h-2" />
                            </div>

                            <div className="flex items-center justify-between mt-3 text-sm">
                              <div className="flex items-center gap-3">
                                <div className="flex items-center gap-1 text-orange-600">
                                  <Thermometer className="w-3 h-3" />
                                  {pile.temperature}°C
                                </div>
                                <div className="flex items-center gap-1 text-blue-600">
                                  <Droplets className="w-3 h-3" />
                                  {pile.moisture}
                                </div>
                              </div>
                              <div className="flex items-center gap-1 text-gray-500">
                                <Users className="w-3 h-3" />
                                {pile.contributors}
                              </div>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </div>
            </TabsContent>

            <TabsContent value="community" className="mt-0">
              <div className="p-4 space-y-6">
                {/* Community Stats */}
                <Card className="bg-gradient-to-r from-emerald-500 to-teal-600 text-white border-0">
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-2xl font-bold">1,247</div>
                        <div className="text-sm opacity-90">Active Community Members</div>
                      </div>
                      <Award className="w-8 h-8 opacity-80" />
                    </div>
                  </CardContent>
                </Card>

                {/* Learning Resources */}
                <div className="grid grid-cols-2 gap-3">
                  <Button
                    onClick={() => setCurrentScreen("guides")}
                    className="h-20 bg-gradient-to-br from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white flex-col gap-2"
                  >
                    <BookOpen className="w-6 h-6" />
                    <span className="font-semibold">Guides</span>
                    <span className="text-xs opacity-90">Step-by-step tutorials</span>
                  </Button>
                  <Button
                    onClick={() => setCurrentScreen("tips")}
                    className="h-20 bg-gradient-to-br from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white flex-col gap-2"
                  >
                    <Lightbulb className="w-6 h-6" />
                    <span className="font-semibold">Tips & Tricks</span>
                    <span className="text-xs opacity-90">Quick solutions</span>
                  </Button>
                </div>

                {/* Featured Learning Content */}
                <div className="space-y-4">
                  <h3 className="font-bold text-green-800 flex items-center gap-2">
                    <Star className="w-5 h-5" />
                    Featured This Week
                  </h3>

                  <Card
                    className="bg-white/80 backdrop-blur-sm border-green-100 hover:shadow-lg transition-shadow cursor-pointer"
                    onClick={() => {
                      setSelectedGuide("singapore-starter")
                      setCurrentScreen("guide-detail")
                    }}
                  >
                    <CardContent className="p-0">
                      <div className="flex">
                        <img
                          src="/placeholder.svg?height=80&width=120"
                          alt="Featured guide"
                          className="w-20 h-20 object-cover rounded-l-lg"
                        />
                        <div className="flex-1 p-3">
                          <Badge className="bg-green-100 text-green-700 mb-1 text-xs">Beginner Guide</Badge>
                          <h4 className="font-semibold text-green-800 text-sm mb-1">Composting in Singapore</h4>
                          <div className="flex items-center gap-2 text-xs text-gray-500">
                            <span className="flex items-center gap-1">
                              <Clock className="w-3 h-3" />8 min
                            </span>
                            <span className="flex items-center gap-1">
                              <Eye className="w-3 h-3" />
                              1.2k
                            </span>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  <div className="grid grid-cols-1 gap-3">
                    {tips.slice(0, 2).map((tip: any) => (
                      <Card
                        key={tip.id}
                        className="bg-white/80 backdrop-blur-sm border-green-100 hover:shadow-md transition-shadow cursor-pointer"
                      >
                        <CardContent className="p-3">
                          <div className="flex items-start gap-3">
                            <div
                              className={`w-8 h-8 rounded-lg bg-gradient-to-br ${tip.color} flex items-center justify-center flex-shrink-0`}
                            >
                              <tip.icon className="w-4 h-4 text-white" />
                            </div>
                            <div className="flex-1">
                              <div className="flex items-center gap-2 mb-1">
                                <Badge variant="secondary" className="text-xs">
                                  {tip.category}
                                </Badge>
                                <span className="text-xs text-gray-500">{tip.time}</span>
                              </div>
                              <h4 className="font-semibold text-green-800 text-sm mb-1">{tip.title}</h4>
                              <p className="text-xs text-gray-600 line-clamp-1">{tip.description}</p>
                              <div className="flex items-center gap-2 mt-1 text-xs text-gray-500">
                                <span className="flex items-center gap-1">
                                  <Heart className="w-3 h-3" />
                                  {tip.likes}
                                </span>
                                <Badge variant="outline" className="text-xs">
                                  {tip.difficulty}
                                </Badge>
                              </div>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                </div>

                <Separator />

                {/* Forum Section */}
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="font-bold text-green-800 flex items-center gap-2">
                      <MessageCircle className="w-5 h-5" />
                      Community Discussions
                    </h3>
                    <Button size="sm" className="bg-green-600 hover:bg-green-700">
                      <Plus className="w-4 h-4 mr-1" />
                      Ask
                    </Button>
                  </div>

                  {/* Quick Category Buttons */}
                  <div className="grid grid-cols-3 gap-2">
                    <Button variant="outline" size="sm" className="h-auto py-2 flex-col gap-1 bg-white/70 text-xs">
                      <HelpCircle className="w-3 h-3 text-blue-600" />
                      <span>Get Help</span>
                    </Button>
                    <Button variant="outline" size="sm" className="h-auto py-2 flex-col gap-1 bg-white/70 text-xs">
                      <Lightbulb className="w-3 h-3 text-amber-600" />
                      <span>Share Tips</span>
                    </Button>
                    <Button variant="outline" size="sm" className="h-auto py-2 flex-col gap-1 bg-white/70 text-xs">
                      <Users className="w-3 h-3 text-green-600" />
                      <span>Connect</span>
                    </Button>
                  </div>

                  {/* Search */}
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <Input
                      placeholder="Search discussions..."
                      className="pl-10 bg-white/70 backdrop-blur-sm border-green-200 focus:border-green-400"
                    />
                  </div>

                  {/* Forum Posts */}
                  {forumPosts.map((post: any) => (
                    <Card
                      key={post.id}
                      className="cursor-pointer hover:shadow-lg transition-all duration-200 bg-white/80 backdrop-blur-sm border-green-100"
                      onClick={() => setCurrentScreen("question")}
                    >
                      <CardContent className="p-4">
                        <div className="flex items-start gap-3">
                          <Avatar className="w-10 h-10">
                            <AvatarImage src={post.authorAvatar || "/placeholder.svg"} />
                            <AvatarFallback className="bg-green-100 text-green-700">{post.author[0]}</AvatarFallback>
                          </Avatar>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 mb-1">
                              <h4 className="font-semibold text-green-800 text-sm line-clamp-1">{post.title}</h4>
                              {post.isAnswered && <CheckCircle2 className="w-4 h-4 text-green-600 flex-shrink-0" />}
                            </div>

                            <p className="text-xs text-gray-600 mb-2 line-clamp-2">{post.excerpt}</p>

                            <div className="flex flex-wrap gap-1 mb-2">
                              {post.tags.map((tag: string) => (
                                <Badge key={tag} variant="secondary" className="text-xs px-2 py-0">
                                  {tag}
                                </Badge>
                              ))}
                            </div>

                            <div className="flex items-center justify-between text-xs text-gray-500">
                              <div className="flex items-center gap-3">
                                <span>{post.author}</span>
                                <span>{post.time}</span>
                              </div>
                              <div className="flex items-center gap-3">
                                <span className="flex items-center gap-1">
                                  <Heart className="w-3 h-3" />
                                  {post.votes}
                                </span>
                                <span className="flex items-center gap-1">
                                  <MessageCircle className="w-3 h-3" />
                                  {post.replies}
                                </span>
                                <span className="flex items-center gap-1">
                                  <Eye className="w-3 h-3" />
                                  {post.views}
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </div>
      </div>
      {showNotifications && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30">
          <div className="bg-white rounded-lg shadow-lg p-6 max-w-xs w-full">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-green-800">Notifications</h3>
              <Button variant="ghost" size="sm" onClick={() => setShowNotifications(false)}>
                Close
            </Button>
            </div>
            <div className="text-gray-600 text-center">No notifications yet</div>
          </div>
            </div>
      )}
            </div>
  )

  const renderGuidesScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        <GuideListComp
          guides={guidesWithLikes}
          loading={guidesLoading}
          error={guidesError}
          search={guideSearch}
          filter={guideFilter}
          onSearch={setGuideSearch}
          onFilter={setGuideFilter}
          onSelect={(id: string) => {
            setSelectedGuide(id);
            setCurrentScreen("guide-detail");
          }}
          onLike={(id: string) => handleGuideLike(id)}
          onBack={() => setCurrentScreen("home")}
        />
                  </div>
                  </div>
  );

  const renderGuideDetailScreen = () => {
    const guide = guidesWithLikes.find((g) => g.id === selectedGuide);
    const relatedGuides = guidesWithLikes.filter((g) => g.id !== selectedGuide).slice(0, 2);
    return (
      <GuideDetailComp
        guide={guide}
        relatedGuides={relatedGuides}
        onBack={() => setCurrentScreen("guides")}
        onLike={(id: string) => handleGuideLike(id)}
        onSelectRelated={(id: string) => setSelectedGuide(id)}
      />
    );
  };

  const renderTipsScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3 mb-4">
            <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("home")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h2 className="text-xl font-bold text-green-800">Tips & Tricks</h2>
              <p className="text-sm text-green-600">Quick solutions and pro tips</p>
            </div>
          </div>

          {/* Search and Filter */}
          <div className="space-y-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <Input
                placeholder="Search tips..."
                className="pl-10 bg-white/70 backdrop-blur-sm border-green-200 focus:border-green-400"
              />
            </div>
            <div className="flex gap-2 overflow-x-auto pb-2">
              <Badge variant="default" className="bg-amber-100 text-amber-700 whitespace-nowrap">
                All
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Basics
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Pro Tips
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Troubleshooting
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Seasonal
              </Badge>
            </div>
          </div>
        </div>

        <div className="p-4 space-y-4">
          {/* Featured Tip */}
          <Card className="bg-gradient-to-br from-amber-500 to-orange-600 text-white border-0 shadow-xl">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 mb-2">
                <Star className="w-5 h-5" />
                <span className="font-semibold">Tip of the Day</span>
              </div>
              <h3 className="font-bold text-lg mb-2">Freeze Kitchen Scraps First</h3>
              <p className="text-sm opacity-90 mb-3">
                Freeze your kitchen scraps for 24-48 hours before composting. This kills fruit fly eggs and breaks down
                cell walls for faster decomposition!
              </p>
              <div className="flex items-center justify-between">
                <Badge className="bg-white/20 text-white">Pro Tip</Badge>
                <div className="flex items-center gap-1 text-sm">
                  <Heart className="w-4 h-4" />
                  134 loves this
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Tips Grid */}
          <div className="space-y-4">
            {tips.map((tip) => (
              <Card
                key={tip.id}
                className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg hover:shadow-xl transition-all duration-200"
              >
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <div
                      className={`w-12 h-12 rounded-xl bg-gradient-to-br ${tip.color} flex items-center justify-center flex-shrink-0`}
                    >
                      <tip.icon className="w-6 h-6 text-white" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <Badge variant="secondary" className="text-xs">
                          {tip.category}
                        </Badge>
                        <Badge variant="outline" className="text-xs">
                          {tip.difficulty}
                        </Badge>
                        <span className="text-xs text-gray-500 flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {tip.time}
                        </span>
                      </div>
                      <h3 className="font-bold text-green-800 mb-2">{tip.title}</h3>
                      <p className="text-sm text-gray-600 mb-3 leading-relaxed">{tip.description}</p>
                      <div className="bg-green-50 rounded-lg p-3 mb-3">
                        <p className="text-sm text-green-800 leading-relaxed">{tip.content}</p>
                      </div>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <Button variant="ghost" size="sm" className="text-red-500 hover:text-red-600">
                            <Heart className="w-4 h-4 mr-1" />
                            {tip.likes}
                          </Button>
                          <Button variant="ghost" size="sm" className="text-blue-500 hover:text-blue-600">
                            <Share2 className="w-4 h-4 mr-1" />
                            Share
                          </Button>
                        </div>
                        <Button variant="ghost" size="sm" className="text-gray-500">
                          <Bookmark className="w-4 h-4" />
                        </Button>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Submit Tip CTA */}
          <Card className="bg-gradient-to-r from-emerald-500 to-teal-600 text-white border-0">
            <CardContent className="p-4 text-center">
              <Lightbulb className="w-8 h-8 mx-auto mb-2" />
              <h3 className="font-bold mb-2">Got a Great Tip?</h3>
              <p className="text-sm opacity-90 mb-3">
                Share your composting wisdom with the community and help others succeed!
              </p>
              <Button className="bg-white text-green-700 hover:bg-gray-100">
                <Plus className="w-4 h-4 mr-2" />
                Submit Your Tip
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )

  const renderScannerScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("home")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h2 className="text-xl font-bold text-green-800">QR Scanner</h2>
              <p className="text-sm text-green-600">Point camera at pile QR code</p>
            </div>
          </div>
        </div>

        <div className="p-6">
          <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-xl">
            <CardContent className="p-6">
              <div className="text-center space-y-6">
                <div className="relative w-64 h-64 mx-auto bg-gradient-to-br from-gray-100 to-gray-200 rounded-2xl flex items-center justify-center border-4 border-dashed border-green-300 overflow-hidden">
                  {isLoading ? (
                    <div className="text-center">
                      <div className="w-12 h-12 border-4 border-green-600 border-t-transparent rounded-full animate-spin mx-auto mb-3"></div>
                      <p className="text-sm text-green-700 font-medium">Scanning...</p>
                    </div>
                  ) : (
                    <div className="text-center">
                      <Camera className="w-16 h-16 mx-auto text-gray-400 mb-3" />
                      <p className="text-sm text-gray-600 font-medium">Camera Viewfinder</p>
                      <p className="text-xs text-gray-500 mt-1">Align QR code within frame</p>
                    </div>
                  )}

                  {/* Scanning overlay */}
                  <div className="absolute inset-4 border-2 border-green-500 rounded-lg">
                    <div className="absolute top-0 left-0 w-6 h-6 border-t-4 border-l-4 border-green-500 rounded-tl-lg"></div>
                    <div className="absolute top-0 right-0 w-6 h-6 border-t-4 border-r-4 border-green-500 rounded-tr-lg"></div>
                    <div className="absolute bottom-0 left-0 w-6 h-6 border-b-4 border-l-4 border-green-500 rounded-bl-lg"></div>
                    <div className="absolute bottom-0 right-0 w-6 h-6 border-b-4 border-r-4 border-green-500 rounded-br-lg"></div>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="flex items-center justify-center gap-2 text-green-700">
                    <Zap className="w-4 h-4" />
                    <span className="text-sm font-medium">Auto-scan enabled</span>
                  </div>

                  <Button
                    onClick={handleScan}
                    disabled={isLoading}
                    className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-3 rounded-xl shadow-lg"
                  >
                    {isLoading ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                        Processing...
                      </>
                    ) : (
                      <>
                        <QrCode className="w-5 h-5 mr-2" />
                        Demo: Scan Community Garden A
                      </>
                    )}
                  </Button>
                </div>

                <div className="bg-green-50 rounded-lg p-4">
                  <div className="flex items-start gap-3">
                    <Info className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
                    <div className="text-left">
                      <p className="text-sm font-medium text-green-800">Quick Tip</p>
                      <p className="text-xs text-green-700 mt-1">
                        Hold your phone steady and ensure good lighting for best results. The QR code should fill most
                        of the frame.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )

  const renderJournalScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3 mb-4">
            <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("home")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div className="flex-1">
              <h2 className="text-lg font-bold text-green-800">Community Garden A</h2>
              <div className="flex items-center gap-1 text-sm text-green-600">
                <MapPin className="w-3 h-3" />
                Toa Payoh Central
              </div>
            </div>
            <div className="flex gap-1">
              <Button variant="ghost" size="sm">
                <Share2 className="w-4 h-4" />
              </Button>
              <Button variant="ghost" size="sm">
                <Bookmark className="w-4 h-4" />
              </Button>
            </div>
          </div>

          {/* Status Cards */}
          <div className="grid grid-cols-2 gap-3 mb-4">
            <Card className="bg-gradient-to-br from-orange-500 to-red-500 text-white border-0">
              <CardContent className="p-3 text-center">
                <div className="flex items-center justify-center gap-1 mb-1">
                  <Thermometer className="w-4 h-4" />
                  <span className="text-lg font-bold">45°C</span>
                </div>
                <p className="text-xs opacity-90">Temperature</p>
                <div className="text-xs mt-1 opacity-75">Optimal Range</div>
              </CardContent>
            </Card>
            <Card className="bg-gradient-to-br from-blue-500 to-cyan-500 text-white border-0">
              <CardContent className="p-3 text-center">
                <div className="flex items-center justify-center gap-1 mb-1">
                  <Droplets className="w-4 h-4" />
                  <span className="text-lg font-bold">Good</span>
                </div>
                <p className="text-xs opacity-90">Moisture Level</p>
                <div className="text-xs mt-1 opacity-75">Well Balanced</div>
              </CardContent>
            </Card>
          </div>

          {/* Health Score */}
          <Card className="bg-white/70 backdrop-blur-sm border-green-200 mb-4">
            <CardContent className="p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="font-semibold text-green-800">Compost Health Score</span>
                <Badge className="bg-green-100 text-green-700">Excellent</Badge>
              </div>
              <div className="flex items-center gap-3">
                <Progress value={85} className="flex-1 h-3" />
                <span className="font-bold text-green-700">85/100</span>
              </div>
              <div className="flex items-center gap-4 mt-3 text-sm text-gray-600">
                <div className="flex items-center gap-1">
                  <Users className="w-3 h-3" />
                  12 contributors
                </div>
                <div className="flex items-center gap-1">
                  <Calendar className="w-3 h-3" />
                  65% complete
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="p-4 space-y-4">
          {/* Add Entry Button */}
          <Button
            onClick={() => setCurrentScreen("add-entry")}
            className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200"
          >
            <Plus className="w-5 h-5 mr-3" />
            <div className="text-left">
              <div className="font-semibold">Log New Activity</div>
              <div className="text-sm opacity-90">Add greens, browns, or maintenance</div>
            </div>
          </Button>

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

            {journalLoading && <div>Loading...</div>}
            {journalError && <div className="text-red-600 text-sm">{journalError}</div>}
            <ScrollArea className="h-96">
              <div className="space-y-4">
                {journalEntries.length === 0 && !journalLoading && <div>No entries yet.</div>}
                {journalEntries.map((entry, index) => (
                  <Card
                    key={entry.id}
                    className="bg-white/80 backdrop-blur-sm border-green-100 hover:shadow-md transition-shadow"
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start gap-3">
                        <div className="relative">
                          <Avatar className="w-10 h-10 border-2 border-white shadow-sm">
                            <AvatarImage src={entry.avatar || "/placeholder.svg"} />
                            <AvatarFallback className="bg-green-100 text-green-700">
                              {entry.user?.split(" ").map((n: string) => n[0]).join("") || "U"}
                            </AvatarFallback>
                          </Avatar>
                          </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex justify-between items-start mb-2">
                            <div>
                              <h4 className="font-semibold text-green-800 text-sm">{entry.action || entry.content}</h4>
                              <p className="text-xs text-gray-600">by {entry.user || "You"}</p>
                            </div>
                            <span className="text-xs text-gray-500">{new Date(entry.created_at).toLocaleString()}</span>
                          </div>
                          <p className="text-sm text-gray-700 mb-3">{entry.details || entry.content}</p>
                          {/* Add more fields as needed */}
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
  )

  const renderAddEntryScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("journal")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h2 className="text-xl font-bold text-green-800">Log Activity</h2>
              <p className="text-sm text-green-600">Community Garden A</p>
            </div>
          </div>
        </div>

        <div className="p-4">
          <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg">
            <CardHeader className="pb-4">
              <h3 className="font-semibold text-green-800">What did you do today?</h3>
            </CardHeader>
            <CardContent>
                  <Textarea
                placeholder="Describe your composting activity..."
                value={newEntryContent}
                onChange={e => setNewEntryContent(e.target.value)}
                    className="bg-white/70 border-green-200 focus:border-green-400 min-h-[80px]"
                  />
              {journalError && <div className="text-red-600 text-sm mt-2">{journalError}</div>}
              <div className="space-y-3 mt-4">
                <Button
                  onClick={handleAddJournalEntry}
                  className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-3 rounded-xl shadow-lg"
                  disabled={journalLoading || !newEntryContent.trim()}
                >
                  <CheckCircle2 className="w-5 h-5 mr-2" />
                  {journalLoading ? "Saving..." : "Save Entry"}
                </Button>
                <Button
                  variant="outline"
                  onClick={() => setCurrentScreen("journal")}
                  className="w-full border-green-200 text-green-700 hover:bg-green-50"
                >
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )

  const renderQuestionScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("home")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div className="flex-1">
              <h2 className="text-lg font-bold text-green-800">Community Discussion</h2>
              <p className="text-sm text-green-600">Help & get helped</p>
            </div>
            <Button variant="ghost" size="sm">
              <Share2 className="w-4 h-4" />
            </Button>
          </div>
        </div>

        <div className="p-4 space-y-4">
          {/* Original Question */}
          <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg">
            <CardContent className="p-4">
              <div className="flex items-start gap-3 mb-4">
                <Avatar className="w-12 h-12 border-2 border-white shadow-sm">
                  <AvatarImage src="/placeholder.svg?height=48&width=48" />
                  <AvatarFallback className="bg-red-100 text-red-700">GN</AvatarFallback>
                </Avatar>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-semibold text-green-800">GreenNewbie</span>
                    <Badge variant="secondary" className="text-xs bg-blue-100 text-blue-700">
                      New Member
                    </Badge>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <span>1 hour ago</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <Eye className="w-3 h-3" />
                      234 views
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-1">
                  <Button variant="ghost" size="sm" className="text-red-500 hover:text-red-600">
                    <Heart className="w-4 h-4 mr-1" />
                    12
                  </Button>
                </div>
              </div>

              <h3 className="font-bold text-green-800 mb-3 text-lg">
                Fruit flies invasion - emergency help needed! 🆘
              </h3>

              <p className="text-gray-700 mb-4 leading-relaxed">
                My compost bin is completely overrun with fruit flies and I'm at my wit's end! I started composting 3
                weeks ago and everything seemed fine initially. But now there are hundreds of tiny flies swarming around
                the bin. The smell is getting worse and my neighbors are starting to complain.
              </p>

              <p className="text-gray-700 mb-4 leading-relaxed">
                I've been adding mostly kitchen scraps - vegetable peels, fruit waste, coffee grounds. I tried covering
                it with a lid but they seem to find their way in anyway. Please help! 😭
              </p>

              <div className="flex flex-wrap gap-2 mb-4">
                <Badge className="bg-red-100 text-red-700">urgent</Badge>
                <Badge className="bg-amber-100 text-amber-700">fruit-flies</Badge>
                <Badge className="bg-blue-100 text-blue-700">pest-control</Badge>
                <Badge className="bg-green-100 text-green-700">troubleshooting</Badge>
              </div>

              <div className="flex items-center justify-between text-sm text-gray-500 pt-3 border-t border-gray-100">
                <div className="flex items-center gap-4">
                  <span className="flex items-center gap-1">
                    <MessageCircle className="w-4 h-4" />
                    15 answers
                  </span>
                  <span className="flex items-center gap-1">
                    <CheckCircle2 className="w-4 h-4 text-green-600" />
                    Solved
                  </span>
                </div>
                <Button variant="ghost" size="sm">
                  <Bookmark className="w-4 h-4" />
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Best Answer */}
          <Card className="bg-gradient-to-r from-amber-50 to-yellow-50 border-2 border-amber-200 shadow-lg">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <Award className="w-5 h-5 text-amber-600" />
                <span className="font-semibold text-amber-800">Best Answer</span>
              </div>
            </CardHeader>
            <CardContent className="pt-0">
              <div className="flex items-start gap-3 mb-4">
                <Avatar className="w-10 h-10 border-2 border-amber-300">
                  <AvatarImage src="/placeholder.svg?height=40&width=40" />
                  <AvatarFallback className="bg-amber-100 text-amber-700">MC</AvatarFallback>
                </Avatar>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-semibold text-green-800">MasterComposter</span>
                    <Badge className="bg-amber-100 text-amber-800 text-xs">
                      <Star className="w-3 h-3 mr-1" />
                      Composting Master
                    </Badge>
                  </div>
                  <p className="text-xs text-gray-500">45 minutes ago</p>
                </div>
              </div>

              <div className="space-y-3 text-gray-700">
                <p className="leading-relaxed">
                  <strong>Don't panic!</strong> Fruit flies are super common and totally fixable. Here's your action
                  plan:
                </p>

                <div className="bg-white/60 rounded-lg p-3 space-y-2">
                  <p className="font-semibold text-green-800">Immediate fixes:</p>
                  <ul className="text-sm space-y-1 ml-4">
                    <li>• Stop adding fresh fruit scraps for now</li>
                    <li>• Add lots of "browns" - dry leaves, cardboard, paper</li>
                    <li>• Turn your pile thoroughly to bury the wet stuff</li>
                    <li>• Cover with a thick layer of browns</li>
                  </ul>
                </div>

                <p className="leading-relaxed">
                  The flies are there because your compost is too wet and lacks carbon. The 3:1 brown-to-green ratio is
                  crucial in Singapore's humidity. Also, avoid citrus peels and meat scraps - they attract more pests.
                </p>

                <div className="bg-green-50 rounded-lg p-3">
                  <p className="text-sm font-medium text-green-800 mb-1">Pro tip:</p>
                  <p className="text-sm text-green-700">
                    Freeze your kitchen scraps for 24 hours before adding them. This kills fly eggs and larvae!
                  </p>
                </div>
              </div>

              <div className="flex items-center justify-between mt-4 pt-3 border-t border-amber-200">
                <div className="flex items-center gap-3 text-sm text-gray-600">
                  <Button variant="ghost" size="sm" className="text-green-600 hover:text-green-700">
                    <Heart className="w-4 h-4 mr-1" />
                    28 helpful
                  </Button>
                  <span>•</span>
                  <span>Marked as solution</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Other Answers */}
          <div className="space-y-3">
            <h4 className="font-semibold text-green-800 flex items-center gap-2">
              <MessageCircle className="w-4 h-4" />
              Other Helpful Answers
            </h4>

            <Card className="bg-white/80 backdrop-blur-sm border-green-100">
              <CardContent className="p-4">
                <div className="flex items-start gap-3 mb-3">
                  <Avatar className="w-8 h-8">
                    <AvatarImage src="/placeholder.svg?height=32&width=32" />
                    <AvatarFallback className="bg-green-100 text-green-700">SG</AvatarFallback>
                  </Avatar>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium text-green-800">SarahGardener</span>
                      <Badge variant="secondary" className="text-xs">
                        Regular
                      </Badge>
                    </div>
                    <p className="text-xs text-gray-500">30 minutes ago</p>
                  </div>
                </div>

                <p className="text-sm text-gray-700 mb-3 leading-relaxed">
                  I had the exact same problem last month! What saved me was adding a layer of soil on top. The
                  microorganisms in soil help break down the organic matter faster and reduce odors. Also, make sure
                  your bin has proper drainage holes.
                </p>

                <div className="flex items-center gap-3 text-xs text-gray-500">
                  <Button variant="ghost" size="sm" className="text-blue-600 hover:text-blue-700">
                    <Heart className="w-3 h-3 mr-1" />8 helpful
                  </Button>
                  <Button variant="ghost" size="sm">
                    Reply
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-white/80 backdrop-blur-sm border-green-100">
              <CardContent className="p-4">
                <div className="flex items-start gap-3 mb-3">
                  <Avatar className="w-8 h-8">
                    <AvatarImage src="/placeholder.svg?height=32&width=32" />
                    <AvatarFallback className="bg-blue-100 text-blue-700">EC</AvatarFallback>
                  </Avatar>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium text-green-800">EcoWarrior</span>
                      <Badge className="bg-green-100 text-green-700 text-xs">
                        <Target className="w-3 h-3 mr-1" />
                        Expert
                      </Badge>
                    </div>
                    <p className="text-xs text-gray-500">15 minutes ago</p>
                  </div>
                </div>

                <p className="text-sm text-gray-700 mb-3 leading-relaxed">
                  Quick DIY trap: Put apple cider vinegar in a jar with a drop of dish soap. Cover with plastic wrap,
                  poke small holes. The flies get trapped! This won't solve the root cause but helps with the immediate
                  swarm.
                </p>

                <div className="flex items-center gap-3 text-xs text-gray-500">
                  <Button variant="ghost" size="sm" className="text-blue-600 hover:text-blue-700">
                    <Heart className="w-3 h-3 mr-1" />
                    12 helpful
                  </Button>
                  <Button variant="ghost" size="sm">
                    Reply
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Add Answer */}
          <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg">
            <CardHeader className="pb-3">
              <h4 className="font-semibold text-green-800">Share Your Experience</h4>
            </CardHeader>
            <CardContent className="pt-0">
              <div className="flex items-start gap-3">
                <Avatar className="w-8 h-8">
                  <AvatarImage src="/placeholder.svg?height=32&width=32" />
                  <AvatarFallback className="bg-blue-100 text-blue-700">YL</AvatarFallback>
                </Avatar>
                <div className="flex-1 space-y-3">
                  <Textarea
                    placeholder="Have you dealt with this issue before? Share your solution or ask follow-up questions..."
                    className="bg-white/70 border-green-200 focus:border-green-400 min-h-[80px]"
                  />
                  <div className="flex justify-between items-center">
                    <div className="flex items-center gap-2 text-xs text-gray-500">
                      <Camera className="w-3 h-3" />
                      <span>Add photos</span>
                    </div>
                    <Button size="sm" className="bg-green-600 hover:bg-green-700 text-white">
                      <Send className="w-3 h-3 mr-2" />
                      Post Answer
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
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
