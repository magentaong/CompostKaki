"use client";
import { useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Camera, RefreshCw, Thermometer, Plus, Leaf } from "lucide-react";
import { NextResponse } from "next/server";

const MOISTURE_OPTIONS = ["Very Dry", "Dry", "Perfect", "Wet", "Very Wet"];

export default function LogActivityPage() {
  const router = useRouter();
  const params = useParams();
  const binId = params?.id as string;
  const [content, setContent] = useState("");
  const [temperature, setTemperature] = useState("");
  const [moisture, setMoisture] = useState("");
  const [type, setType] = useState("");
  const [weight, setWeight] = useState("");
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  // Action buttons
  const handleAction = (action: string) => {
    setType(action);
    if (action === "Turn Pile") setContent("Turned the pile");
    if (action === "Add Greens") setContent("Added greens (kitchen scraps)");
    if (action === "Add Browns") setContent("Added browns (dry materials)");
    if (action === "Monitor") setContent("Checked status");
  };

  // Handle image upload (for now, just store base64 string in a hidden field)
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setImageFile(e.target.files[0]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const user = await supabase.auth.getUser();
      const userId = user.data.user?.id;
      if (!userId) throw new Error("Not logged in");
      let imageUrl = null;
      if (imageFile) {
        const fileExt = imageFile.name.split('.').pop();
        const filePath = `${userId}_${Date.now()}.${fileExt}`;
        const { error: uploadError } = await supabase.storage.from('bin-logs').upload(filePath, imageFile, { upsert: true });
        if (uploadError) {
          console.error('Supabase upload error:', uploadError);
          setError(uploadError.message || "Failed to upload image");
          setLoading(false);
          return;
        }
        const { data: publicUrlData } = supabase.storage.from('bin-logs').getPublicUrl(filePath);
        imageUrl = publicUrlData.publicUrl;
      }
      // Use API route to insert log and update bin
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;
      const response = await fetch('/api/bins/logs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {})
        },
        body: JSON.stringify({
          bin_id: binId,
          content,
          temperature: temperature ? parseInt(temperature) : null,
          moisture: moisture || null,
          type,
          weight: weight ? parseFloat(weight) : null,
          image: imageUrl,
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || "Failed to log activity");
      setSuccess(true);
      router.push(`/bin/${binId}`);
    } catch (err: any) {
      setError(err.message || "Failed to log activity");
      return NextResponse.json({ error: err.message || String(err) }, { status: 500 });
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md w-full p-4 bg-white rounded-xl shadow-lg border border-green-100">
        {/* Back Button */}
        <div className="mb-2 flex items-center gap-1.5">
          <Button variant="ghost" size="icon" onClick={() => router.push(`/bin/${binId}`)}>
            <svg width="28" height="28" fill="none" stroke="#00796B" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"/></svg>
          </Button>
          <span className="text-[#00796B] text-lg font-semibold cursor-pointer select-none" onClick={() => router.push(`/bin/${binId}`)}>Back</span>
        </div>
        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-4 mb-8">
          {[
            { label: "Add Greens", icon: <Leaf className="w-12 h-12 text-green-600" />, desc: "Kitchen scraps" },
            { label: "Add Browns", icon: <Plus className="w-12 h-12 text-amber-600" />, desc: "Dry materials" },
            { label: "Turn Pile", icon: <RefreshCw className="w-12 h-12 text-blue-600" />, desc: "Mix & aerate" },
            { label: "Monitor", icon: <Thermometer className="w-12 h-12 text-orange-600" />, desc: "Check status" },
          ].map(btn => (
            <Button
              key={btn.label}
              type="button"
              variant="ghost"
              className={`
                flex flex-col gap-2 py-8 text-xl rounded-2xl border-2 shadow-md
                ${type === btn.label
                  ? "bg-[#00796B] text-white border-[#00796B] font-bold"
                  : "bg-green-50 text-[#00796B] border-[#00796B]"}
                transition-all duration-150
              `}
              style={{ minHeight: 120 }}
              onClick={() => handleAction(btn.label)}
            >
              <span className="flex items-center justify-center">{btn.icon}</span>
              {btn.label}
              <span className="text-base font-normal text-[#00796B]" style={{ fontFamily: 'inherit' }}>{btn.desc}</span>
            </Button>
          ))}
        </div>
        <form className="space-y-6" onSubmit={handleSubmit}>
          {/* Show Temperature and Moisture only if Monitor is selected */}
          {type === "Monitor" && (
            <div className="grid grid-cols-1 gap-4">
              <div>
                <label className="block text-[#00796B] font-semibold mb-1 text-lg">Temperature (°C)</label>
                <input
                  type="number"
                  value={temperature}
                  onChange={e => setTemperature(e.target.value)}
                  placeholder="Enter temperature"
                  min={0}
                  max={100}
                  step={1}
                  className="w-full border-2 border-[#00796B] rounded-xl px-4 py-3 text-2xl text-center focus:outline-none focus:ring-2 focus:ring-[#00796B] bg-green-50 text-[#00796B]"
                  style={{ fontSize: "2rem" }}
                  required
                />
              </div>
              <div>
                <label className="block text-[#00796B] font-semibold mb-1 text-lg">Moisture Level</label>
                <select
                  className="w-full border-2 border-[#00796B] rounded-xl px-4 py-3 text-2xl text-center focus:outline-none focus:ring-2 focus:ring-[#00796B] bg-green-50 text-[#00796B]"
                  value={moisture}
                  onChange={e => setMoisture(e.target.value)}
                  required
                >
                  <option value="">Select</option>
                  {MOISTURE_OPTIONS.map(opt => <option key={opt} value={opt}>{opt}</option>)}
                </select>
              </div>
            </div>
          )}
          <div>
            <label className="block text-[#00796B] font-semibold mb-1 text-lg">
              Activity Details <span className="font-normal text-gray-500">(Optional)</span>
            </label>
            <Textarea
              value={content}
              onChange={e => setContent(e.target.value)}
              placeholder="Describe what you added or did (e.g., 2.5kg mixed vegetable scraps from weekend market)"
              className="w-full border-2 border-[#00796B] rounded-xl px-4 py-3 text-base focus:outline-none focus:ring-2 focus:ring-[#00796B] bg-white text-[#00796B] placeholder:text-sm placeholder:text-gray-400"
              disabled={!type}
              style={{ fontSize: '1.1rem' }}
            />
          </div>
          <div>
            <label className="block text-[#00796B] font-semibold mb-1 text-lg">Add Photos (Optional)</label>
            <label className="flex flex-col items-center justify-center border-2 border-dashed border-[#00796B] rounded-xl p-6 cursor-pointer hover:bg-green-50">
              <Camera className="w-10 h-10 text-[#00796B] mb-2" />
              <span className="text-[#00796B] font-medium">Tap to add photos</span>
              <input type="file" accept="image/*" className="hidden" onChange={handleImageChange} />
            </label>
            {imageFile && <div className="text-[#00796B] text-xs mt-2">Selected: {imageFile.name}</div>}
          </div>
          {error && <div className="text-red-600 text-sm">{error}</div>}
          {success && (
            <div className="flex items-center justify-center text-green-700 font-bold text-lg">
              ✓ Activity logged!
            </div>
          )}
          <div className="flex flex-col gap-2">
            <Button
              type="submit"
              className="w-full text-lg py-4 bg-[#00796B] hover:bg-[#005B4F] text-white rounded-full shadow-md border-none font-semibold"
              disabled={loading}
            >
              {loading ? "Saving..." : "Save Entry"}
            </Button>
            <Button
              type="button"
              variant="outline"
              className="w-full border-2 border-red-500 text-white bg-red-500 rounded-full py-4 text-lg font-semibold transition-colors duration-150 hover:bg-[#b91c1c] hover:border-[#b91c1c] focus:bg-[#b91c1c] focus:border-[#b91c1c]"
              onClick={() => router.push(`/bin/${binId}`)}
            >
              Cancel
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
} 