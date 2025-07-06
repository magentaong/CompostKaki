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

      <div className="bg-blue-50 border border-blue-200 text-blue-800 rounded-lg px-4 py-3 mb-4 text-center text-base font-medium max-w-xl mx-auto">
        If your community already has a bin, try <span className="font-semibold">joining it instead!</span>
      </div>

      <Card className="bg-white rounded-xl shadow-md p-8 max-w-xl mx-auto">
        <CardHeader>
          <h2 className="text-xl font-bold mb-6 text-green-800">Bin Details</h2>
          <p className="text-[#5F9133] text-sm mb-4">
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
            <Button
              type="submit"
              className="w-full bg-[#96CC4F] text-white hover:bg-[#7CAB38]"
              disabled={loading || !name.trim()}
            >
              {loading ? "Creating..." : "Create Bin"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
