-- =====================================================
-- FUTBOL BASE TOTAL - AUTENTICACIÓN Y SESIONES
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- Perfiles de usuario (complementa auth.users)
CREATE TABLE IF NOT EXISTS perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT,
    email TEXT,
    avatar_url TEXT,
    plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'coach')),
    ejercicios_vistos_mes INTEGER DEFAULT 0,
    puntos INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sesiones de entrenamiento
CREATE TABLE IF NOT EXISTS sesiones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    fecha DATE,
    categoria_edad TEXT,
    objetivo TEXT,
    notas TEXT,
    ejercicios JSONB DEFAULT '[]',
    duracion_total INTEGER DEFAULT 0,
    num_ejercicios INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Favoritos de usuarios
CREATE TABLE IF NOT EXISTS favoritos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ejercicio_id UUID REFERENCES ejercicios(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(usuario_id, ejercicio_id)
);

-- =====================================================
-- POLÍTICAS RLS (Row Level Security)
-- =====================================================

ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesiones ENABLE ROW LEVEL SECURITY;
ALTER TABLE favoritos ENABLE ROW LEVEL SECURITY;

-- Perfiles: usuarios solo ven/editan su propio perfil
DROP POLICY IF EXISTS "Usuarios ven su perfil" ON perfiles;
CREATE POLICY "Usuarios ven su perfil" ON perfiles 
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Usuarios editan su perfil" ON perfiles;
CREATE POLICY "Usuarios editan su perfil" ON perfiles 
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Crear perfil propio" ON perfiles;
CREATE POLICY "Crear perfil propio" ON perfiles 
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Sesiones: usuarios gestionan sus propias sesiones
DROP POLICY IF EXISTS "Usuarios ven sus sesiones" ON sesiones;
CREATE POLICY "Usuarios ven sus sesiones" ON sesiones 
    FOR SELECT USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Usuarios crean sesiones" ON sesiones;
CREATE POLICY "Usuarios crean sesiones" ON sesiones 
    FOR INSERT WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Usuarios editan sus sesiones" ON sesiones;
CREATE POLICY "Usuarios editan sus sesiones" ON sesiones 
    FOR UPDATE USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Usuarios eliminan sus sesiones" ON sesiones;
CREATE POLICY "Usuarios eliminan sus sesiones" ON sesiones 
    FOR DELETE USING (auth.uid() = usuario_id);

-- Favoritos: usuarios gestionan sus propios favoritos
DROP POLICY IF EXISTS "Usuarios ven sus favoritos" ON favoritos;
CREATE POLICY "Usuarios ven sus favoritos" ON favoritos 
    FOR SELECT USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Usuarios crean favoritos" ON favoritos;
CREATE POLICY "Usuarios crean favoritos" ON favoritos 
    FOR INSERT WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Usuarios eliminan favoritos" ON favoritos;
CREATE POLICY "Usuarios eliminan favoritos" ON favoritos 
    FOR DELETE USING (auth.uid() = usuario_id);

-- =====================================================
-- TRIGGER: Crear perfil automático al registrarse
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.perfiles (id, nombre, email)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'nombre', split_part(NEW.email, '@', 1)),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar trigger si existe y recrear
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ÍNDICES para mejor rendimiento
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_sesiones_usuario ON sesiones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_favoritos_usuario ON favoritos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_favoritos_ejercicio ON favoritos(ejercicio_id);

-- Si la tabla sesiones ya existe, añadir nuevas columnas
ALTER TABLE sesiones ADD COLUMN IF NOT EXISTS fecha DATE;
ALTER TABLE sesiones ADD COLUMN IF NOT EXISTS categoria_edad TEXT;
ALTER TABLE sesiones ADD COLUMN IF NOT EXISTS objetivo TEXT;
ALTER TABLE sesiones ADD COLUMN IF NOT EXISTS notas TEXT;

-- Índice para fecha (después de crear la columna)
CREATE INDEX IF NOT EXISTS idx_sesiones_fecha ON sesiones(fecha);

-- =====================================================
-- ¡LISTO! Ahora puedes usar autenticación en tu app
-- =====================================================
