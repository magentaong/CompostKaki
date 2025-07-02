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
  
  // future implementation for notifs
  const notificationCount = 3;
  useEffect(() => {
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

  // Filter bins by search
  const filteredBins = bins.filter(
    (bin) =>
      bin.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      bin.location?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-emerald-50 to-teal-50">
      <div className="relative max-w-md mx-auto">
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
              <Button variant="ghost" size="sm" className="relative">
                <Bell className="w-10 h-10 text-green-700" />
                <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full flex items-center justify-center text-[10px] text-white font-bold">
                  {notificationCount}
                </span>
              </Button> 

              <Button variant="ghost" size="sm" onClick={() => router.push("/profile-settings")}> <div className="w-8 h-8 rounded-full bg-gray-200" /> </Button>
            </div>
          </div>
          <Tabs value={tab} onValueChange={setTab} className="w-full">
            <TabsList className="grid w-full grid-cols-2 bg-green-100/50 p-1">
              <TabsTrigger value="journal" className="flex items-center gap-2 data-[state=active]:bg-white data-[state=active]:shadow-sm">
                <span className="font-medium">Journal</span>
              </TabsTrigger>
              <TabsTrigger value="community" className="flex items-center gap-2 data-[state=active]:bg-white data-[state=active]:shadow-sm">
                <span className="font-medium">Community</span>
              </TabsTrigger>
            </TabsList>
          </Tabs>
        </div>
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsContent value="journal">
            <div className="p-4 space-y-6">

              {/* Quick Stats */}
              <div className="grid grid-cols-2 gap-3">
                <Card className="flex flex-col gap-6 shadow-sm bg-white border-green-700 text-green-900 rounded-xl border-2 p-0">
                  <CardContent className="p-3 text-center">
                    <div className="text-2xl font-bold">{bins.length}</div>
                    <div className="text-xs opacity-90">Active Bins</div>
                  </CardContent>
                </Card>
                <Card className="flex flex-col gap-6 shadow-sm bg-white border-green-700 text-green-900 rounded-xl border-2 p-0">
                  <CardContent className="p-3 text-center">
                    <div className="text-2xl font-bold">{userLogCount}</div>
                    <div className="text-xs opacity-90">Logs</div>
                  </CardContent>
                </Card>
              </div>           
              {/* Search Bar 
              <div className="relative">
                <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                <Input
                  placeholder="Search compost bins..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10 bg-white/70 backdrop-blur-sm border-green-200 focus:border-green-400"
                />
              </div> */}
              {/* Add Bin Button */}
              <div className="flex justify-between items-center">
                <p className="text-green-700 text-m font-medium font-bold flex gap-2 items-center">
                  <TrendingUp className="w-5 h-5"></TrendingUp> Your Active Piles</p>
                <div className="flex justify-end">
                  <Button
                    className="w-8 h-8 rounded-full border-2 border-[#96CC4F] bg-white text-[#96CC4F] flex items-center justify-center hover:bg-[#96CC4F] hover:text-white shadow-[0_0_5px_rgba(150,204,79,0.3)] hover:shadow-[0_0_10px_rgba(150,204,79,0.5)]transition duration-200"
                    onClick={() => router.push("/add-bin")}
                  >
                    <Plus className="w-5 h-5" /> 
                  </Button>
                </div>
              </div>
              {/* Bin Cards */}
              <div className="space-y-4">
                {loading && <div>Loading bins...</div>}
                {error && <div className="text-red-600 text-sm">{error}</div>}
                {filteredBins.map((bin) => (
                  
                  <Card
                    key={bin.id}
                    className="cursor-pointer hover:shadow-lg transition-all duration-200 bg-white/80 backdrop-blur-sm border-green-100 hover:border-green-200 p-0"
                    onClick={() => router.push(`/bin/${bin.id}`)}
                  >
                    <CardContent className="p-0">
                      <div className="flex">
                        <img
                        src={bin.image || "/default_compost_image.jpg"}
                        alt={bin.name}
                        className="w-30 object-cover rounded-l-lg height-auto"
                        />
                        <div className="flex-1 p-4">
                          <div className="flex justify-between items-start mb-2">
                            <div>
                              <h4 className="font-semibold text-green-800">{bin.name}</h4>
                            </div>
                            <Badge
                              variant={
                                bin.health_status === "Healthy"
                                  ? "default"
                                  : bin.health_status === "Needs Attention"
                                  ? "secondary"
                                  : bin.health_status === "Critical"
                                  ? "destructive"
                                  : "outline"
                              }
                              className={
                                bin.health_status === "Healthy"
                                  ? "bg-green-100 text-green-700"
                                  : bin.health_status === "Needs Attention"
                                  ? "bg-amber-100 text-amber-700"
                                  : bin.health_status === "Critical"
                                  ? "bg-red-100 text-red-700"
                                  : "bg-gray-100 text-gray-600"
                              }
                            >
                              {bin.health_status === "Healthy"
                                ? "Healthy"
                                : bin.health_status === "Needs Attention"
                                ? "Needs Attention"
                                : bin.health_status === "Critical"
                                ? "Critical"
                                : "Unknown"}
                            </Badge>

                          </div>
                          
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-1 text-orange-600 text-sm">
                                <Thermometer className="w-5 h-5" />
                                {bin.latest_temperature || "-"}°C
                              </div>
                              <div className="flex items-center gap-1 text-blue-600 text-sm">
                                <Droplets className="w-5 h-5" />
                                {bin.latest_moisture || "-"}
                              </div>
                              <div className="flex items-center gap-1 text-brown-600 text-sm">
                                <RefreshCw className="w-5 h-5" />
                                {bin.latest_flips || "0"}
                              </div>
                            </div>
                            <div className="flex items-centergap-1 text-gray-500 justify-end mt-5">
                              <Users className="w-5 h-5" />
                              {bin.contributors || 1}
                            </div>
                          </div>
                        </div>
                      
                    </CardContent>
                  </Card>
                ))}
                {filteredBins.length === 0 && !loading && <div className="text-gray-500 text-center">No bins found.</div>}
              </div>
              {/* QR Scanner Button */}
              <div className="mt-12 flex justify-end items-end ">
                <button onClick={() => router.push("/scanner")}
                className="fixed bottom-6 w-16 h-16 rounded-full bg-[#96CC4F] text-white 
             flex items-center justify-center
             shadow-[0_0_8px_rgba(150,204,79,0.5)]
             hover:bg-[#80B543]
             transition">
                  <QrCode className="w-6 h-6" />
                </button>
              </div>
            </div>
          </TabsContent>
          <TabsContent value="community">
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
                  onClick={() => router.push("/guides")}
                  className="h-20 bg-gradient-to-br from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white flex-col gap-2"
                >
                  <BookOpen className="w-6 h-6" />
                  <span className="font-semibold">Guides</span>
                  <span className="text-xs opacity-90">Step-by-step tutorials</span>
                </Button>
                <Button
                  onClick={() => router.push("/tips")}
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
                  onClick={() => router.push("/guides")}
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
                            <BookOpen className="w-3 h-3" />8 min
                          </span>
                          <span className="flex items-center gap-1">
                            <Eye className="w-3 h-3" />1.2k
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
                          <div className={`w-8 h-8 rounded-lg bg-gradient-to-br ${tip.color} flex items-center justify-center flex-shrink-0`}>
                            {tip.icon ? <tip.icon className="w-4 h-4 text-white" /> : <Lightbulb className="w-4 h-4 text-white" />}
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <Badge variant="secondary" className="text-xs">{tip.category}</Badge>
                              <span className="text-xs text-gray-500">{tip.time}</span>
                            </div>
                            <h4 className="font-semibold text-green-800 text-sm mb-1">{tip.title}</h4>
                            <p className="text-xs text-gray-600 line-clamp-1">{tip.description}</p>
                            <div className="flex items-center gap-2 mt-1 text-xs text-gray-500">
                              <span className="flex items-center gap-1">
                                <Heart className="w-3 h-3" />{tip.likes}
                              </span>
                              <Badge variant="outline" className="text-xs">{tip.difficulty}</Badge>
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
                    <Plus className="w-4 h-4 mr-1" />Ask
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
                {forumLoading && <div>Loading discussions...</div>}
                {forumError && <div className="text-red-600 text-sm">{forumError}</div>}
                {forumPosts.map((post: any) => (
                  <Card
                    key={post.id}
                    className="cursor-pointer hover:shadow-lg transition-all duration-200 bg-white/80 backdrop-blur-sm border-green-100"
                    onClick={() => router.push(`/community/posts/${post.id}`)}
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start gap-3">
                        <Avatar className="w-10 h-10">
                          <AvatarImage src={post.authorAvatar || "/placeholder.svg"} />
                          <AvatarFallback className="bg-green-100 text-green-700">{post.author?.[0] || "U"}</AvatarFallback>
                        </Avatar>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h4 className="font-semibold text-green-800 text-sm line-clamp-1">{post.title}</h4>
                            {post.isAnswered && <CheckCircle2 className="w-4 h-4 text-green-600 flex-shrink-0" />}
                          </div>
                          <p className="text-xs text-gray-600 mb-2 line-clamp-2">{post.excerpt}</p>
                          <div className="flex flex-wrap gap-1 mb-2">
                            {post.tags?.map((tag: string) => (
                              <Badge key={tag} variant="secondary" className="text-xs px-2 py-0">{tag}</Badge>
                            ))}
                          </div>
                          <div className="flex items-center justify-between text-xs text-gray-500">
                            <div className="flex items-center gap-3">
                              <span>{post.author}</span>
                              <span>{post.time}</span>
                            </div>
                            <div className="flex items-center gap-3">
                              <span className="flex items-center gap-1">
                                <Heart className="w-3 h-3" />{post.votes}
                              </span>
                              <span className="flex items-center gap-1">
                                <MessageCircle className="w-3 h-3" />{post.replies}
                              </span>
                              <span className="flex items-center gap-1">
                                <Eye className="w-3 h-3" />{post.views}
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
  );
} 