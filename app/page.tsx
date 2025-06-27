"use client"

import { useState } from "react"
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

export default function CompostConnect() {
  const [currentScreen, setCurrentScreen] = useState<Screen>("home")
  const [selectedPile, setSelectedPile] = useState<string>("")
  const [selectedGuide, setSelectedGuide] = useState<string>("")
  const [isLoading, setIsLoading] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")

  const guides = [
    {
      id: "singapore-starter",
      title: "Composting in Singapore: Complete Beginner's Guide",
      description: "Everything you need to know to start composting in tropical Singapore",
      category: "Beginner",
      readTime: "8 min read",
      difficulty: "Beginner",
      views: 1234,
      likes: 89,
      image: "/placeholder.svg?height=120&width=200",
      author: "Dr. Sarah Lim",
      tags: ["beginner", "singapore", "tropical", "setup"],
      sections: [
        {
          title: "Why Compost in Singapore?",
          content:
            "Singapore generates over 1.5 million tonnes of food waste annually. Learn how composting helps reduce this burden while creating nutrient-rich soil for our urban gardens.",
          icon: Recycle,
        },
        {
          title: "Choosing Your Setup",
          content:
            "From HDB-friendly bokashi bins to community pile systems, discover which composting method works best for your living situation and space constraints.",
          icon: Home,
        },
        {
          title: "Tropical Climate Considerations",
          content:
            "Singapore's year-round heat and humidity create unique challenges. Learn how to manage moisture, prevent pest issues, and maintain optimal decomposition rates.",
          icon: Sun,
        },
        {
          title: "Getting Started Checklist",
          content:
            "Your step-by-step action plan including materials needed, initial setup, and first week activities to ensure composting success from day one.",
          icon: CheckCircle,
        },
      ],
    },
    {
      id: "hdb-composting",
      title: "HDB Apartment Composting Solutions",
      description: "Space-efficient methods for high-rise living",
      category: "Urban",
      readTime: "6 min read",
      difficulty: "Beginner",
      views: 892,
      likes: 67,
      image: "/placeholder.svg?height=120&width=200",
      author: "Marcus Tan",
      tags: ["hdb", "small-space", "urban", "indoor"],
      sections: [
        {
          title: "Balcony Setup",
          content:
            "Transform your HDB balcony into a composting station with proper ventilation, odor control, and neighbor-friendly practices.",
          icon: Building,
        },
        {
          title: "Kitchen Prep Area",
          content:
            "Organize your kitchen for efficient scrap collection and preprocessing before adding to your compost system.",
          icon: Home,
        },
        {
          title: "Odor Management",
          content:
            "Essential techniques to keep your apartment and hallway odor-free while maintaining an active compost system.",
          icon: AlertTriangle,
        },
      ],
    },
    {
      id: "pest-prevention",
      title: "Pest-Free Composting in the Tropics",
      description: "Keep flies, ants, and critters away from your compost",
      category: "Troubleshooting",
      readTime: "5 min read",
      difficulty: "Intermediate",
      views: 756,
      likes: 54,
      image: "/placeholder.svg?height=120&width=200",
      author: "Lisa Wong",
      tags: ["pests", "tropical", "prevention", "maintenance"],
      sections: [
        {
          title: "Common Tropical Pests",
          content: "Identify fruit flies, ants, cockroaches, and other common compost invaders in Singapore's climate.",
          icon: Bug,
        },
        {
          title: "Prevention Strategies",
          content:
            "Proactive measures to prevent pest infestations before they start, including proper ratios and covering techniques.",
          icon: CheckCircle,
        },
        {
          title: "Natural Solutions",
          content:
            "Chemical-free methods to eliminate existing pest problems without harming your compost microorganisms.",
          icon: TreePine,
        },
      ],
    },
    {
      id: "community-composting",
      title: "Community Composting Success",
      description: "Building and maintaining shared composting projects",
      category: "Community",
      readTime: "7 min read",
      difficulty: "Advanced",
      views: 445,
      likes: 32,
      image: "/placeholder.svg?height=120&width=200",
      author: "David Chen",
      tags: ["community", "management", "collaboration", "leadership"],
      sections: [
        {
          title: "Getting Started",
          content:
            "How to propose, plan, and launch a community composting initiative in your neighborhood or organization.",
          icon: Users,
        },
        {
          title: "Management Systems",
          content:
            "Organizing volunteers, creating schedules, and maintaining consistent participation in group composting projects.",
          icon: Calendar,
        },
        {
          title: "Conflict Resolution",
          content:
            "Common challenges in community composting and diplomatic solutions to keep everyone engaged and happy.",
          icon: MessageCircle,
        },
      ],
    },
  ]

  const tips = [
    {
      id: "green-brown-ratio",
      title: "Perfect Green-to-Brown Ratio for Singapore",
      category: "Basics",
      difficulty: "Beginner",
      time: "2 min",
      likes: 156,
      description: "The 3:1 ratio that actually works in tropical humidity",
      icon: Scales,
      color: "from-green-500 to-emerald-600",
      content:
        "In Singapore's humid climate, use 3 parts brown materials (dry leaves, cardboard, paper) to 1 part green materials (kitchen scraps). This prevents the soggy, smelly compost common in tropical climates.",
    },
    {
      id: "freeze-scraps",
      title: "Freeze Kitchen Scraps Before Composting",
      category: "Pro Tips",
      difficulty: "Beginner",
      time: "1 min",
      likes: 134,
      description: "Kill fruit fly eggs and speed up decomposition",
      icon: Zap,
      color: "from-blue-500 to-cyan-600",
      content:
        "Freeze kitchen scraps for 24-48 hours before adding to compost. This kills fruit fly eggs, breaks down cell walls for faster decomposition, and reduces initial odors.",
    },
    {
      id: "monsoon-management",
      title: "Monsoon Season Composting",
      category: "Seasonal",
      difficulty: "Intermediate",
      time: "3 min",
      likes: 98,
      description: "Keep your pile active during heavy rains",
      icon: CloudRain,
      color: "from-purple-500 to-indigo-600",
      content:
        "During monsoon season, cover your pile with a tarp, add extra brown materials, and turn more frequently. Create drainage channels around ground piles to prevent waterlogging.",
    },
    {
      id: "temperature-monitoring",
      title: "Temperature Sweet Spots",
      category: "Monitoring",
      difficulty: "Intermediate",
      time: "2 min",
      likes: 87,
      description: "When to worry about pile temperature",
      icon: Thermometer,
      color: "from-orange-500 to-red-600",
      content:
        "Ideal range: 40-60°C for active decomposition. Below 35°C means add greens and turn. Above 70°C means add browns and water. No heat after 1 week indicates imbalanced ratios.",
    },
    {
      id: "urban-collection",
      title: "Urban Scrap Collection Hacks",
      category: "Organization",
      difficulty: "Beginner",
      time: "2 min",
      likes: 112,
      description: "Efficient ways to collect materials in the city",
      icon: Recycle,
      color: "from-teal-500 to-green-600",
      content:
        "Partner with local coffee shops for grounds, ask markets for vegetable trimmings at closing time, and collect fallen leaves during morning walks. Always ask permission first!",
    },
    {
      id: "smell-test",
      title: "The Smell Test: Diagnosing Problems",
      category: "Troubleshooting",
      difficulty: "Intermediate",
      time: "2 min",
      likes: 76,
      description: "What different odors tell you about your pile",
      icon: AlertTriangle,
      color: "from-amber-500 to-orange-600",
      content:
        "Sweet/earthy smell = healthy compost. Sour/putrid = too wet, add browns. Ammonia smell = too much nitrogen, add carbon. No smell = pile too dry or inactive.",
    },
  ]

  const piles = [
    {
      id: "pile-a",
      name: "Community Garden A",
      location: "Toa Payoh Central",
      lastUpdate: "2 hours ago",
      temperature: 45,
      moisture: "Optimal",
      status: "active",
      progress: 65,
      contributors: 12,
      image: "/placeholder.svg?height=120&width=200",
      healthScore: 85,
    },
    {
      id: "pile-b",
      name: "Greenwood School",
      location: "Ang Mo Kio Ave 3",
      lastUpdate: "1 day ago",
      temperature: 38,
      moisture: "Needs Water",
      status: "attention",
      progress: 40,
      contributors: 8,
      image: "/placeholder.svg?height=120&width=200",
      healthScore: 72,
    },
    {
      id: "pile-c",
      name: "Sunrise HDB Block",
      location: "Jurong West St 42",
      lastUpdate: "3 days ago",
      temperature: 42,
      moisture: "Good",
      status: "active",
      progress: 80,
      contributors: 15,
      image: "/placeholder.svg?height=120&width=200",
      healthScore: 90,
    },
  ]

  const journalEntries = [
    {
      id: 1,
      user: "Sarah Lim",
      avatar: "/placeholder.svg?height=40&width=40",
      action: "Added organic greens",
      details: "2.5kg mixed vegetable scraps from weekend market",
      time: "2 hours ago",
      temp: 45,
      moisture: "Optimal",
      photos: ["/placeholder.svg?height=80&width=80"],
      likes: 5,
      type: "greens",
    },
    {
      id: 2,
      user: "Mike Tan",
      avatar: "/placeholder.svg?height=40&width=40",
      action: "Turned and aerated pile",
      details: "Mixed thoroughly, added air pockets for better decomposition",
      time: "1 day ago",
      temp: 43,
      moisture: "Good",
      photos: [],
      likes: 8,
      type: "maintenance",
    },
    {
      id: 3,
      user: "Lisa Wong",
      avatar: "/placeholder.svg?height=40&width=40",
      action: "Added carbon-rich browns",
      details: "1.2kg dried leaves and shredded cardboard",
      time: "2 days ago",
      temp: 40,
      moisture: "Dry",
      photos: ["/placeholder.svg?height=80&width=80"],
      likes: 3,
      type: "browns",
    },
    {
      id: 4,
      user: "David Chen",
      avatar: "/placeholder.svg?height=40&width=40",
      action: "Temperature monitoring",
      details: "Pile heating up well, decomposition progressing nicely",
      time: "3 days ago",
      temp: 38,
      moisture: "Good",
      photos: [],
      likes: 6,
      type: "monitoring",
    },
  ]

  const forumPosts = [
    {
      id: 1,
      title: "Fruit flies invasion - emergency help needed!",
      author: "GreenNewbie",
      authorAvatar: "/placeholder.svg?height=32&width=32",
      replies: 15,
      views: 234,
      time: "1 hour ago",
      category: "troubleshooting",
      tags: ["fruit-flies", "pest-control", "urgent"],
      excerpt:
        "My compost bin is completely overrun with fruit flies. I've tried covering it but they keep coming back. The smell is getting worse and my neighbors are complaining...",
      isAnswered: true,
      votes: 12,
    },
    {
      id: 2,
      title: "Perfect green-to-brown ratio for Singapore climate?",
      author: "TropicalGardener",
      authorAvatar: "/placeholder.svg?height=32&width=32",
      replies: 28,
      views: 567,
      time: "3 hours ago",
      category: "best-practices",
      tags: ["ratios", "climate", "singapore"],
      excerpt:
        "I keep hearing different ratios from 2:1 to 4:1. What actually works best in our humid tropical climate? Looking for data-backed answers...",
      isAnswered: true,
      votes: 24,
    },
    {
      id: 3,
      title: "Composting in HDB: space-efficient methods",
      author: "UrbanComposter",
      authorAvatar: "/placeholder.svg?height=32&width=32",
      replies: 19,
      views: 445,
      time: "5 hours ago",
      category: "beginner-tips",
      tags: ["hdb", "small-space", "urban"],
      excerpt:
        "Living in a small HDB flat but want to start composting. What are the most space-efficient and neighbor-friendly methods you'd recommend?",
      isAnswered: false,
      votes: 18,
    },
  ]

  const handleScan = () => {
    setIsLoading(true)
    setTimeout(() => {
      setSelectedPile("pile-a")
      setCurrentScreen("journal")
      setIsLoading(false)
    }, 2000)
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
              <Button variant="ghost" size="sm" className="relative">
                <Bell className="w-5 h-5 text-green-700" />
                <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full flex items-center justify-center">
                  <span className="text-xs text-white font-bold">3</span>
                </div>
              </Button>
              <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("profile")}>
                <Avatar className="w-6 h-6">
                  <AvatarImage src="/placeholder.svg?height=24&width=24" />
                  <AvatarFallback className="bg-green-100 text-green-700 text-xs">YL</AvatarFallback>
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

                  {piles.map((pile) => (
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
                    {tips.slice(0, 2).map((tip) => (
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
                  {forumPosts.map((post) => (
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
                              {post.tags.map((tag) => (
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
    </div>
  )

  const renderGuidesScreen = () => (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3 mb-4">
            <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("home")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h2 className="text-xl font-bold text-green-800">Composting Guides</h2>
              <p className="text-sm text-green-600">Complete step-by-step tutorials</p>
            </div>
          </div>

          {/* Search and Filter */}
          <div className="space-y-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <Input
                placeholder="Search guides..."
                className="pl-10 bg-white/70 backdrop-blur-sm border-green-200 focus:border-green-400"
              />
            </div>
            <div className="flex gap-2 overflow-x-auto pb-2">
              <Badge variant="default" className="bg-green-100 text-green-700 whitespace-nowrap">
                All
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Beginner
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Urban
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Troubleshooting
              </Badge>
              <Badge variant="outline" className="whitespace-nowrap">
                Community
              </Badge>
            </div>
          </div>
        </div>

        <div className="p-4 space-y-4">
          {guides.map((guide) => (
            <Card
              key={guide.id}
              className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg hover:shadow-xl transition-all duration-200 cursor-pointer"
              onClick={() => {
                setSelectedGuide(guide.id)
                setCurrentScreen("guide-detail")
              }}
            >
              <CardContent className="p-0">
                <div className="relative">
                  <img
                    src={guide.image || "/placeholder.svg"}
                    alt={guide.title}
                    className="w-full h-48 object-cover rounded-t-lg"
                  />
                  <div className="absolute top-3 left-3">
                    <Badge className="bg-white/90 text-green-700">{guide.category}</Badge>
                  </div>
                  <div className="absolute top-3 right-3">
                    <div className="bg-black/50 text-white px-2 py-1 rounded text-xs">{guide.readTime}</div>
                  </div>
                </div>

                <div className="p-4">
                  <div className="flex items-start justify-between mb-2">
                    <h3 className="font-bold text-green-800 text-lg line-clamp-2">{guide.title}</h3>
                  </div>

                  <p className="text-gray-600 text-sm mb-3 line-clamp-2">{guide.description}</p>

                  <div className="flex flex-wrap gap-1 mb-3">
                    {guide.tags.map((tag) => (
                      <Badge key={tag} variant="secondary" className="text-xs">
                        {tag}
                      </Badge>
                    ))}
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3 text-sm text-gray-500">
                      <div className="flex items-center gap-1">
                        <Avatar className="w-5 h-5">
                          <AvatarFallback className="bg-green-100 text-green-700 text-xs">
                            {guide.author
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>
                        <span className="text-xs">{guide.author}</span>
                      </div>
                      <span className="flex items-center gap-1">
                        <Eye className="w-3 h-3" />
                        {guide.views}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="outline" className="text-xs">
                        {guide.difficulty}
                      </Badge>
                      <Button variant="ghost" size="sm" className="text-red-500 hover:text-red-600">
                        <Heart className="w-4 h-4 mr-1" />
                        {guide.likes}
                      </Button>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </div>
  )

  const renderGuideDetailScreen = () => {
    const guide = guides.find((g) => g.id === selectedGuide)
    if (!guide) return null

    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
        <div className="max-w-md mx-auto">
          {/* Header */}
          <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
            <div className="flex items-center gap-3 mb-3">
              <Button variant="ghost" size="sm" onClick={() => setCurrentScreen("guides")}>
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <div className="flex-1">
                <Badge className="bg-green-100 text-green-700 mb-1">{guide.category}</Badge>
                <h2 className="text-lg font-bold text-green-800 line-clamp-2">{guide.title}</h2>
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

            <div className="flex items-center justify-between text-sm text-gray-600">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1">
                  <Avatar className="w-6 h-6">
                    <AvatarFallback className="bg-green-100 text-green-700 text-xs">
                      {guide.author
                        .split(" ")
                        .map((n) => n[0])
                        .join("")}
                    </AvatarFallback>
                  </Avatar>
                  <span className="text-xs">{guide.author}</span>
                </div>
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {guide.readTime}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <Button variant="ghost" size="sm" className="text-red-500 hover:text-red-600">
                  <Heart className="w-4 h-4 mr-1" />
                  {guide.likes}
                </Button>
              </div>
            </div>
          </div>

          <div className="p-4 space-y-6">
            {/* Hero Image */}
            <div className="relative">
              <img
                src={guide.image || "/placeholder.svg"}
                alt={guide.title}
                className="w-full h-48 object-cover rounded-xl"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent rounded-xl"></div>
            </div>

            {/* Overview */}
            <Card className="bg-white/90 backdrop-blur-sm border-green-200">
              <CardContent className="p-4">
                <h3 className="font-semibold text-green-800 mb-2">What you'll learn</h3>
                <p className="text-gray-700 text-sm leading-relaxed mb-3">{guide.description}</p>
                <div className="flex items-center gap-4 text-sm text-gray-600">
                  <div className="flex items-center gap-1">
                    <Target className="w-4 h-4 text-green-600" />
                    <span>{guide.difficulty}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Eye className="w-4 h-4 text-blue-600" />
                    <span>{guide.views} views</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Table of Contents */}
            <Card className="bg-white/90 backdrop-blur-sm border-green-200">
              <CardHeader className="pb-3">
                <h3 className="font-semibold text-green-800 flex items-center gap-2">
                  <BookOpen className="w-5 h-5" />
                  Table of Contents
                </h3>
              </CardHeader>
              <CardContent className="pt-0 space-y-3">
                {guide.sections.map((section, index) => (
                  <div
                    key={index}
                    className="flex items-start gap-3 p-3 bg-green-50/50 rounded-lg hover:bg-green-50 transition-colors cursor-pointer"
                  >
                    <div className="w-8 h-8 bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg flex items-center justify-center flex-shrink-0">
                      <section.icon className="w-4 h-4 text-white" />
                    </div>
                    <div className="flex-1">
                      <h4 className="font-medium text-green-800 text-sm">{section.title}</h4>
                      <p className="text-xs text-gray-600 mt-1 line-clamp-2">{section.content}</p>
                    </div>
                    <ArrowRight className="w-4 h-4 text-gray-400 mt-1" />
                  </div>
                ))}
              </CardContent>
            </Card>

            {/* Quick Start Preview */}
            <Card className="bg-gradient-to-br from-emerald-50 to-teal-50 border-emerald-200">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-3">
                  <Zap className="w-5 h-5 text-emerald-600" />
                  <h3 className="font-semibold text-emerald-800">Quick Start Preview</h3>
                </div>
                {selectedGuide === "singapore-starter" && (
                  <div className="space-y-3 text-sm text-emerald-700">
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Choose your location: balcony, community garden, or shared space</span>
                    </div>
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Gather materials: container, brown materials (3 parts), green materials (1 part)</span>
                    </div>
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Set up proper drainage and ventilation for Singapore's humidity</span>
                    </div>
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Start with small amounts and build your composting routine</span>
                    </div>
                  </div>
                )}
                {selectedGuide === "hdb-composting" && (
                  <div className="space-y-3 text-sm text-emerald-700">
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Measure your balcony space and check building regulations</span>
                    </div>
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Select compact, enclosed composting system with tight lids</span>
                    </div>
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Install proper drainage system to prevent water damage</span>
                    </div>
                    <div className="flex items-start gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>Create maintenance schedule to prevent odor complaints</span>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Action Buttons */}
            <div className="space-y-3">
              <Button className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-3 rounded-xl shadow-lg">
                <Play className="w-5 h-5 mr-2" />
                Start Reading Guide
              </Button>
              <div className="grid grid-cols-2 gap-3">
                <Button variant="outline" className="border-green-200 text-green-700 hover:bg-green-50 bg-transparent">
                  <Download className="w-4 h-4 mr-2" />
                  Download PDF
                </Button>
                <Button variant="outline" className="border-green-200 text-green-700 hover:bg-green-50 bg-transparent">
                  <Share2 className="w-4 h-4 mr-2" />
                  Share Guide
                </Button>
              </div>
            </div>

            {/* Related Guides */}
            <Card className="bg-white/80 backdrop-blur-sm border-green-200">
              <CardHeader className="pb-3">
                <h3 className="font-semibold text-green-800">Related Guides</h3>
              </CardHeader>
              <CardContent className="pt-0 space-y-3">
                {guides
                  .filter((g) => g.id !== selectedGuide)
                  .slice(0, 2)
                  .map((relatedGuide) => (
                    <div
                      key={relatedGuide.id}
                      className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors cursor-pointer"
                      onClick={() => {
                        setSelectedGuide(relatedGuide.id)
                      }}
                    >
                      <img
                        src={relatedGuide.image || "/placeholder.svg"}
                        alt={relatedGuide.title}
                        className="w-12 h-12 object-cover rounded-lg"
                      />
                      <div className="flex-1">
                        <h4 className="font-medium text-green-800 text-sm line-clamp-1">{relatedGuide.title}</h4>
                        <div className="flex items-center gap-2 text-xs text-gray-500 mt-1">
                          <Badge variant="outline" className="text-xs">
                            {relatedGuide.category}
                          </Badge>
                          <span>{relatedGuide.readTime}</span>
                        </div>
                      </div>
                      <ArrowRight className="w-4 h-4 text-gray-400" />
                    </div>
                  ))}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    )
  }

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

            <ScrollArea className="h-96">
              <div className="space-y-4">
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
                              {entry.user
                                .split(" ")
                                .map((n) => n[0])
                                .join("")}
                            </AvatarFallback>
                          </Avatar>
                          <div
                            className={`absolute -bottom-1 -right-1 w-6 h-6 rounded-full flex items-center justify-center ${
                              entry.type === "greens"
                                ? "bg-green-500"
                                : entry.type === "browns"
                                  ? "bg-amber-500"
                                  : entry.type === "maintenance"
                                    ? "bg-blue-500"
                                    : "bg-orange-500"
                            }`}
                          >
                            {entry.type === "greens" && <Leaf className="w-3 h-3 text-white" />}
                            {entry.type === "browns" && <Coffee className="w-3 h-3 text-white" />}
                            {entry.type === "maintenance" && <RotateCcw className="w-3 h-3 text-white" />}
                            {entry.type === "monitoring" && <Thermometer className="w-3 h-3 text-white" />}
                          </div>
                        </div>

                        <div className="flex-1">
                          <div className="flex justify-between items-start mb-2">
                            <div>
                              <h4 className="font-semibold text-green-800 text-sm">{entry.action}</h4>
                              <p className="text-xs text-gray-600">by {entry.user}</p>
                            </div>
                            <span className="text-xs text-gray-500">{entry.time}</span>
                          </div>

                          <p className="text-sm text-gray-700 mb-3">{entry.details}</p>

                          {entry.photos.length > 0 && (
                            <div className="flex gap-2 mb-3">
                              {entry.photos.map((photo, i) => (
                                <img
                                  key={i}
                                  src={photo || "/placeholder.svg"}
                                  alt="Activity photo"
                                  className="w-16 h-16 object-cover rounded-lg border border-gray-200"
                                />
                              ))}
                            </div>
                          )}

                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3 text-xs text-gray-500">
                              <span className="flex items-center gap-1">
                                <Thermometer className="w-3 h-3" />
                                {entry.temp}°C
                              </span>
                              <span className="flex items-center gap-1">
                                <Droplets className="w-3 h-3" />
                                {entry.moisture}
                              </span>
                            </div>
                            <Button variant="ghost" size="sm" className="text-gray-500 hover:text-red-500">
                              <Heart className="w-4 h-4 mr-1" />
                              {entry.likes}
                            </Button>
                          </div>
                        </div>
                      </div>

                      {index < journalEntries.length - 1 && (
                        <div className="absolute left-8 top-16 w-px h-8 bg-gradient-to-b from-green-200 to-transparent"></div>
                      )}
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
            <CardContent className="space-y-6">
              {/* Activity Type Selection */}
              <div className="grid grid-cols-2 gap-3">
                <Button
                  variant="outline"
                  className="h-24 flex-col gap-2 bg-green-50 hover:bg-green-100 border-green-200"
                >
                  <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center">
                    <Leaf className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium">Add Greens</span>
                  <span className="text-xs text-gray-600">Kitchen scraps</span>
                </Button>
                <Button
                  variant="outline"
                  className="h-24 flex-col gap-2 bg-amber-50 hover:bg-amber-100 border-amber-200"
                >
                  <div className="w-10 h-10 bg-amber-500 rounded-full flex items-center justify-center">
                    <Coffee className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium">Add Browns</span>
                  <span className="text-xs text-gray-600">Dry materials</span>
                </Button>
                <Button variant="outline" className="h-24 flex-col gap-2 bg-blue-50 hover:bg-blue-100 border-blue-200">
                  <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                    <RotateCcw className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium">Turn Pile</span>
                  <span className="text-xs text-gray-600">Mix & aerate</span>
                </Button>
                <Button
                  variant="outline"
                  className="h-24 flex-col gap-2 bg-orange-50 hover:bg-orange-100 border-orange-200"
                >
                  <div className="w-10 h-10 bg-orange-500 rounded-full flex items-center justify-center">
                    <Thermometer className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium">Monitor</span>
                  <span className="text-xs text-gray-600">Check status</span>
                </Button>
              </div>

              <Separator />

              {/* Form Fields */}
              <div className="space-y-4">
                <div>
                  <Label htmlFor="details" className="text-sm font-semibold text-green-800 mb-2 block">
                    Activity Details
                  </Label>
                  <Textarea
                    id="details"
                    placeholder="Describe what you added or did (e.g., 2.5kg mixed vegetable scraps from weekend market)"
                    className="bg-white/70 border-green-200 focus:border-green-400 min-h-[80px]"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="temperature" className="text-sm font-semibold text-green-800 mb-2 block">
                      Temperature (°C)
                    </Label>
                    <Input
                      id="temperature"
                      type="number"
                      placeholder="45"
                      className="bg-white/70 border-green-200 focus:border-green-400"
                    />
                  </div>
                  <div>
                    <Label htmlFor="moisture" className="text-sm font-semibold text-green-800 mb-2 block">
                      Moisture Level
                    </Label>
                    <select className="w-full p-2 border border-green-200 rounded-md text-sm bg-white/70 focus:border-green-400 focus:outline-none">
                      <option>Good</option>
                      <option>Dry</option>
                      <option>Too Wet</option>
                      <option>Optimal</option>
                    </select>
                  </div>
                </div>

                {/* Photo Upload */}
                <div>
                  <Label className="text-sm font-semibold text-green-800 mb-2 block">Add Photos (Optional)</Label>
                  <div className="border-2 border-dashed border-green-300 rounded-lg p-6 text-center bg-green-50/50">
                    <Camera className="w-8 h-8 mx-auto text-green-600 mb-2" />
                    <p className="text-sm text-green-700 font-medium">Tap to add photos</p>
                    <p className="text-xs text-green-600 mt-1">Help others see your progress</p>
                  </div>
                </div>
              </div>

              <Separator />

              {/* Action Buttons */}
              <div className="space-y-3">
                <Button
                  onClick={() => setCurrentScreen("journal")}
                  className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-3 rounded-xl shadow-lg"
                >
                  <CheckCircle2 className="w-5 h-5 mr-2" />
                  Save Entry
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
