import React from 'react';

interface CardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  color?: 'blue' | 'green' | 'red' | 'yellow' | 'purple';
}

const colorClasses = {
  blue: 'bg-blue-50 border-blue-200',
  green: 'bg-green-50 border-green-200',
  red: 'bg-red-50 border-red-200',
  yellow: 'bg-yellow-50 border-yellow-200',
  purple: 'bg-purple-50 border-purple-200',
};

const textColorClasses = {
  blue: 'text-blue-900',
  green: 'text-green-900',
  red: 'text-red-900',
  yellow: 'text-yellow-900',
  purple: 'text-purple-900',
};

export default function Card({ 
  title, 
  value, 
  subtitle, 
  color = 'blue' 
}: CardProps) {
  return (
    <div className={`p-6 rounded-lg border-2 ${colorClasses[color]} shadow-sm`}>
      <h3 className="text-sm font-medium text-gray-600 mb-2">{title}</h3>
      <p className={`text-3xl font-bold ${textColorClasses[color]}`}>
        {value}
      </p>
      {subtitle && (
        <p className="text-sm text-gray-500 mt-1">{subtitle}</p>
      )}
    </div>
  );
}