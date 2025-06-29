"use client";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { ArrowLeft, QrCode } from "lucide-react";

export default function ScannerPage() {
  const router = useRouter();
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md w-full p-8 bg-white rounded-xl shadow-lg text-center">
        <Button variant="ghost" size="sm" className="mb-4" onClick={() => router.push("/main")}> <ArrowLeft className="w-5 h-5" /> </Button>
        <QrCode className="w-16 h-16 mx-auto text-green-400 mb-4" />
        <h1 className="text-2xl font-bold text-green-800 mb-2">QR Scanner</h1>
        <p className="text-green-700 mb-4">QR Scanner coming soon...</p>
        <p className="text-gray-500">This page will let you scan a compost bin QR code to access its journal instantly.</p>
      </div>
    </div>
  );
} 