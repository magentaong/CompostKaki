"use client";
import { useState, useEffect, ChangeEvent } from "react";
import { supabase } from "@/lib/supabaseClient";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Label } from "@/components/ui/label";
import { useRouter } from "next/navigation";

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

export default function ProfileSettings() {
  const [user, setUser] = useState<any>(null);
  const [name, setName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState<string>("");
  const [email, setEmail] = useState("");
  const [notifications, setNotifications] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [success, setSuccess] = useState("");
  const [error, setError] = useState("");
  const router = useRouter();

  useEffect(() => {
    const getUser = async () => {
      const { data } = await supabase.auth.getUser();
      setUser(data.user);
      setName(data.user?.user_metadata?.name || "");
      setAvatarUrl(data.user?.user_metadata?.avatar_url || "");
      setEmail(data.user?.email || "");
      setNotifications(data.user?.user_metadata?.notifications !== false); // default true
    };
    getUser();
  }, []);

  const handleNameChange = (e: ChangeEvent<HTMLInputElement>) => {
    setName(e.target.value);
  };

  const handleAvatarChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;
    setUploading(true);
    setError("");
    setSuccess("");
    const fileExt = file.name.split('.').pop();
    const filePath = `avatars/${user.id}.${fileExt}`;
    const { error: uploadError } = await supabase.storage.from('avatars').upload(filePath, file, { upsert: true });
    if (uploadError) {
      setError("Failed to upload image");
      setUploading(false);
      return;
    }
    const { data } = supabase.storage.from('avatars').getPublicUrl(filePath);
    setAvatarUrl(data.publicUrl);
    setUploading(false);
    setSuccess("Profile picture updated!");
  };

  const handleSave = async () => {
    setError("");
    setSuccess("");
    const { error: updateError } = await supabase.auth.updateUser({
      data: { name, avatar_url: avatarUrl, notifications },
    });
    if (updateError) {
      setError("Failed to update profile");
    } else {
      setSuccess("Profile updated!");
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push("/");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50 flex flex-col items-center justify-center">
      <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10 w-full max-w-md mx-auto">
        <button onClick={() => router.push("/")} className="mr-3 p-2 rounded hover:bg-green-100">
          <svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
        </button>
        <span className="text-xl font-bold text-green-800 align-middle">Profile Settings</span>
      </div>
      <Card className="max-w-md w-full p-6 mt-4">
        <CardHeader>
          <h2 className="text-xl font-bold mb-2 text-green-800">Profile Settings</h2>
        </CardHeader>
        <CardContent>
          <form className="space-y-6" onSubmit={e => { e.preventDefault(); handleSave(); }}>
            <div className="flex flex-col items-center gap-3">
              <Avatar className="w-20 h-20">
                <AvatarImage src={avatarUrl || "/placeholder.svg?height=80&width=80"} />
                <AvatarFallback className="bg-green-100 text-green-700 text-2xl">
                  {getInitials(name, email)}
                </AvatarFallback>
              </Avatar>
              <input type="file" accept="image/*" onChange={handleAvatarChange} disabled={uploading} />
              {uploading && <div className="text-xs text-green-700">Uploading...</div>}
            </div>
            <div>
              <Label htmlFor="name">Display Name</Label>
              <Input id="name" value={name} onChange={handleNameChange} placeholder="Your name" />
            </div>
            <div>
              <Label htmlFor="email">Email</Label>
              <Input id="email" value={email} readOnly className="bg-gray-100 cursor-not-allowed" />
            </div>
            <div className="flex items-center gap-3">
              <Label htmlFor="notifications">Email Notifications</Label>
              <input
                id="notifications"
                type="checkbox"
                checked={notifications}
                onChange={e => setNotifications(e.target.checked)}
                className="h-4 w-4 accent-green-600"
              />
            </div>
            {error && <div className="text-red-600 text-sm">{error}</div>}
            {success && <div className="text-green-700 text-sm">{success}</div>}
            <Button type="submit" className="w-full" disabled={uploading}>Save Changes</Button>
            <Button type="button" className="w-full bg-red-500 hover:bg-red-600 text-white mt-2" onClick={handleLogout}>Log Out</Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
} 