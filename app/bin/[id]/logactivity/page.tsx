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
      router.push(`/bin/${binId}`);
    } catch (err: any) {
      setError(err.message || "Failed to log activity");
      return NextResponse.json({ error: err.message || String(err) }, { status: 500 });
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md w-full p-4 bg-white rounded-xl shadow-lg">
        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-3 mb-6">
          <Button variant={type === "Add Greens" ? "default" : "outline"} className="flex flex-col gap-1 py-6" onClick={() => handleAction("Add Greens")}> <Leaf className="w-6 h-6 text-green-600" /> Add Greens <span className="text-xs text-gray-500">Kitchen scraps</span> </Button>
          <Button variant={type === "Add Browns" ? "default" : "outline"} className="flex flex-col gap-1 py-6" onClick={() => handleAction("Add Browns")}> <Plus className="w-6 h-6 text-amber-600" /> Add Browns <span className="text-xs text-gray-500">Dry materials</span> </Button>
          <Button variant={type === "Turn Pile" ? "default" : "outline"} className="flex flex-col gap-1 py-6" onClick={() => handleAction("Turn Pile")}> <RefreshCw className="w-6 h-6 text-blue-600" /> Turn Pile <span className="text-xs text-gray-500">Mix & aerate</span> </Button>
          <Button variant={type === "Monitor" ? "default" : "outline"} className="flex flex-col gap-1 py-6" onClick={() => handleAction("Monitor")}> <Thermometer className="w-6 h-6 text-orange-600" /> Monitor <span className="text-xs text-gray-500">Check status</span> </Button>
        </div>
        <form className="space-y-6" onSubmit={handleSubmit}>
          <div>
            <h2 className="text-green-700 font-bold mb-2">Activity Details</h2>
            <Textarea value={content} onChange={e => setContent(e.target.value)} required placeholder="Describe what you added or did (e.g., 2.5kg mixed vegetable scraps from weekend market)" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-green-700 font-medium mb-1">Temperature (°C)</label>
              <Input type="number" value={temperature} onChange={e => setTemperature(e.target.value)} placeholder="e.g. 45" />
            </div>
            <div>
              <label className="block text-green-700 font-medium mb-1">Moisture Level</label>
              <select className="w-full border rounded px-3 py-2" value={moisture} onChange={e => setMoisture(e.target.value)}>
                <option value="">Select</option>
                {MOISTURE_OPTIONS.map(opt => <option key={opt} value={opt}>{opt}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="block text-green-700 font-medium mb-1">Weight (kg)</label>
            <Input type="number" value={weight} onChange={e => setWeight(e.target.value)} placeholder="e.g. 2.5" step="0.01" min="0" />
          </div>
          <div>
            <label className="block text-green-700 font-medium mb-1">Add Photos (Optional)</label>
            <label className="flex flex-col items-center justify-center border-2 border-dashed border-green-400 rounded-xl p-6 cursor-pointer hover:bg-green-50">
              <Camera className="w-8 h-8 text-green-500 mb-2" />
              <span className="text-green-700 font-medium">Tap to add photos</span>
              <span className="text-xs text-green-500">Help others see your progress</span>
              <input type="file" accept="image/*" className="hidden" onChange={handleImageChange} />
            </label>
            {imageFile && <div className="text-green-700 text-xs mt-2">Selected: {imageFile.name}</div>}
          </div>
          {error && <div className="text-red-600 text-sm">{error}</div>}
          <Button type="submit" className="w-full text-lg py-3" disabled={loading}>{loading ? "Saving..." : "Save Entry"}</Button>
          <Button type="button" variant="outline" className="w-full" onClick={() => router.push(`/bin/${binId}`)}>Cancel</Button>
        </form>
      </div>
    </div>
  );
} 