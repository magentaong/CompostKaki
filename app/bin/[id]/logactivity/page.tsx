"use client";
import { useState, useEffect } from "react";
import { useRouter, useParams } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Camera, RefreshCw, Thermometer, Plus, Leaf, Droplets } from "lucide-react";
import { NextResponse } from "next/server";
import { apiFetch } from "@/lib/apiFetch";

const MOISTURE_OPTIONS = ["Very Dry", "Dry", "Perfect", "Wet", "Very Wet"];

export default function LogActivityPage() {
  const router = useRouter();
  const params = useParams();
  const binId = params?.id as string;
  const [binName, setBinName] = useState("Bin");
  const [content, setContent] = useState("");
  const [temperature, setTemperature] = useState("");
  const [moisture, setMoisture] = useState("");
  const [type, setType] = useState("");
  const [weight, setWeight] = useState("");
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  const [materialsChecked, setMaterialsChecked] = useState({
    greens: false,
    browns: false,
    water: false,
  });

  // Redirect not-logged-in users to /
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user) router.replace('/');
    });
  }, [router]);


  useEffect(() => {
    if (!binId) return;
    apiFetch(`/api/bins/${binId}`)
      .then(res => res.json())
      .then(data => setBinName(data.bin?.name || "Bin"));
  }, [binId]);

  // Action buttons
  const handleAction = (action: string) => {
    setType(action);
    if (action === "Turn Pile") setContent("Turned the pile");
    if (action === "Add Materials") setContent("Added materials: greens, browns and water");
    if (action === "Add Water") setContent("Added water to the bin");
    if (action === "Monitor") setContent("Checked status");
  };

  // block submit until all checked
  const canSubmit =
    !!type && // must have selected an activity
    !loading &&
    (
      (type === "Add Materials" && Object.values(materialsChecked).every(Boolean)) ||
      (type !== "Add Materials")
    );

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

// ...existing imports and logic...

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#F3F3F3]">
      <div className="max-w-md w-full p-4 bg-white rounded-xl shadow-lg border border-[#E0E0E0]">
        {/* Header */}
        <div className="bg-white border-b border-gray-100 p-2 sticky top-0 z-10">
          <div className="flex items-center gap-3 mb-2">
            <Button
              variant="ghost"
              size="sm"
              className="text-[#00796B] hover:bg-[#F3F3F3]"
              onClick={() => router.push(`/bin/${binId}`)}
            >
              <svg width="28" height="28" fill="none" stroke="#00796B" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"/></svg>
              <span className="text-[#00796B] text-lg font-semibold cursor-pointer select-none" onClick={() => router.push(`/bin/${binId}`)}>Back</span>
            </Button>
          </div>
          <h1 className="text-xl font-bold text-gray-900 text-center">{binName}</h1>
        </div>
        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-4 mb-8">
          {[
            { label: "Add Materials", icon: <Leaf className="w-12 h-12 text-green-600" /> },
            { label: "Add Water", icon: <Droplets className="w-12 h-12 text-green-600" /> },
            { label: "Turn Pile", icon: <RefreshCw className="w-12 h-12 text-green-600" /> },
            { label: "Monitor", icon: <Thermometer className="w-12 h-12 text-green-600" /> },
          ].map(btn => (
            <Button
              key={btn.label}
              type="button"
              className={`
                flex flex-col gap-2 py-8 text-xl rounded-lg font-semibold px-6 shadow-md
                ${type === btn.label
                  ? "bg-[#00796B] text-white"
                  : "bg-[#E6F4EA] text-[#00796B]"}
                transition-all duration-150
              `}
              style={{ minHeight: 120 }}
              onClick={() => handleAction(btn.label)}
            >
              <span className="flex items-center justify-center">{btn.icon}</span>
              {btn.label}
            </Button>
          ))}
        </div>
        <form className="space-y-6" onSubmit={handleSubmit}>
        {/* Instructions Section */}
        {!type && (
          <div className="mb-6">
            <div className="flex items-center gap-2 bg-[#F8FAF9] border border-[#E0E0E0] rounded-lg px-4 py-3">
              <svg width="22" height="22" fill="none" stroke="#7CB8A2" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10" />
                <path d="M12 16v-4" />
                <path d="M12 8h.01" />
              </svg>
              <span className="text-[#4B8378] text-base font-medium">
                Please select one of the activities above before logging your activity.
              </span>
            </div>
          </div>
        )}
        {/* Type Selection */}
        {type === "Add Materials" && (
          <div className="mb-4">
            <div className="bg-[#F3F3F3] border border-[#B2DFDB] rounded-lg p-4">
              <div className="font-semibold text-[#00796B] mb-4 text-base flex items-center gap-2">
                <Plus className="w-5 h-5 text-[#00796B]" />
                I have added the following (must add all three before logging):
              </div>
              <div className="space-y-3">
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={materialsChecked.greens}
                    onChange={e => setMaterialsChecked(c => ({ ...c, greens: e.target.checked }))}
                    className="accent-[#00796B] w-5 h-5 rounded border-2 border-[#B2DFDB] group-hover:border-[#00796B] transition"
                  />
                  <span className="text-[#00796B] text-base">Greens <span className="text-gray-500 text-sm">(e.g. fresh leaves, compostable food waste)</span></span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={materialsChecked.browns}
                    onChange={e => setMaterialsChecked(c => ({ ...c, browns: e.target.checked }))}
                    className="accent-[#00796B] w-5 h-5 rounded border-2 border-[#B2DFDB] group-hover:border-[#00796B] transition"
                  />
                  <span className="text-[#00796B] text-base">Browns <span className="text-gray-500 text-sm">(e.g. dry leaves)</span></span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={materialsChecked.water}
                    onChange={e => setMaterialsChecked(c => ({ ...c, water: e.target.checked }))}
                    className="accent-[#00796B] w-5 h-5 rounded border-2 border-[#B2DFDB] group-hover:border-[#00796B] transition"
                  />
                  <span className="text-[#00796B] text-base">Water</span>
                </label>
              </div>
            </div>
          </div>
          )}
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
                  className="w-full border-2 border-[#00796B] rounded-xl px-4 py-3 text-2xl text-center focus:outline-none focus:ring-2 focus:ring-[#00796B] bg-[#F3F3F3] text-[#00796B] h-14"
                  required
                />
              </div>
              <div>
                <label className="block text-[#00796B] font-semibold mb-1 text-lg">Moisture Level</label>
                <select
                  className="w-full border-2 border-[#00796B] rounded-xl px-4 py-3 text-2xl text-center focus:outline-none focus:ring-2 focus:ring-[#00796B] bg-[#F3F3F3] text-[#00796B] h-14"
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
              Activity Details (Optional)
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
            <label className="flex flex-col items-center justify-center border-2 border-dashed border-[#00796B] rounded-xl p-6 cursor-pointer hover:bg-[#F3F3F3]">
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
              className="w-full text-lg py-4 bg-[#00796B] hover:bg-[#005B4F] text-white rounded-lg shadow-md border-none font-semibold"
              disabled={!canSubmit || loading}
            >
              {loading ? "Logging..." : "Log Activity"}
            </Button>
            <Button
              type="button"
              variant="outline"
              className="w-full border-2 border-[#00796B] text-[#00796B] bg-white rounded-lg py-4 text-lg font-semibold transition-colors duration-150 hover:bg-[#F3F3F3] hover:border-[#005B4F] focus:bg-[#F3F3F3] focus:border-[#005B4F]"
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