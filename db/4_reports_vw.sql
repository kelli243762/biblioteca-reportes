-- ============================================================================
-- VIEW 1: Ranking de libros más prestados (Window Function + Agregación)
-- ============================================================================
-- GRAIN: Un registro por libro
-- MÉTRICAS: total_loans (cantidad de préstamos), ranking (posición en ranking)
-- TÉCNICAS: Window Function (RANK), COUNT, GROUP BY
-- 
-- VERIFY QUERIES:
-- SELECT * FROM vw_most_borrowed_books WHERE title ILIKE '%quijote%' LIMIT 10;
-- SELECT * FROM vw_most_borrowed_books ORDER BY ranking LIMIT 20;
-- ============================================================================

CREATE OR REPLACE VIEW vw_most_borrowed_books AS
SELECT 
    b.id AS book_id,
    b.title,
    b.author,
    b.category,
    b.isbn,
    COUNT(l.id) AS total_loans,
    RANK() OVER (ORDER BY COUNT(l.id) DESC) AS ranking,
    ROUND(COUNT(l.id) * 100.0 / NULLIF(SUM(COUNT(l.id)) OVER (), 0), 2) AS percentage_of_total
FROM books b
LEFT JOIN copies c ON b.id = c.book_id
LEFT JOIN loans l ON c.id = l.copy_id
GROUP BY b.id, b.title, b.author, b.category, b.isbn
ORDER BY total_loans DESC, b.title;


-- ============================================================================
-- VIEW 2: Préstamos vencidos con días de atraso (CTE + CASE + HAVING)
-- ============================================================================
-- GRAIN: Un registro por préstamo vencido activo
-- MÉTRICAS: dias_atraso, monto_sugerido (calculado por días)
-- TÉCNICAS: CTE (WITH), CASE, COALESCE, cálculos de fechas
--
-- VERIFY QUERIES:
-- SELECT * FROM vw_overdue_loans WHERE dias_atraso >= 10 ORDER BY dias_atraso DESC;
-- SELECT COUNT(*), AVG(dias_atraso) FROM vw_overdue_loans;
-- ============================================================================

CREATE OR REPLACE VIEW vw_overdue_loans AS
WITH overdue_details AS (
    SELECT 
        l.id AS loan_id,
        l.copy_id,
        l.member_id,
        m.name AS member_name,
        m.email AS member_email,
        m.member_type,
        b.title AS book_title,
        b.author AS book_author,
        c.barcode,
        l.loaned_at,
        l.due_at,
        CURRENT_DATE - l.due_at AS dias_atraso,
        CASE 
            WHEN m.member_type = 'premium' THEN 2.00
            WHEN m.member_type = 'senior' THEN 1.50
            WHEN m.member_type = 'student' THEN 1.50
            ELSE 2.50
        END AS tarifa_diaria,
        f.amount AS monto_multa_actual,
        f.paid_at
    FROM loans l
    INNER JOIN members m ON l.member_id = m.id
    INNER JOIN copies c ON l.copy_id = c.id
    INNER JOIN books b ON c.book_id = b.id
    LEFT JOIN fines f ON l.id = f.loan_id
    WHERE l.returned_at IS NULL 
    AND l.due_at < CURRENT_DATE
)
SELECT 
    loan_id,
    member_id,
    member_name,
    member_email,
    member_type,
    book_title,
    book_author,
    barcode,
    loaned_at,
    due_at,
    dias_atraso,
    tarifa_diaria,
    GREATEST(dias_atraso * tarifa_diaria, 5.00) AS monto_sugerido,
    COALESCE(monto_multa_actual, 0) AS monto_multa_registrada,
    CASE 
        WHEN paid_at IS NOT NULL THEN 'Pagada'
        WHEN monto_multa_actual IS NOT NULL THEN 'Pendiente'
        ELSE 'Sin registrar'
    END AS estado_multa,
    CASE 
        WHEN dias_atraso >= 30 THEN 'Crítico'
        WHEN dias_atraso >= 15 THEN 'Alto'
        WHEN dias_atraso >= 7 THEN 'Medio'
        ELSE 'Bajo'
    END AS nivel_atraso
FROM overdue_details
ORDER BY dias_atraso DESC;


