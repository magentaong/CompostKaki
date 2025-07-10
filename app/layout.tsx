import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "CompostKaki",
  description:
    "Track and manage community composting projects with ease. Monitor temperature, moisture, and volunteer actions in real time.",
  applicationName: "CompostKaki",
  icons: {
  icon: "/favicon.ico",
  },
  keywords: [
    "Composting",
    "Sustainability",
    "Community",
    "Volunteer Tracking",
    "Circular Economy",
    "Waste Management",
  ],
  themeColor: "#80B543",
  colorScheme: "light",
  metadataBase: new URL("https://compostkaki.vercel.app"),
  openGraph: {
    title: "CompostKaki",
    description:
      "Empowering communities to compost better with real-time tracking and collaborative tools.",
    url: "https://compostKaki.vercel.app",
    siteName: "CompostKaki",
    locale: "en_SG",
    type: "website",
    images: [
      {
        url: "/og-image.png", // Replace this with an actual image :O
        width: 1200,
        height: 630,
      },
    ],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
