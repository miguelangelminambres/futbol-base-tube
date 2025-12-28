# ⚽ Futbol Base TUBE

**La Mayor Biblioteca de Ejercicios de Fútbol del Mundo**

Una plataforma de curación de videos de entrenamiento de fútbol, creada por entrenadores para entrenadores.

![Hero](https://img.shields.io/badge/Ejercicios-1000+-green) ![Filtros](https://img.shields.io/badge/Filtros-12+-blue) ![Comunidad](https://img.shields.io/badge/Comunidad-Open-orange)

## 🚀 Características

- **🔍 12+ Filtros avanzados**: Categoría, dificultad, entrenador, equipo, idioma, edad, duración, jugadores, porteros, likes, vistas, fuente
- **📺 Multi-fuente**: YouTube, Twitter/X, Instagram
- **📋 Planificador de sesiones**: Crea y organiza tus entrenamientos
- **🔗 Links compartibles**: Comparte sesiones con tu equipo técnico
- **👥 Comunidad**: Contenido subido y clasificado por entrenadores reales
- **🆓 100% Contenido gratuito**: Curación de videos públicos

## 📁 Estructura del Proyecto

```
futbol-base-tube/
├── public/
│   ├── index.html      # Frontend principal
│   └── admin.html      # Panel de administración
├── sql/
│   ├── 01-ejercicios-setup.sql    # Tabla ejercicios
│   └── 02-auth-sesiones-setup.sql # Auth, sesiones, favoritos
└── docs/
    └── ...
```

## 🛠️ Stack Tecnológico

- **Frontend**: HTML + CSS + JavaScript vanilla
- **Backend**: Supabase (PostgreSQL + Auth + RLS)
- **APIs**: YouTube oEmbed, Twitter Publish, Instagram oEmbed
- **Hosting**: Cualquier hosting estático (Vercel, Netlify, GitHub Pages)

## ⚡ Instalación Rápida

### 1. Crear proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) y crea un proyecto
2. Copia tu `SUPABASE_URL` y `SUPABASE_ANON_KEY`

### 2. Ejecutar SQL

En el SQL Editor de Supabase, ejecuta en orden:

```bash
sql/01-ejercicios-setup.sql
sql/02-auth-sesiones-setup.sql
```

### 3. Configurar credenciales

En `public/index.html` y `public/admin.html`, actualiza:

```javascript
var SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
var SUPABASE_KEY = 'tu-anon-key';
```

### 4. Habilitar Auth

En Supabase → Authentication → Providers → Habilita **Email**

### 5. Desplegar

Sube la carpeta `public/` a tu hosting favorito.

## 📊 Esquema de Base de Datos

### Tabla `ejercicios`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | ID único |
| titulo_ejercicio | TEXT | Título del ejercicio |
| categorias | TEXT[] | Array de categorías |
| dificultad | INTEGER | 1-5 |
| entrenador | TEXT | Nombre del entrenador |
| equipo | TEXT | Equipo/Club |
| idioma | TEXT | es, en, pt, etc. |
| edad | TEXT | Benjamín, Alevín, etc. |
| duracion | TEXT | "10:30" |
| duracion_segundos | INTEGER | 630 |
| jugadores | TEXT | "12-16" |
| num_porteros | INTEGER | 0-3 |
| video_url | TEXT | URL original del video |
| thumbnail_url | TEXT | URL de la miniatura |
| source | TEXT | youtube, twitter, instagram |
| vistas | INTEGER | Contador de vistas |
| likes | INTEGER | Contador de likes |
| estado | TEXT | publicado, borrador |

### Tabla `sesiones`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | ID único |
| usuario_id | UUID | FK a auth.users |
| nombre | TEXT | "Entrenamiento Lunes" |
| fecha | DATE | Fecha de la sesión |
| categoria_edad | TEXT | Categoría de edad |
| objetivo | TEXT | Objetivo de la sesión |
| notas | TEXT | Notas adicionales |
| ejercicios | JSONB | Array de ejercicios |
| duracion_total | INTEGER | Segundos totales |
| num_ejercicios | INTEGER | Contador |

### Tabla `favoritos`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | ID único |
| usuario_id | UUID | FK a auth.users |
| ejercicio_id | UUID | FK a ejercicios |

## 🔐 Seguridad (RLS)

Todas las tablas tienen Row Level Security habilitado:

- **ejercicios**: Lectura pública, escritura solo admin
- **sesiones**: Solo el propietario puede CRUD
- **favoritos**: Solo el propietario puede CRUD
- **perfiles**: Solo el propietario puede ver/editar

## 🗺️ Roadmap

- [x] Filtros avanzados (12 filtros)
- [x] Multi-fuente (YouTube, Twitter, Instagram)
- [x] Autenticación usuarios
- [x] Planificador de sesiones
- [x] Links compartibles
- [ ] Sistema Freemium (límites + Stripe)
- [ ] Comunidad (subir ejercicios, rankings)
- [ ] App móvil (PWA)

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit (`git commit -m 'Añade nueva funcionalidad'`)
4. Push (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

MIT License - Ver [LICENSE](LICENSE)

---

Hecho con ⚽ por la comunidad de entrenadores