-- ============================================================================
-- VIEW 3: Resumen mensual de multas (HAVING + Agregación + GROUP BY)
-- ============================================================================
-- GRAIN: Un registro por mes
-- MÉTRICAS: total_multas, monto_total, multas_pagadas, monto_pagado
-- TÉCNICAS: GROUP BY fecha, HAVING, SUM, COUNT, FILTER
--
-- VERIFY QUERIES:
-- SELECT * FROM vw_fines_summary WHERE anio = 2024 AND mes >= 6;
-- SELECT SUM(monto_total), SUM(monto_pagado) FROM vw_fines_summary;
-- ============================================================================

CREATE OR REPLACE VIEW vw_fines_summary AS
SELECT 
    EXTRACT(YEAR FROM f.created_at) AS anio,
    EXTRACT(MONTH FROM f.created_at) AS mes,
    TO_CHAR(f.created_at, 'YYYY-MM') AS periodo,
    TO_CHAR(f.created_at, 'Month YYYY') AS periodo_texto,
    COUNT(f.id) AS total_multas,
    SUM(f.amount) AS monto_total,
    COUNT(f.id) FILTER (WHERE f.paid_at IS NOT NULL) AS multas_pagadas,
    COALESCE(SUM(f.amount) FILTER (WHERE f.paid_at IS NOT NULL), 0) AS monto_pagado,
    COUNT(f.id) FILTER (WHERE f.paid_at IS NULL) AS multas_pendientes,
    COALESCE(SUM(f.amount) FILTER (WHERE f.paid_at IS NULL), 0) AS monto_pendiente,
    ROUND(
        COALESCE(
            SUM(f.amount) FILTER (WHERE f.paid_at IS NOT NULL) * 100.0 / NULLIF(SUM(f.amount), 0),
            0
        ), 
        2
    ) AS tasa_recuperacion_porcentaje
FROM fines f
GROUP BY 
    EXTRACT(YEAR FROM f.created_at),
    EXTRACT(MONTH FROM f.created_at),
    TO_CHAR(f.created_at, 'YYYY-MM'),
    TO_CHAR(f.created_at, 'Month YYYY')
HAVING COUNT(f.id) > 0
ORDER BY anio DESC, mes DESC;


-- ============================================================================
-- VIEW 4: Actividad de miembros con tasa de atraso (HAVING + CASE + COALESCE)
-- ============================================================================
-- GRAIN: Un registro por miembro activo (con al menos 1 préstamo)
-- MÉTRICAS: total_prestamos, tasa_atraso, multas_totales
-- TÉCNICAS: HAVING, múltiples CASE, COALESCE, FILTER
--
-- VERIFY QUERIES:
-- SELECT * FROM vw_member_activity WHERE tasa_atraso_porcentaje > 20;
-- SELECT member_type, AVG(total_prestamos) FROM vw_member_activity GROUP BY member_type;
-- ============================================================================

CREATE OR REPLACE VIEW vw_member_activity AS
SELECT 
    m.id AS member_id,
    m.name,
    m.email,
    m.member_type,
    m.joined_at,
    COUNT(l.id) AS total_prestamos,
    COUNT(l.id) FILTER (WHERE l.returned_at IS NULL) AS prestamos_activos,
    COUNT(l.id) FILTER (WHERE l.returned_at IS NOT NULL) AS prestamos_devueltos,
    COUNT(l.id) FILTER (WHERE l.returned_at IS NOT NULL AND l.returned_at > l.due_at) AS prestamos_atrasados,
    ROUND(
        COALESCE(
            COUNT(l.id) FILTER (WHERE l.returned_at IS NOT NULL AND l.returned_at > l.due_at) * 100.0 
            / NULLIF(COUNT(l.id) FILTER (WHERE l.returned_at IS NOT NULL), 0),
            0
        ),
        2
    ) AS tasa_atraso_porcentaje,
    COALESCE(SUM(f.amount), 0) AS multas_totales,
    COALESCE(SUM(f.amount) FILTER (WHERE f.paid_at IS NULL), 0) AS multas_pendientes,
    CASE 
        WHEN COUNT(l.id) >= 20 THEN 'Muy Activo'
        WHEN COUNT(l.id) >= 10 THEN 'Activo'
        WHEN COUNT(l.id) >= 5 THEN 'Regular'
        ELSE 'Poco Activo'
    END AS nivel_actividad,
    CASE 
        WHEN COALESCE(SUM(f.amount) FILTER (WHERE f.paid_at IS NULL), 0) > 50 THEN 'Alto Riesgo'
        WHEN COALESCE(SUM(f.amount) FILTER (WHERE f.paid_at IS NULL), 0) > 20 THEN 'Riesgo Medio'
        WHEN COALESCE(SUM(f.amount) FILTER (WHERE f.paid_at IS NULL), 0) > 0 THEN 'Riesgo Bajo'
        ELSE 'Sin Riesgo'
    END AS nivel_riesgo
