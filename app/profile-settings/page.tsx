"use client";
import { useState, useEffect, ChangeEvent, useRef } from "react";
import { supabase } from "@/lib/supabaseClient";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Label } from "@/components/ui/label";
import { useRouter } from "next/navigation";
import { LogOut } from "lucide-react";

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
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState<string>("");
  const [email, setEmail] = useState("");
  const [notifications, setNotifications] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [success, setSuccess] = useState("");
  const [error, setError] = useState("");
  const [editing, setEditing] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();
  const [logCount, setLogCount] = useState(0);
  const [taskCount, setTaskCount] = useState(0);

  useEffect(() => {
    const getUser = async () => {
      const { data } = await supabase.auth.getUser();
      setUser(data.user);
      setFirstName(data.user?.user_metadata?.first_name || "");
      setLastName(data.user?.user_metadata?.last_name || "");
      setAvatarUrl(data.user?.user_metadata?.avatar_url || "");
      setEmail(data.user?.email || "");
      setNotifications(data.user?.user_metadata?.notifications !== false); // default true
      if (data.user?.id) {
        const { data: profile } = await supabase.from('profiles').select('first_name, last_name, avatar_url').eq('id', data.user.id).single();
        if (profile) {
          setFirstName(profile.first_name || "");
          setLastName(profile.last_name || "");
          setAvatarUrl(profile.avatar_url || "");
        }
        // Fetch log count
        const { count: logs } = await supabase.from('bin_logs').select('*', { count: 'exact', head: true }).eq('user_id', data.user.id);
        setLogCount(logs || 0);
        // Fetch task count
        const { count: tasks } = await supabase.from('tasks').select('*', { count: 'exact', head: true }).eq('user_id', data.user.id);
        setTaskCount(tasks || 0);
      }
    };
    getUser();
  }, []);

  // Redirect not-logged-in users to /
  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user) router.replace('/');
    });
  }, [router]);

  const handleFirstNameChange = (e: ChangeEvent<HTMLInputElement>) => {
    setFirstName(e.target.value);
  };

  const handleLastNameChange = (e: ChangeEvent<HTMLInputElement>) => {
    setLastName(e.target.value);
  };

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
    const { error: updateError } = await supabase.auth.updateUser({
      data: { first_name: firstName, last_name: lastName, avatar_url: avatarUrl, notifications },
    });
    if (user?.id) {
      await supabase.from('profiles').upsert({
        id: user.id,
        first_name: firstName,
        last_name: lastName
      });
    }
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
    <div className="min-h-screen bg-[#F3F3F3] flex flex-col items-center justify-center">
      <div className="relative w-full max-w-md flex flex-col items-center justify-center min-h-[600px]">
        {/* Back button */}
        <button
          onClick={() => router.push('/main')}
          className="absolute top-6 left-6 bg-white rounded-full p-2 shadow hover:bg-[#F3F3F3] z-20"
          aria-label="Back"
        >
          <svg xmlns="http://www.w3.org/2000/svg" className="w-6 h-6 text-[#00796B]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        {/* Card with gradient and avatar */}
        <div className="w-full flex flex-col items-center">
          <div className="relative w-full flex flex-col items-center">
            {/* Gradient */}
            <div className="absolute top-0 left-0 w-full h-36 bg-gradient-to-b from-[#00796B] to-[#43cea2] rounded-t-3xl z-15" />
            {/* Avatar */}
            <div className="absolute left-1/2 top-18 transform -translate-x-1/2 -translate-y-1/2 z-20" style={{ marginTop: 0 }}>
              <Avatar className="w-28 h-28 border-4 border-white shadow-lg">
                <AvatarImage src={avatarUrl || "/placeholder.svg?height=80&width=80"} />
                <AvatarFallback className="bg-[#F3F3F3] text-[#00796B] text-3xl">
                  {getInitials(firstName + ' ' + lastName, email)}
                </AvatarFallback>
              </Avatar>
            </div>
            {/* Card content */}
            <div className="bg-white rounded-3xl shadow-xl w-full pt-24 pb-8 px-6 flex flex-col items-center relative z-10 mt-14">
              <div className="text-2xl font-bold text-[#00796B] mt-2 mb-1 text-center">{firstName} {lastName}</div>
              <div className="text-gray-500 text-base mb-4 text-center">{email}</div>
              <div className="flex gap-12 my-4">
                <div className="flex flex-col items-center">
                  <span className="text-2xl font-bold text-[#00796B]">{logCount}</span>
                  <span className="text-sm text-gray-500">Logs</span>
                </div>
                <div className="flex flex-col items-center">
                  <span className="text-2xl font-bold text-[#00796B]">{taskCount}</span>
                  <span className="text-sm text-gray-500">Tasks</span>
                </div>
              </div>
              <Button className="bg-[#00796B] text-white rounded-full px-8 py-3 font-semibold text-lg mb-4 w-3/4" onClick={() => router.push('/profile-settings/edit')}>
                Edit Profile
              </Button>
              <Button type="button" className="w-3/4 bg-red-500 hover:bg-red-600 text-white rounded-full py-3 font-semibold text-lg" onClick={handleLogout}>Log Out</Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 