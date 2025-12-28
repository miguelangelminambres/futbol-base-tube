# 🗄️ FUTBOL BASE TOTAL - Configuración de Supabase

## 📋 Paso 1: Crear proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) e inicia sesión
2. Click en **"New Project"**
3. Configura:
   - **Name**: `futbol-base-total`
   - **Database Password**: (guárdala en lugar seguro)
   - **Region**: EU West (Frankfurt) - más cercano a España
4. Espera 2 minutos a que se cree

---

## 📋 Paso 2: Crear las tablas

Ve a **SQL Editor** en el menú lateral y ejecuta este script:

```sql
-- ============================================
-- TABLA: ejercicios
-- Almacena todos los ejercicios de la biblioteca
-- ============================================
CREATE TABLE ejercicios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Fuente del video
    source TEXT NOT NULL CHECK (source IN ('youtube', 'twitter')),
    video_id TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    
    -- Datos del video
    titulo_video TEXT,
    canal TEXT,
    duracion TEXT,
    duracion_segundos INTEGER DEFAULT 0,
    fecha_publicacion TEXT,
    descripcion TEXT,
    
    -- Estadísticas (solo YouTube)
    vistas INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    
    -- Datos del ejercicio
    titulo_ejercicio TEXT NOT NULL,
    entrenador TEXT,
    equipo TEXT,
    categorias TEXT[] DEFAULT '{}',
    dificultad INTEGER CHECK (dificultad BETWEEN 1 AND 5),
    jugadores TEXT,
    dimensiones TEXT,
    material TEXT,
    
    -- Estadísticas internas
    vistas_internas INTEGER DEFAULT 0,
    likes_internos INTEGER DEFAULT 0,
    
    -- Estado y moderación
    estado TEXT DEFAULT 'publicado' CHECK (estado IN ('borrador', 'pendiente', 'publicado', 'rechazado')),
    creado_por UUID REFERENCES auth.users(id),
    aprobado_por UUID REFERENCES auth.users(id),
    
    -- Embed de Twitter (si aplica)
    tweet_embed_html TEXT
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_ejercicios_source ON ejercicios(source);
CREATE INDEX idx_ejercicios_categorias ON ejercicios USING GIN(categorias);
CREATE INDEX idx_ejercicios_dificultad ON ejercicios(dificultad);
CREATE INDEX idx_ejercicios_estado ON ejercicios(estado);
CREATE INDEX idx_ejercicios_entrenador ON ejercicios(entrenador);

-- ============================================
-- TABLA: usuarios (perfil extendido)
-- Extiende auth.users con datos de gamificación
-- ============================================
CREATE TABLE perfiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Datos básicos
    nombre TEXT,
    username TEXT UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    
    -- Gamificación
    puntos INTEGER DEFAULT 0,
    nivel INTEGER DEFAULT 1,
    rango TEXT DEFAULT 'Novato',
    
    -- Estadísticas
    ejercicios_subidos INTEGER DEFAULT 0,
    ejercicios_aprobados INTEGER DEFAULT 0,
    likes_recibidos INTEGER DEFAULT 0,
    
    -- Suscripción
    plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'coach')),
    plan_expira TIMESTAMP WITH TIME ZONE,
    
    -- Preferencias
    ejercicios_vistos_hoy INTEGER DEFAULT 0,
    ultimo_reset_diario DATE DEFAULT CURRENT_DATE
);

-- ============================================
-- TABLA: favoritos
-- Ejercicios guardados por usuarios
-- ============================================
CREATE TABLE favoritos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ejercicio_id UUID REFERENCES ejercicios(id) ON DELETE CASCADE,
    UNIQUE(usuario_id, ejercicio_id)
);

CREATE INDEX idx_favoritos_usuario ON favoritos(usuario_id);

-- ============================================
-- TABLA: likes
-- Likes de usuarios a ejercicios
-- ============================================
CREATE TABLE likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ejercicio_id UUID REFERENCES ejercicios(id) ON DELETE CASCADE,
    UNIQUE(usuario_id, ejercicio_id)
);

CREATE INDEX idx_likes_ejercicio ON likes(ejercicio_id);

-- ============================================
-- TABLA: sesiones
-- Entrenamientos creados por usuarios
-- ============================================
CREATE TABLE sesiones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    titulo TEXT NOT NULL,
    descripcion TEXT,
    duracion_total INTEGER DEFAULT 0,
    
    -- Array ordenado de ejercicios
    ejercicios_ids UUID[] DEFAULT '{}',
    
    -- Metadatos
    es_publica BOOLEAN DEFAULT FALSE,
    veces_copiada INTEGER DEFAULT 0
);

CREATE INDEX idx_sesiones_usuario ON sesiones(usuario_id);

-- ============================================
-- TABLA: historial_puntos
-- Registro de puntos ganados
-- ============================================
CREATE TABLE historial_puntos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    puntos INTEGER NOT NULL,
    motivo TEXT NOT NULL,
    ejercicio_id UUID REFERENCES ejercicios(id) ON DELETE SET NULL
);

CREATE INDEX idx_historial_usuario ON historial_puntos(usuario_id);

-- ============================================
-- TABLA: categorias
-- Categorías predefinidas
-- ============================================
CREATE TABLE categorias (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    color TEXT DEFAULT '#8b5cf6',
    icono TEXT DEFAULT '⚽',
    orden INTEGER DEFAULT 0
);

-- Insertar categorías iniciales
INSERT INTO categorias (nombre, slug, color, icono, orden) VALUES
    ('Rondos', 'rondos', '#ef4444', '🔄', 1),
    ('Posesión', 'posesion', '#f59e0b', '⚽', 2),
    ('Finalización', 'finalizacion', '#22c55e', '🥅', 3),
    ('Transiciones', 'transiciones', '#3b82f6', '⚡', 4),
    ('Pressing', 'pressing', '#8b5cf6', '🏃', 5),
    ('Físico', 'fisico', '#ec4899', '💪', 6),
    ('Técnica', 'tecnica', '#06b6d4', '🎯', 7),
    ('Porteros', 'porteros', '#84cc16', '🧤', 8),
    ('Táctico', 'tactico', '#f97316', '📋', 9),
    ('Calentamiento', 'calentamiento', '#a855f7', '🔥', 10);

-- ============================================
-- TABLA: entrenadores
-- Entrenadores conocidos
-- ============================================
CREATE TABLE entrenadores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    equipo_actual TEXT,
    pais TEXT,
    foto_url TEXT
);

-- Insertar entrenadores iniciales
INSERT INTO entrenadores (nombre, equipo_actual, pais) VALUES
    ('Pep Guardiola', 'Manchester City', 'España'),
    ('Jürgen Klopp', 'Sin equipo', 'Alemania'),
    ('Carlo Ancelotti', 'Real Madrid', 'Italia'),
    ('Diego Simeone', 'Atlético Madrid', 'Argentina'),
    ('Xavi Hernández', 'Sin equipo', 'España'),
    ('Mikel Arteta', 'Arsenal', 'España'),
    ('Luis Enrique', 'PSG', 'España'),
    ('Unai Emery', 'Aston Villa', 'España'),
    ('Julian Nagelsmann', 'Alemania', 'Alemania'),
    ('Thomas Tuchel', 'Bayern Munich', 'Alemania');

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER update_ejercicios_updated_at
    BEFORE UPDATE ON ejercicios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_perfiles_updated_at
    BEFORE UPDATE ON perfiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_sesiones_updated_at
    BEFORE UPDATE ON sesiones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Función para crear perfil automáticamente al registrarse
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO perfiles (id, nombre, username, puntos)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        LOWER(SPLIT_PART(NEW.email, '@', 1)),
        50  -- Puntos por registrarse
    );
    
    -- Registrar puntos de bienvenida
    INSERT INTO historial_puntos (usuario_id, puntos, motivo)
    VALUES (NEW.id, 50, 'Registro en la plataforma');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Función para actualizar likes internos
CREATE OR REPLACE FUNCTION update_ejercicio_likes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE ejercicios SET likes_internos = likes_internos + 1 WHERE id = NEW.ejercicio_id;
        
        -- Dar puntos al creador del ejercicio
        UPDATE perfiles SET 
            puntos = puntos + 10,
            likes_recibidos = likes_recibidos + 1
        WHERE id = (SELECT creado_por FROM ejercicios WHERE id = NEW.ejercicio_id);
        
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE ejercicios SET likes_internos = likes_internos - 1 WHERE id = OLD.ejercicio_id;
        
        UPDATE perfiles SET 
            puntos = puntos - 10,
            likes_recibidos = likes_recibidos - 1
        WHERE id = (SELECT creado_por FROM ejercicios WHERE id = OLD.ejercicio_id);
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_like_change
    AFTER INSERT OR DELETE ON likes
    FOR EACH ROW EXECUTE FUNCTION update_ejercicio_likes();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE ejercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE favoritos ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesiones ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_puntos ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE entrenadores ENABLE ROW LEVEL SECURITY;

-- Políticas para EJERCICIOS
CREATE POLICY "Ejercicios publicados visibles para todos"
    ON ejercicios FOR SELECT
    USING (estado = 'publicado');

CREATE POLICY "Usuarios autenticados pueden crear ejercicios"
    ON ejercicios FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Usuarios pueden editar sus propios ejercicios"
    ON ejercicios FOR UPDATE
    TO authenticated
    USING (creado_por = auth.uid());

-- Políticas para PERFILES
CREATE POLICY "Perfiles visibles para todos"
    ON perfiles FOR SELECT
    USING (true);

CREATE POLICY "Usuarios pueden editar su propio perfil"
    ON perfiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid());

-- Políticas para FAVORITOS
CREATE POLICY "Usuarios ven sus propios favoritos"
    ON favoritos FOR SELECT
    TO authenticated
    USING (usuario_id = auth.uid());

CREATE POLICY "Usuarios pueden añadir favoritos"
    ON favoritos FOR INSERT
    TO authenticated
    WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "Usuarios pueden eliminar sus favoritos"
    ON favoritos FOR DELETE
    TO authenticated
    USING (usuario_id = auth.uid());

-- Políticas para LIKES
CREATE POLICY "Likes visibles para todos"
    ON likes FOR SELECT
    USING (true);

CREATE POLICY "Usuarios pueden dar like"
    ON likes FOR INSERT
    TO authenticated
    WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "Usuarios pueden quitar like"
    ON likes FOR DELETE
    TO authenticated
    USING (usuario_id = auth.uid());

-- Políticas para SESIONES
CREATE POLICY "Sesiones públicas visibles"
    ON sesiones FOR SELECT
    USING (es_publica = true OR usuario_id = auth.uid());

CREATE POLICY "Usuarios pueden crear sesiones"
    ON sesiones FOR INSERT
    TO authenticated
    WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "Usuarios pueden editar sus sesiones"
    ON sesiones FOR UPDATE
    TO authenticated
    USING (usuario_id = auth.uid());

CREATE POLICY "Usuarios pueden eliminar sus sesiones"
    ON sesiones FOR DELETE
    TO authenticated
    USING (usuario_id = auth.uid());

-- Políticas para CATEGORIAS y ENTRENADORES (solo lectura)
CREATE POLICY "Categorías visibles para todos"
    ON categorias FOR SELECT
    USING (true);

CREATE POLICY "Entrenadores visibles para todos"
    ON entrenadores FOR SELECT
    USING (true);

-- Políticas para HISTORIAL
CREATE POLICY "Usuarios ven su historial"
    ON historial_puntos FOR SELECT
    TO authenticated
    USING (usuario_id = auth.uid());
```

