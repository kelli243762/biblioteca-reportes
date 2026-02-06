-- ============================================================================
-- CONFIGURACIÓN DE SEGURIDAD: ROLES Y PERMISOS
-- ============================================================================
-- La aplicación NO debe conectarse como usuario postgres
-- Se crea un usuario/rol específico con permisos mínimos necesarios

-- ============================================================================
-- PASO 1: Crear rol/usuario para la aplicación
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user WITH LOGIN PASSWORD 'app_password';
    END IF;
END
$$;

ALTER ROLE app_user WITH PASSWORD 'app_password';

-- Configuraciones de seguridad adicionales
ALTER ROLE app_user SET statement_timeout = '30s';
ALTER ROLE app_user SET idle_in_transaction_session_timeout = '60s';


-- ============================================================================
-- PASO 2: Otorgar permisos básicos sobre la base de datos
-- ============================================================================

GRANT CONNECT ON DATABASE biblioteca TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;


-- ============================================================================
-- PASO 3: Denegar acceso directo a TABLAS
-- ============================================================================

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM app_user;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA public FROM app_user;

REVOKE SELECT ON TABLE members FROM app_user;
REVOKE SELECT ON TABLE books FROM app_user;
REVOKE SELECT ON TABLE copies FROM app_user;
REVOKE SELECT ON TABLE loans FROM app_user;
REVOKE SELECT ON TABLE fines FROM app_user;


-- ============================================================================
-- PASO 4: Otorgar SELECT SOLO sobre VIEWs
-- ============================================================================

GRANT SELECT ON vw_most_borrowed_books TO app_user;
GRANT SELECT ON vw_overdue_loans TO app_user;
GRANT SELECT ON vw_fines_summary TO app_user;
GRANT SELECT ON vw_member_activity TO app_user;
GRANT SELECT ON vw_inventory_health TO app_user;


-- ============================================================================
-- PASO 5: Configuración por defecto para objetos futuros
-- ============================================================================

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
REVOKE ALL ON TABLES FROM app_user;