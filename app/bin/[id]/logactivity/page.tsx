"use client";
import { useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { Button } from "@/components/ui/button";
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
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  // Action buttons
  const handleAction = (action: string) => {
    setType(action);
    setTemperature("");
    setMoisture("");
    if (action === "Turn Pile") setContent("Turned the pile");
    if (action === "Add Greens") setContent("Added greens (kitchen scraps)");
    if (action === "Add Browns") setContent("Added browns (dry materials)");
    if (action === "Monitor") setContent("Checked status");
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setImageFile(e.target.files[0]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setSuccess(false);
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
          setError(uploadError.message || "Failed to upload image");
          setLoading(false);
          return;
        }
        const { data: publicUrlData } = supabase.storage.from('bin-logs').getPublicUrl(filePath);
        imageUrl = publicUrlData.publicUrl;
      }
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
          temperature: type === "Monitor" ? (temperature ? parseInt(temperature) : null) : null,
          moisture: type === "Monitor" ? moisture : null,
          type,
          image: imageUrl,
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || "Failed to log activity");
      setSuccess(true);
      setTimeout(() => router.push(`/bin/${binId}`), 1200);
    } catch (err: any) {
      setError(err.message || "Failed to log activity");
      return NextResponse.json({ error: err.message || String(err) }, { status: 500 });
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md w-full p-4 bg-white rounded-xl shadow-lg border border-green-100">
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
                  ? "bg-gradient-to-r from-green-500 to-emerald-500 text-white border-green-600 font-bold"
                  : "bg-green-50 text-green-800 border-green-200"}
                transition-all duration-150
              `}
              style={{ minHeight: 120 }}
              onClick={() => handleAction(btn.label)}
            >
              <span className="flex items-center justify-center">{btn.icon}</span>
              {btn.label}
              <span className="text-base text-gray-500">{btn.desc}</span>
            </Button>
          ))}
        </div>
        <form className="space-y-6" onSubmit={handleSubmit}>
          {/* Show Temperature and Moisture only if Monitor is selected */}
          {type === "Monitor" && (
            <div className="grid grid-cols-1 gap-4">
              <div>
                <label className="block text-green-800 font-semibold mb-1 text-lg">Temperature (°C)</label>
                <input
                  type="number"
                  value={temperature}
                  onChange={e => setTemperature(e.target.value)}
                  placeholder="Enter temperature"
                  min={0}
                  max={100}
                  step={1}
                  className="w-full border-2 border-green-200 rounded-xl px-4 py-3 text-2xl text-center focus:outline-none focus:ring-2 focus:ring-green-300 bg-green-50 text-green-900"
                  style={{ fontSize: "2rem" }}
                  required
                />
              </div>
              <div>
                <label className="block text-green-800 font-semibold mb-1 text-lg">Moisture Level</label>
                <select
                  className="w-full border-2 border-green-200 rounded-xl px-4 py-3 text-2xl text-center focus:outline-none focus:ring-2 focus:ring-green-300 bg-green-50 text-green-900"
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
            <label className="block text-green-800 font-semibold mb-1 text-lg">
              Activity Details <span className="font-normal text-gray-500">(Optional)</span>
            </label>
            <Textarea
              value={content}
              onChange={e => setContent(e.target.value)}
              placeholder="Describe what you added or did (e.g., 2.5kg mixed vegetable scraps from weekend market)"
              className="w-full border-2 border-green-200 rounded-xl px-4 py-3 text-lg focus:outline-none focus:ring-2 focus:ring-green-300 bg-green-50 text-green-900"
            />
          </div>
          <div>
            <label className="block text-green-800 font-semibold mb-1 text-lg">Add Photos (Optional)</label>
            <label className="flex flex-col items-center justify-center border-2 border-dashed border-green-200 rounded-xl p-6 cursor-pointer hover:bg-green-50">
              <Camera className="w-10 h-10 text-green-400 mb-2" />
              <span className="text-green-800 font-medium">Tap to add photos</span>
              <span className="text-xs text-green-400">Help others see your progress</span>
              <input type="file" accept="image/*" className="hidden" onChange={handleImageChange} />
            </label>
            {imageFile && <div className="text-green-800 text-xs mt-2">Selected: {imageFile.name}</div>}
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
              className="w-full text-lg py-4 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white rounded-full shadow-md border-none"
              disabled={loading}
            >
              {loading ? "Saving..." : "Save Entry"}
            </Button>
            <Button
              type="button"
              variant="outline"
              className="w-full border-2 border-green-200 text-green-800 rounded-full py-4"
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