---

## 📋 Paso 3: Configurar Storage (para thumbnails opcionales)

1. Ve a **Storage** en el menú lateral
2. Click en **"New bucket"**
3. Nombre: `thumbnails`
4. Marca **"Public bucket"**
5. Click **Create**

---

## 📋 Paso 4: Obtener credenciales

1. Ve a **Settings** → **API**
2. Copia estos valores:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGci...`

---

## 📋 Paso 5: Crear usuario administrador

1. Ve a **Authentication** → **Users**
2. Click **"Add user"**
3. Introduce tu email y contraseña
4. Ve a **SQL Editor** y ejecuta:

```sql
-- Cambiar el plan del admin a 'coach' y darle puntos
UPDATE perfiles 
SET plan = 'coach', puntos = 10000, nivel = 99, rango = 'Admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'TU_EMAIL@ejemplo.com');
```

---

## ✅ ¡Listo!

Tu base de datos está configurada con:
- ✅ Tabla de ejercicios (YouTube + Twitter)
- ✅ Sistema de usuarios con gamificación
- ✅ Favoritos y likes
- ✅ Sesiones de entrenamiento
- ✅ Historial de puntos
- ✅ Categorías y entrenadores predefinidos
- ✅ Seguridad RLS configurada
- ✅ Triggers automáticos

---

## 🔗 Próximo paso

Ahora abre el archivo `admin-supabase.html` para empezar a cargar ejercicios.
