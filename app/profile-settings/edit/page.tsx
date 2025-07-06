"use client";
import { useState, useEffect, ChangeEvent, useRef } from "react";
import { supabase } from "@/lib/supabaseClient";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useRouter } from "next/navigation";
import { Pencil } from "lucide-react";

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

export default function EditProfile() {
  const [user, setUser] = useState<any>(null);
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState<string>("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [uploading, setUploading] = useState(false);
  const [success, setSuccess] = useState("");
  const [error, setError] = useState("");
  const fileInputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  useEffect(() => {
    const getUser = async () => {
      const { data } = await supabase.auth.getUser();
      setUser(data.user);
      setFirstName(data.user?.user_metadata?.first_name || "");
      setLastName(data.user?.user_metadata?.last_name || "");
      setAvatarUrl(data.user?.user_metadata?.avatar_url || "");
      setEmail(data.user?.email || "");
      if (data.user?.id) {
        const { data: profile } = await supabase.from('profiles').select('first_name, last_name, avatar_url').eq('id', data.user.id).single();
        if (profile) {
          setFirstName(profile.first_name || "");
          setLastName(profile.last_name || "");
          setAvatarUrl(profile.avatar_url || "");
        }
      }
    };
    getUser();
  }, []);

  const handleAvatarChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;
    setUploading(true);
    setError("");
    setSuccess("");
    const fileExt = file.name.split('.').pop();
    const filePath = `${user.id}.${fileExt}`;
    const { error: uploadError } = await supabase.storage.from('avatars').upload(filePath, file, { upsert: true });
    if (uploadError) {
      if (uploadError.message && uploadError.message.includes('400')) {
        setError("File too large or wrong format");
      } else {
        setError("Failed to upload image");
      }
      setUploading(false);
      return;
    }
    const { data } = supabase.storage.from('avatars').getPublicUrl(filePath);
    setAvatarUrl(data.publicUrl);
    setUploading(false);
    setSuccess("Profile picture updated!");
    await supabase.from('profiles').update({ avatar_url: data.publicUrl }).eq('id', user.id);
    await supabase.auth.updateUser({
      data: { avatar_url: data.publicUrl }
    });
  };

  const handleAvatarButtonClick = () => {
    fileInputRef.current?.click();
  };

  const handleSave = async () => {
    setError("");
    setSuccess("");
    let updateError = null;
    if (password) {
      const { error } = await supabase.auth.updateUser({ password });
      if (error) updateError = error;
    }
    const { error: metaError } = await supabase.auth.updateUser({
      data: { first_name: firstName, last_name: lastName, avatar_url: avatarUrl },
    });
    if (user?.id) {
      await supabase.from('profiles').upsert({
        id: user.id,
        first_name: firstName,
        last_name: lastName,
        avatar_url: avatarUrl
      });
    }
    if (updateError || metaError) {
      setError("Failed to update profile");
    } else {
      setSuccess("Profile updated!");
      setTimeout(() => router.push('/profile-settings'), 1000);
    }
  };

  return (
    <div className="min-h-screen bg-[#F3F3F3] flex flex-col items-center justify-center">
      <div className="relative w-full max-w-md flex flex-col items-center justify-center min-h-[600px]">
        {/* Back button */}
        <button
          onClick={() => router.push('/profile-settings')}
          className="absolute top-6 left-6 bg-white rounded-full p-2 shadow hover:bg-[#F3F3F3] z-20"
          aria-label="Back"
        >
          <svg xmlns="http://www.w3.org/2000/svg" className="w-6 h-6 text-[#00796B]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        {/* Avatar with pencil/camera icon */}
        <div className="flex flex-col items-center w-full mt-16 mb-6">
          <div className="relative">
            <Avatar className="w-28 h-28 border-4 border-white shadow-lg">
              <AvatarImage src={avatarUrl || "/placeholder.svg?height=80&width=80"} />
              <AvatarFallback className="bg-[#F3F3F3] text-[#00796B] text-3xl">
                {getInitials(firstName + ' ' + lastName, email)}
              </AvatarFallback>
            </Avatar>
            <button
              type="button"
              onClick={handleAvatarButtonClick}
              className="absolute bottom-2 right-2 bg-[#00796B] rounded-full p-2 shadow hover:bg-[#005B4F]"
              aria-label="Change profile picture"
            >
              <Pencil className="w-5 h-5 text-white" />
            </button>
            <input
              type="file"
              accept="image/*"
              onChange={handleAvatarChange}
              disabled={uploading}
              ref={fileInputRef}
              className="hidden"
            />
          </div>
          {uploading && <div className="text-xs text-[#00796B] mt-2">Uploading...</div>}
          {error && <div className="text-red-600 text-sm mt-2">{error}</div>}
          {success && <div className="text-green-700 text-sm mt-2">{success}</div>}
        </div>
        {/* Editable fields */}
        <div className="bg-white rounded-3xl shadow-xl w-full px-6 py-8 flex flex-col items-center">
          <div className="w-full mb-4">
            <label className="block text-[#00796B] font-semibold mb-1">First Name</label>
            <Input value={firstName} onChange={e => setFirstName(e.target.value)} placeholder="First Name" />
          </div>
          <div className="w-full mb-4">
            <label className="block text-[#00796B] font-semibold mb-1">Last Name</label>
            <Input value={lastName} onChange={e => setLastName(e.target.value)} placeholder="Last Name" />
          </div>
          <div className="w-full mb-4">
            <label className="block text-[#00796B] font-semibold mb-1">Email</label>
            <Input value={email} readOnly className="bg-gray-100 cursor-not-allowed" />
          </div>
          <div className="w-full mb-6">
            <label className="block text-[#00796B] font-semibold mb-1">Password</label>
            <Input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="New Password (optional)" />
          </div>
          <Button className="bg-[#00796B] text-white rounded-full px-8 py-3 font-semibold text-lg w-full" onClick={handleSave} disabled={uploading}>
            Save Changes
          </Button>
        </div>
      </div>
    </div>
  );
} 