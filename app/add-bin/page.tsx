"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { ArrowLeft } from "lucide-react";
import QRCode from "qrcode";

export default function AddBinPage() {
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const router = useRouter();

  // Redirect not-logged-in users to /
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user) router.replace('/');
    });
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      // Get user
      const { data: userData } = await supabase.auth.getUser();
      const userId = userData.user?.id;
      if (!userId) throw new Error("Not logged in");
      // Insert bin
      const { data: bin, error: binError } = await supabase
        .from("bins")
        .insert({
          name,
          location: name,
          user_id: userId,
          contributors: 1,
          progress: 0,
          health_status: "Healthy",
        })
        .select()
        .single();
      console.log("BIN ERROR:", binError);
      if (binError || !bin) throw new Error(binError?.message || "Failed to create bin");
      // Generate QR code (URL to join bin)
      const qrValue = `${window.location.origin}/bin/${bin.id}`;
      const qrDataUrl = await QRCode.toDataURL(qrValue);
      // Save QR code to bin
      await supabase.from("bins").update({ qr_code: qrDataUrl }).eq("id", bin.id);
      // Redirect to bin page
      router.push(`/bin/${bin.id}`);
    } catch (err: any) {
      setError(err.message || "Failed to add bin");
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-[#F3F3F3] py-8">
      {/* Sticky header */}
      <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10 w-full max-w-md mx-auto flex items-center gap-3">
        <Button variant="ghost" size="sm" onClick={() => router.push("/main")}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <span className="text-xl font-bold bg-gradient-to-r from-green-700 to-emerald-600 bg-clip-text text-transparent">
          Add New Bin
        </span>
      </div>

      <div className="bg-[#E6FFF3] border border-[#00796B] text-[#00796B] rounded-lg px-4 py-3 mb-0 text-center text-base font-medium w-full max-w-md mx-auto flex items-center justify-center gap-2 mb-4 mt-6 shadow-[0_2px_8px_rgba(0,0,0,0.03)]">
        <span role="img" aria-label="plant">🪴</span>
        <span>
          If your community already has a bin, try <span className="font-semibold">joining it instead!</span>
        </span>
        <button
          className="ml-3 bg-[#00796B] text-white rounded-lg px-4 py-2 font-semibold text-sm shadow hover:bg-[#005B4F] transition whitespace-nowrap"
          onClick={() => router.push('/main?join=1')}
          type="button"
        >
          Join Bin
        </button>
      </div>

      <Card className="bg-white rounded-xl shadow-md p-8 w-full max-w-md mx-auto">
        <CardHeader className="rounded-t-xl">
          <h1 className="text-2xl font-bold text-[#00796B] mb-4 flex items-center gap-2">
            <span className="mr-1">Add New Bin</span>
          </h1>
          <p className="text-[#3E6F4B] text-sm mb-4">
            Tip: Name your bin after its location, e.g., <span className="font-semibold">Dakota Crescent</span>
          </p>
        </CardHeader>
        <CardContent>
          <form className="space-y-6" onSubmit={handleSubmit}>
            <div>
              <Label htmlFor="name">Bin Name</Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Dakota Crescent"
                required
                className="mt-3"
              />
            </div>
            {error && <div className="text-[#C0392B] text-sm">{error}</div>}
            <Button className="w-full bg-[#00796B] text-white hover:bg-[#005A4B] transition font-semibold rounded-lg py-3 mt-4" type="submit" disabled={loading}>
              {loading ? "Creating..." : "Create Bin"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
