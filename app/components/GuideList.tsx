import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Eye, Heart } from 'lucide-react';

interface GuideListProps {
  guides: any[];
  loading: boolean;
  error: string;
  search: string;
  filter: string;
  onSearch: (v: string) => void;
  onFilter: (v: string) => void;
  onSelect: (id: string) => void;
  onLike: (id: string) => void;
  onBack: () => void;
}

const GuideList: React.FC<GuideListProps> = ({
  guides,
  loading,
  error,
  search,
  filter,
  onSearch,
  onFilter,
  onSelect,
  onLike,
  onBack,
}) => {
  const filteredGuides = guides.filter((g) => {
    const matchesSearch =
      g.title.toLowerCase().includes(search.toLowerCase()) ||
      g.description.toLowerCase().includes(search.toLowerCase());
    const matchesFilter = filter === 'All' || g.category === filter;
    return matchesSearch && matchesFilter;
  });

  const categories = Array.from(new Set(guides.map((g) => g.category)));

  return (
    <div className="p-4 space-y-4">
      <div className="bg-white/80 backdrop-blur-sm border-b border-green-100 p-4 sticky top-0 z-10">
        <div className="flex items-center gap-3 mb-4">
          <Button variant="ghost" size="sm" onClick={onBack}>
            <svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </Button>
          <div>
            <h2 className="text-xl font-bold text-green-800">Composting Guides</h2>
            <p className="text-sm text-green-600">Complete step-by-step tutorials</p>
          </div>
        </div>
      </div>
      <div className="relative mb-2">
        <input
          type="text"
          placeholder="Search guides..."
          value={search}
          onChange={(e) => onSearch(e.target.value)}
          className="pl-10 pr-3 py-2 w-full rounded border border-green-200 bg-white/70 focus:border-green-400"
        />
      </div>
      <div className="flex gap-2 overflow-x-auto pb-2 mb-2">
        <Badge
          variant={filter === 'All' ? 'default' : 'outline'}
          className="whitespace-nowrap cursor-pointer"
          onClick={() => onFilter('All')}
        >
          All
        </Badge>
        {categories.map((cat: string) => (
          <Badge
            key={cat}
            variant={filter === cat ? 'default' : 'outline'}
            className="whitespace-nowrap cursor-pointer"
            onClick={() => onFilter(cat)}
          >
            {cat}
          </Badge>
        ))}
      </div>
      {loading && <div>Loading...</div>}
      {error && <div className="text-red-600 text-sm">{error}</div>}
      {filteredGuides.length === 0 && !loading && <div>No guides found.</div>}
      {filteredGuides.map((guide) => (
        <Card
          key={guide.id}
          className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg hover:shadow-xl transition-all duration-200 cursor-pointer"
          onClick={() => onSelect(guide.id)}
        >
          <CardContent className="p-0">
            <div className="relative">
              <img
                src={guide.image || "/placeholder.svg"}
                alt={guide.title}
                className="w-full h-48 object-cover rounded-t-lg"
              />
              <div className="absolute top-3 left-3">
                <Badge className="bg-white/90 text-green-700">{guide.category}</Badge>
              </div>
              <div className="absolute top-3 right-3">
                <div className="bg-black/50 text-white px-2 py-1 rounded text-xs">{guide.read_time}</div>
              </div>
            </div>
            <div className="p-4">
              <div className="flex items-start justify-between mb-2">
                <h3 className="font-bold text-green-800 text-lg line-clamp-2">{guide.title}</h3>
              </div>
              <p className="text-gray-600 text-sm mb-3 line-clamp-2">{guide.description}</p>
              <div className="flex flex-wrap gap-1 mb-3">
                {guide.tags && guide.tags.map((tag: string) => (
                  <Badge key={tag} variant="secondary" className="text-xs">
                    {tag}
                  </Badge>
                ))}
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-sm text-gray-500">
                  <div className="flex items-center gap-1">
                    <Avatar className="w-5 h-5">
                      <AvatarFallback className="bg-green-100 text-green-700 text-xs">
                        {guide.author && guide.author.split(" ").map((n: string) => n[0]).join("")}
                      </AvatarFallback>
                    </Avatar>
                    <span className="text-xs">{guide.author}</span>
                  </div>
                  <span className="flex items-center gap-1">
                    <Eye className="w-3 h-3" />
                    {guide.views}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant="outline" className="text-xs">
                    {guide.difficulty}
                  </Badge>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-red-500 hover:text-red-600"
                    onClick={(e) => { e.stopPropagation(); onLike(guide.id); }}
                  >
                    <Heart className="w-4 h-4 mr-1" />
                    {guide.likes}
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
};

export default GuideList; 