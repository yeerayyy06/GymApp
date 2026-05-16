# Gym Tracker AI

App móvil multiplataforma (Flutter) para registro de entrenamientos de fuerza, orientada a **minimizar la fricción de entrada de datos** y a automatizar el progreso mediante reglas de sobrecarga progresiva y visualización avanzada del rendimiento físico.

> Proyecto full-stack en desarrollo activo. Pieza de portfolio.

## Visión

A diferencia de las apps comerciales actuales (Strong, Hevy, FitNotes), que requieren navegación tediosa entre menús, Gym Tracker AI prioriza:

- **Velocidad de entrada**: teclado numérico exclusivo, prellenado inteligente, gestos.
- **Sobrecarga progresiva automatizada**: la app sugiere kilos y repeticiones de la próxima sesión a partir del historial y del RPE registrado.
- **Mapa de calor muscular**: SVG del cuerpo humano que cambia de color según el progreso real de fuerza (cálculo de 1RM cruzado con peso corporal y tablas estándar).
- **Offline-first**: las sesiones se persisten localmente en SQLite y se sincronizan en background con Supabase.

## Stack técnico

| Capa | Tecnología |
|------|------------|
| UI / Framework | Flutter (Dart 3.9.2) — Material 3, dark theme |
| State management | Riverpod |
| Routing | go_router (`StatefulShellRoute.indexedStack`) |
| Persistencia local | Drift (SQLite) — offline-first |
| Backend (Fase 2) | Supabase (PostgreSQL + Auth) |
| Catálogo de ejercicios | wger / ExerciseDB |
| IA (Fase 4) | Gemini / OpenAI — explicación natural de progresiones |

## Arquitectura

Estructura **feature-first** con un núcleo (`core/`) para infraestructura compartida:

```
lib/
├── main.dart                    # ProviderScope + MaterialApp.router
├── core/
│   ├── app_theme.dart
│   ├── domain/                  # Enums de dominio (MuscleGroup, CatalogSource)
│   ├── database/                # Drift schema + AppDatabase
│   │   ├── tables/
│   │   └── converters.dart      # TypeConverters (List<MuscleGroup>, ...)
│   ├── providers/               # Riverpod providers compartidos
│   └── router/                  # go_router config
├── shared/
│   └── main_layout.dart         # Shell con BottomNavigationBar
└── features/
    ├── history/
    ├── workout/
    └── profile/
```

### Decisiones de diseño relevantes

- **IDs UUID en todas las tablas** → permite generar registros offline sin colisiones al sincronizar con Supabase.
- **`createdAt`, `updatedAt`, `deletedAt` (soft delete) en cada tabla** → base preparada para sync con resolución de conflictos.
- **`MuscleGroup` como enum + JSON via TypeConverter** → simple en Fase 1; migrable a tabla de unión si las queries SQL agregadas del heatmap lo requieren.
- **`PRAGMA foreign_keys = ON`** activado al abrir la DB para forzar integridad referencial.
- **`Clock` y `IdGenerator` como providers Riverpod** → tests deterministas sin tocar `DateTime.now()` global.

## Fases de desarrollo

- ✅ **Fase 1** — Cimientos: scaffolding Flutter, esquema de dominio + Drift, Riverpod, go_router.
- 🚧 **Fase 2** — Funcionalidad core: pantalla de Entrenar con persistencia local, creador de rutinas, auth + sync con Supabase.
- 📋 **Fase 3** — Mapa de calor muscular (SVG interactivo + cálculo de 1RM).
- 📋 **Fase 4** — Sobrecarga progresiva automatizada + integración IA.

## Cómo ejecutar

```bash
flutter pub get
dart run build_runner build        # codegen de Drift
flutter run                        # Android / iOS / Chrome / Edge / Windows
```

Tests:

```bash
flutter test
flutter analyze
```