FROM members m
LEFT JOIN loans l ON m.id = l.member_id
LEFT JOIN fines f ON l.id = f.loan_id
GROUP BY m.id, m.name, m.email, m.member_type, m.joined_at
HAVING COUNT(l.id) > 0
ORDER BY total_prestamos DESC, tasa_atraso_porcentaje DESC;


-- ============================================================================
-- VIEW 5: Salud del inventario por categoría (CASE + COALESCE + Agregación)
-- ============================================================================
-- GRAIN: Un registro por categoría de libro
-- MÉTRICAS: total_copias, disponibles, prestadas, perdidas
-- TÉCNICAS: Múltiples CASE, COALESCE, FILTER, porcentajes calculados
--
-- VERIFY QUERIES:
-- SELECT * FROM vw_inventory_health ORDER BY tasa_perdida_porcentaje DESC;
-- SELECT * FROM vw_inventory_health WHERE tasa_disponibilidad_porcentaje < 50;
-- ============================================================================

CREATE OR REPLACE VIEW vw_inventory_health AS
SELECT 
    b.category AS categoria,
    COUNT(DISTINCT b.id) AS libros_unicos,
    COUNT(c.id) AS total_copias,
    COUNT(c.id) FILTER (WHERE c.status = 'available') AS copias_disponibles,
    COUNT(c.id) FILTER (WHERE c.status = 'loaned') AS copias_prestadas,
    COUNT(c.id) FILTER (WHERE c.status = 'lost') AS copias_perdidas,
    COUNT(c.id) FILTER (WHERE c.status = 'maintenance') AS copias_mantenimiento,
    ROUND(
        COALESCE(
            COUNT(c.id) FILTER (WHERE c.status = 'available') * 100.0 / NULLIF(COUNT(c.id), 0),
            0
        ),
        2
    ) AS tasa_disponibilidad_porcentaje,
    ROUND(
        COALESCE(
            COUNT(c.id) FILTER (WHERE c.status = 'loaned') * 100.0 / NULLIF(COUNT(c.id), 0),
            0
        ),
        2
    ) AS tasa_prestamo_porcentaje,
    ROUND(
        COALESCE(
            COUNT(c.id) FILTER (WHERE c.status = 'lost') * 100.0 / NULLIF(COUNT(c.id), 0),
            0
        ),
        2
    ) AS tasa_perdida_porcentaje,
    CASE 
        WHEN COUNT(c.id) FILTER (WHERE c.status = 'lost') * 100.0 / NULLIF(COUNT(c.id), 0) > 10 THEN 'Crítico'
        WHEN COUNT(c.id) FILTER (WHERE c.status = 'lost') * 100.0 / NULLIF(COUNT(c.id), 0) > 5 THEN 'Atención'
        WHEN COUNT(c.id) FILTER (WHERE c.status = 'available') * 100.0 / NULLIF(COUNT(c.id), 0) < 30 THEN 'Baja disponibilidad'
        ELSE 'Saludable'
    END AS estado_inventario,
    CASE 
        WHEN COUNT(c.id) FILTER (WHERE c.status = 'available') = 0 THEN 'Urgente: Reponer'
        WHEN COUNT(c.id) FILTER (WHERE c.status = 'available') * 100.0 / NULLIF(COUNT(c.id), 0) < 20 THEN 'Considerar reposición'
        ELSE 'Stock adecuado'
    END AS recomendacion
FROM books b
LEFT JOIN copies c ON b.id = c.book_id
GROUP BY b.category
HAVING COUNT(c.id) > 0
ORDER BY total_copias DESC, tasa_disponibilidad_porcentaje ASC;