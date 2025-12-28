"use client";
import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { ArrowLeft, QrCode, Upload, Camera } from "lucide-react";
import { Html5Qrcode, Html5QrcodeScanner } from "html5-qrcode";
import { supabase } from "@/lib/supabaseClient";


export default function ScannerPage() {
  const router = useRouter();
  const [result, setResult] = useState<string | null>(null);
  const [error, setError] = useState("");
  const [scanning, setScanning] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const qrRegionId = "qr-reader-region";
  const html5QrCodeRef = useRef<InstanceType<typeof Html5Qrcode> | null>(null);

  // Start camera scan
  const startCamera = async () => {
    setError("");
    setResult(null);
    setScanning(true);
    try {
      if (!html5QrCodeRef.current) {
        html5QrCodeRef.current = new Html5Qrcode(qrRegionId);
      }
      await html5QrCodeRef.current.start(
        { facingMode: "environment" },
        {
          fps: 10,
          qrbox: { width: 250, height: 250 },
        },
        (decodedText: string) => {
          setResult(decodedText);
          html5QrCodeRef.current?.stop();
          setScanning(false);
          if (decodedText.includes("/bin/")) {
            const match = decodedText.match(/\/bin\/([a-zA-Z0-9\-]+)/);
            if (match && match[1]) {
              // Call join API before navigating
              const joinBin = async () => {
                try {
                  const { data: { session } } = await supabase.auth.getSession();
                  const token = session?.access_token;
                  await fetch('/api/bins/join', {
                    method: 'POST',
                    headers: {
                      'Content-Type': 'application/json',
                      ...(token ? { 'Authorization': `Bearer ${token}` } : {})
                    },
                    body: JSON.stringify({ binId: match[1] })
                  });
                } catch (e) { /* ignore */ }
                router.push(`/bin/${match[1]}`);
              };
              joinBin();
            }
          }
        },
        (err: unknown) => {
          // Ignore scan errors (happens frequently)
        }
      );
    } catch (err: any) {
      setError("Camera error: " + (err?.message || err));
      setScanning(false);
    }
  };

  // Stop camera scan
  const stopCamera = async () => {
    setScanning(false);
    try {
      await html5QrCodeRef.current?.stop();
    } catch {}
  };

  // Clean up on unmount
  useEffect(() => {
    return () => {
      html5QrCodeRef.current?.stop().catch(() => {});
      html5QrCodeRef.current?.clear().catch(() => {});
    };
  }, []);

  // Handle image upload
  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    setError("");
    setResult(null);
    const file = e.target.files?.[0];
    if (!file) return;
    
    try {
      // Ensure the container element exists
      let containerElement = document.getElementById(qrRegionId + "-img");
      if (!containerElement) {
        containerElement = document.createElement("div");
        containerElement.id = qrRegionId + "-img";
        containerElement.style.display = "none";
        document.body.appendChild(containerElement);
      }
      
      // Create Html5Qrcode instance and scan the file
      const html5QrCode = new Html5Qrcode(qrRegionId + "-img");
      const result = await html5QrCode.scanFile(file, true);
      
      // Clean up
      await html5QrCode.clear();
      
      setResult(result);
      if (result.includes("/bin/")) {
        const match = result.match(/\/bin\/([a-zA-Z0-9\-]+)/);
        if (match && match[1]) {
          // Call join API before navigating
          const joinBin = async () => {
            try {
              const { data: { session } } = await supabase.auth.getSession();
              const token = session?.access_token;
              await fetch('/api/bins/join', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  ...(token ? { 'Authorization': `Bearer ${token}` } : {})
                },
                body: JSON.stringify({ binId: match[1] })
              });
            } catch (e) { /* ignore */ }
            router.push(`/bin/${match[1]}`);
          };
          joinBin();
        } else {
          setError("Invalid QR code format. Expected a bin link.");
        }
      } else {
        setError("QR code does not contain a valid bin link.");
      }
    } catch (err: any) {
      console.error("QR scan error:", err);
      setError("Could not scan image: " + (err?.message || err || "Unknown error"));
    }
    
    // Reset file input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md w-full p-4 bg-white rounded-xl shadow-lg text-center">
        <Button variant="ghost" size="sm" className="mb-4" onClick={() => router.push("/main")}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <QrCode className="w-16 h-16 mx-auto text-green-400 mb-4" />
        <h1 className="text-2xl font-bold text-green-800 mb-2">QR Scanner</h1>
        <p className="text-green-700 mb-4">Scan a compost bin QR code below</p>
        <div className="mb-4">
          {!scanning ? (
            <Button className="flex items-center gap-2 justify-center" onClick={startCamera}>
              <Camera className="w-4 h-4" /> Start Camera Scan
            </Button>
          ) : (
            <Button className="flex items-center gap-2 justify-center" onClick={stopCamera} variant="destructive">
              Stop Camera
            </Button>
          )}
        </div>
        <div id={qrRegionId} className="mb-4 mx-auto" style={{ width: 260, minHeight: 260 }} />
        <div className="mb-4">
          <p className="text-gray-500">Or upload a QR code image:</p>
          <Button className="mt-2 flex items-center gap-2 justify-center" onClick={() => fileInputRef.current?.click()}>
            <Upload className="w-4 h-4" /> Upload from Photos
          </Button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleFileChange}
          />
          <div id={qrRegionId + "-img"} style={{ display: "none" }} />
        </div>
        {result && <div className="text-green-700 font-medium mt-2 break-all">Scanned: {result}</div>}
        {error && <div className="text-red-600 text-sm mt-2">{error}</div>}
      </div>
    </div>
  );
} 