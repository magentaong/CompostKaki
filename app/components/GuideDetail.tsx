import React from 'react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { ArrowLeft, Share2, Bookmark, Clock, Heart, Eye, Target, BookOpen, ArrowRight, Zap, CheckCircle } from 'lucide-react';

interface GuideDetailProps {
  guide: any;
  relatedGuides: any[];
  onBack: () => void;
  onLike: (id: string) => void;
  onSelectRelated: (id: string) => void;
}

const GuideDetail: React.FC<GuideDetailProps> = ({ guide, relatedGuides, onBack, onLike, onSelectRelated }) => {
  if (!guide) return null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
          <div className="flex items-center gap-3 mb-3">
            <Button variant="ghost" size="sm" onClick={onBack}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div className="flex-1">
              <Badge className="bg-green-100 text-green-700 mb-1">{guide.category}</Badge>
              <h2 className="text-lg font-bold text-green-800 line-clamp-2">{guide.title}</h2>
            </div>
            <div className="flex gap-1">
              <Button variant="ghost" size="sm">
                <Share2 className="w-4 h-4" />
              </Button>
              <Button variant="ghost" size="sm">
                <Bookmark className="w-4 h-4" />
              </Button>
            </div>
          </div>
          <div className="flex items-center justify-between text-sm text-gray-600">
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1">
                <Avatar className="w-6 h-6">
                  <AvatarFallback className="bg-green-100 text-green-700 text-xs">
                    {guide.author && guide.author.split(' ').map((n: string) => n[0]).join('')}
                  </AvatarFallback>
                </Avatar>
                <span className="text-xs">{guide.author}</span>
              </div>
              <span className="flex items-center gap-1">
                <Clock className="w-3 h-3" />
                {guide.read_time}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <Button variant="ghost" size="sm" className="text-red-500 hover:text-red-600" onClick={() => onLike(guide.id)}>
                <Heart className="w-4 h-4 mr-1" />
                {guide.likes}
              </Button>
            </div>
          </div>
        </div>
        <div className="p-4 space-y-6">
          {/* Hero Image */}
          <div className="relative">
            <img
              src={guide.image || "/placeholder.svg"}
              alt={guide.title}
              className="w-full h-48 object-cover rounded-xl"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent rounded-xl"></div>
          </div>
          {/* Overview */}
          <Card className="bg-white/90 backdrop-blur-sm border-green-200">
            <CardContent className="p-4">
              <h3 className="font-semibold text-green-800 mb-2">What you'll learn</h3>
              <p className="text-gray-700 text-sm leading-relaxed mb-3">{guide.description}</p>
              <div className="flex items-center gap-4 text-sm text-gray-600">
                <div className="flex items-center gap-1">
                  <Target className="w-4 h-4 text-green-600" />
                  <span>{guide.difficulty}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Eye className="w-4 h-4 text-blue-600" />
                  <span>{guide.views} views</span>
                </div>
              </div>
            </CardContent>
          </Card>
          {/* Table of Contents */}
          <Card className="bg-white/90 backdrop-blur-sm border-green-200">
            <CardHeader className="pb-3">
              <h3 className="font-semibold text-green-800 flex items-center gap-2">
                <BookOpen className="w-5 h-5" />
                Table of Contents
              </h3>
            </CardHeader>
            <CardContent className="pt-0 space-y-3">
              {guide.sections && guide.sections.map((section: any, index: number) => (
                <div
                  key={index}
                  className="flex items-start gap-3 p-3 bg-green-50/50 rounded-lg hover:bg-green-50 transition-colors cursor-pointer"
                >
                  <div className="w-8 h-8 bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg flex items-center justify-center flex-shrink-0">
                    {section.icon ? <section.icon className="w-4 h-4 text-white" /> : <BookOpen className="w-4 h-4 text-white" />}
                  </div>
                  <div className="flex-1">
                    <h4 className="font-medium text-green-800 text-sm">{section.title}</h4>
                    <p className="text-xs text-gray-600 mt-1 line-clamp-2">{section.content}</p>
                  </div>
                  <ArrowRight className="w-4 h-4 text-gray-400 mt-1" />
                </div>
              ))}
            </CardContent>
          </Card>
          {/* Quick Start Preview (optional, can be customized) */}
          {guide.quickStart && (
            <Card className="bg-gradient-to-br from-emerald-50 to-teal-50 border-emerald-200">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-3">
                  <Zap className="w-5 h-5 text-emerald-600" />
                  <h3 className="font-semibold text-emerald-800">Quick Start Preview</h3>
                </div>
                <div className="space-y-3 text-sm text-emerald-700">
                  {guide.quickStart.map((item: string, idx: number) => (
                    <div className="flex items-start gap-2" key={idx}>
                      <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      <span>{item}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
          {/* Action Buttons */}
          <div className="space-y-3">
            <Button className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-3 rounded-xl shadow-lg">
              Start Reading Guide
            </Button>
            <div className="grid grid-cols-2 gap-3">
              <Button variant="outline" className="border-green-200 text-green-700 hover:bg-green-50 bg-transparent">
                Download PDF
              </Button>
              <Button variant="outline" className="border-green-200 text-green-700 hover:bg-green-50 bg-transparent">
                <Share2 className="w-4 h-4 mr-2" />
                Share Guide
              </Button>
            </div>
          </div>
          {/* Related Guides */}
          <Card className="bg-white/80 backdrop-blur-sm border-green-200">
            <CardHeader className="pb-3">
              <h3 className="font-semibold text-green-800">Related Guides</h3>
            </CardHeader>
            <CardContent className="pt-0 space-y-3">
              {relatedGuides.map((relatedGuide) => (
                <div
                  key={relatedGuide.id}
                  className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors cursor-pointer"
                  onClick={() => onSelectRelated(relatedGuide.id)}
                >
                  <img
                    src={relatedGuide.image || "/placeholder.svg"}
                    alt={relatedGuide.title}
                    className="w-12 h-12 object-cover rounded-lg"
                  />
                  <div className="flex-1">
                    <h4 className="font-medium text-green-800 text-sm line-clamp-1">{relatedGuide.title}</h4>
                    <div className="flex items-center gap-2 text-xs text-gray-500 mt-1">
                      <Badge variant="outline" className="text-xs">
                        {relatedGuide.category}
                      </Badge>
                      <span>{relatedGuide.read_time}</span>
                    </div>
                  </div>
                  <ArrowRight className="w-4 h-4 text-gray-400" />
                </div>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default GuideDetail; 