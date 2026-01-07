"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import {CardContent} from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { supabase } from "@/lib/supabaseClient"
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
  const [selectedPile, setSelectedPile] = useState<string>("")
  const [isLoading, setIsLoading] = useState(false)
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [firstName, setFirstName] = useState("")
  const [lastName, setLastName] = useState("")
  const [session, setSession] = useState<any>(null)
  const [authError, setAuthError] = useState<string>("")
  const [pilesLoading, setPilesLoading] = useState(false)
  const [pilesError, setPilesError] = useState("")
  const [pileEntries, setPileEntries] = useState<any[]>([])
  const [pileEntriesLoading, setPileEntriesLoading] = useState(false)
  const [pileEntriesError, setPileEntriesError] = useState("")
  const [newPileName, setNewPileName] = useState("")
  const [newPileLocation, setNewPileLocation] = useState("")
  const [newPileImage, setNewPileImage] = useState("")
  const [newPileDescription, setNewPileDescription] = useState("")
  const [addPileLoading, setAddPileLoading] = useState(false)
  const [addPileError, setAddPileError] = useState("")
  const [piles, setPiles] = useState<any[]>([])
  const [showNotifications, setShowNotifications] = useState(false);
  const [step, setStep] = useState<"email" | "signin" | "signup">("email");
  const [emailExists, setEmailExists] = useState<boolean | null>(null);

  const router = useRouter();

  // Check for password reset token FIRST (before checking auth)
  // This must run before the auth check to prevent redirect to /main
  useEffect(() => {
    // Use window.location directly for immediate check (before React hydration)
    const urlParams = new URLSearchParams(window.location.search);
    const hash = window.location.hash;
    const token = urlParams.get('token') || urlParams.get('code');
    const type = urlParams.get('type');
    
    // If we have a recovery token, IMMEDIATELY redirect (don't wait)
    if (token && (type === 'recovery' || hash.includes('access_token'))) {
      console.log('🔐 [HOME PAGE] Password reset token detected, redirecting IMMEDIATELY');
      
      // Use window.location.href for immediate redirect (faster than router)
      if (token && type === 'recovery') {
        window.location.href = `/reset-password?token=${encodeURIComponent(token)}&type=${type}`;
        return;
      }
      if (hash && hash.includes('access_token')) {
        window.location.href = `/reset-password${hash}`;
        return;
      }
    }
  }, []); // Empty deps - run once on mount

  // Redirect logged-in users to /main (but only if no reset token)
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token') || urlParams.get('code');
    const type = urlParams.get('type');
    
    // Don't redirect if we have a reset token
    if (token && type === 'recovery') {
      return; // Let the reset flow handle it
    }
    
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


  // Fetch data on mount
  useEffect(() => {
    fetchPiles()
  }, [])

  // Fetch pile entries when selectedPile changes
  useEffect(() => {
    if (selectedPile) fetchPileEntries(selectedPile)
  }, [selectedPile])

  

  const handleScan = () => {
    // TODO: Implement scan logic or leave empty for now
  };

 

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

}
