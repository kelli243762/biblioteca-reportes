-- ============================================================================
-- SCRIPT DE VERIFICACIÓN Y MIGRACIÓN
-- ============================================================================

\echo '============================================================================'
\echo 'VERIFICANDO MIGRACIÓN DE BASE DE DATOS'
\echo '============================================================================'

-- Verificar que las tablas fueron creadas
\echo ''
\echo 'Verificando tablas...'
DO $$
DECLARE
    tabla_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO tabla_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    RAISE NOTICE 'Total de tablas creadas: %', tabla_count;
    
    IF tabla_count < 5 THEN
        RAISE EXCEPTION 'ERROR: Se esperaban al menos 5 tablas';
    END IF;
END $$;

-- Verificar que las vistas fueron creadas
\echo ''
\echo 'Verificando vistas...'
DO $$
DECLARE
    vista_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO vista_count
    FROM information_schema.views 
    WHERE table_schema = 'public';
    
    RAISE NOTICE 'Total de vistas creadas: %', vista_count;
    
    IF vista_count < 5 THEN
        RAISE EXCEPTION 'ERROR: Se esperaban al menos 5 vistas';
    END IF;
END $$;

-- Verificar que los datos fueron insertados
\echo ''
\echo 'Verificando datos...'
DO $$
DECLARE
    members_count INTEGER;
    books_count INTEGER;
    loans_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO members_count FROM members;
    SELECT COUNT(*) INTO books_count FROM books;
    SELECT COUNT(*) INTO loans_count FROM loans;
    
    RAISE NOTICE 'Miembros: %', members_count;
    RAISE NOTICE 'Libros: %', books_count;
    RAISE NOTICE 'Préstamos: %', loans_count;
    
    IF members_count < 10 OR books_count < 10 OR loans_count < 10 THEN
        RAISE EXCEPTION 'ERROR: Datos insuficientes para reportes';
    END IF;
END $$;

-- Verificar permisos del usuario app_user
\echo ''
\echo 'Verificando permisos del usuario app_user...'
DO $$
DECLARE
    permisos_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO permisos_count
    FROM information_schema.role_table_grants 
    WHERE grantee = 'app_user' 
    AND privilege_type = 'SELECT'
    AND table_name LIKE 'vw_%';
    
    RAISE NOTICE 'Permisos SELECT en vistas: %', permisos_count;
    
    IF permisos_count < 5 THEN
        RAISE WARNING 'ADVERTENCIA: El usuario app_user podría no tener todos los permisos necesarios';
    END IF;
END $$;

\echo ''
\echo '============================================================================'
\echo 'MIGRACIÓN COMPLETADA EXITOSAMENTE'
\echo '============================================================================'
\echo ''