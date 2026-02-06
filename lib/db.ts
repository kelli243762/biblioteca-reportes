import { Pool, QueryResult } from 'pg';


const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});


export async function query<T = any>(
  text: string,
  params?: any[]
): Promise<QueryResult<T>> {
  const start = Date.now();
  try {
    const res = await pool.query<T>(text, params);
    const duration = Date.now() - start;
    
    if (process.env.NODE_ENV === 'development') {
      console.log('Query ejecutada:', { text, duration, rows: res.rowCount });
    }
    
    return res;
  } catch (error) {
    console.error('Error en query:', error);
    throw error;
  }
}


export interface MostBorrowedBook {
  book_id: number;
  title: string;
  author: string;
  category: string;
  isbn: string;
  total_loans: number;
  ranking: number;
  percentage_of_total: number;
}

export interface OverdueLoan {
  loan_id: number;
  member_id: number;
  member_name: string;
  member_email: string;
  member_type: string;
  book_title: string;
  book_author: string;
  barcode: string;
  loaned_at: Date;
  due_at: Date;
  dias_atraso: number;
  tarifa_diaria: number;
  monto_sugerido: number;
  monto_multa_registrada: number;
  estado_multa: string;
  nivel_atraso: string;
}

export interface FineSummary {
  anio: number;
  mes: number;
  periodo: string;
  periodo_texto: string;
  total_multas: number;
  monto_total: number;
  multas_pagadas: number;
  monto_pagado: number;
  multas_pendientes: number;
  monto_pendiente: number;
  tasa_recuperacion_porcentaje: number;
}

export interface MemberActivity {
  member_id: number;
  name: string;
  email: string;
  member_type: string;
  joined_at: Date;
  total_prestamos: number;
  prestamos_activos: number;
  prestamos_devueltos: number;
  prestamos_atrasados: number;
  tasa_atraso_porcentaje: number;
  multas_totales: number;
  multas_pendientes: number;
  nivel_actividad: string;
  nivel_riesgo: string;
}

export interface InventoryHealth {
  categoria: string;
  libros_unicos: number;
  total_copias: number;
  copias_disponibles: number;
  copias_prestadas: number;
  copias_perdidas: number;
  copias_mantenimiento: number;
  tasa_disponibilidad_porcentaje: number;
  tasa_prestamo_porcentaje: number;
  tasa_perdida_porcentaje: number;
  estado_inventario: string;
  recomendacion: string;
}