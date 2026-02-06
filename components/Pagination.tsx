import React from 'react';
import Link from 'next/link';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  baseUrl: string;
  searchParams?: Record<string, string>;
}

export default function Pagination({ 
  currentPage, 
  totalPages, 
  baseUrl,
  searchParams = {}
}: PaginationProps) {
  const createUrl = (page: number) => {
    const params = new URLSearchParams(searchParams);
    params.set('page', page.toString());
    return `${baseUrl}?${params.toString()}`;
  };

  if (totalPages <= 1) return null;

  return (
    <div className="flex items-center justify-center gap-2 mt-6">
      <Link
        href={createUrl(Math.max(1, currentPage - 1))}
        className={`px-3 py-2 rounded border ${
          currentPage === 1
            ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
            : 'bg-white text-blue-600 hover:bg-blue-50 border-blue-300'
        }`}
      >
        Anterior
      </Link>

      {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
        const page = i + 1;
        return (
          <Link
            key={page}
            href={createUrl(page)}
            className={`px-3 py-2 rounded border ${
              page === currentPage
                ? 'bg-blue-600 text-white border-blue-600'
                : 'bg-white text-blue-600 hover:bg-blue-50 border-blue-300'
            }`}
          >
            {page}
          </Link>
        );
      })}

      <Link
        href={createUrl(Math.min(totalPages, currentPage + 1))}
        className={`px-3 py-2 rounded border ${
          currentPage === totalPages
            ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
            : 'bg-white text-blue-600 hover:bg-blue-50 border-blue-300'
        }`}
      >
        Siguiente
      </Link>
    </div>
  );
}