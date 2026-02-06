import type { Metadata } from 'next'
import Link from 'next/link'
import './globals.css'

export const metadata: Metadata = {
  title: 'Sistema de Reportes - Biblioteca',
  description: 'Dashboard de análisis y reportes para gestión de biblioteca',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="es">
      <body className="bg-gray-50">
        <nav className="bg-white shadow-sm border-b">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between h-16">
              <div className="flex items-center">
                <Link href="/" className="flex items-center">
                  <span className="text-2xl font-bold text-blue-600">📚</span>
                  <span className="ml-2 text-xl font-semibold text-gray-900">
                    Sistema de Biblioteca
                  </span>
                </Link>
              </div>
              <div className="flex items-center space-x-4">
                <Link 
                  href="/" 
                  className="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Dashboard
                </Link>
              </div>
            </div>
          </div>
        </nav>
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {children}
        </main>
        <footer className="bg-white border-t mt-12">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
            <p className="text-center text-gray-500 text-sm">
              Sistema de Reportes de Biblioteca - Evaluación Práctica C1
            </p>
          </div>
        </footer>
      </body>
    </html>
  )
}