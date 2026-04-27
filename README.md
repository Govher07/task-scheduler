# Task Scheduler

A Flutter app for tracking long-term goals, daily tasks, and scheduled events on a calendar. Includes a task recommender that suggests what to work on next based on priority and deadlines.

## Features

- **Goals** — Create long-term goals (completable or ongoing) and group tasks under them
- **Tasks** — Track tasks with priority, effort level, deadlines, and status (todo / in progress / done)
- **Calendar** — Schedule events with date/time, optionally linked to tasks
- **Recommender** — Get smart suggestions for which task to work on next, scored by priority and deadline urgency

## Tech Stack

- **Flutter/Dart** — UI framework
- **Supabase (Postgres)** — Cloud database
- **Riverpod** — State management
- **GoRouter** — Declarative routing
- **Freezed** — Immutable domain models
- **Drift** — Local database (used in tests)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.41+ stable)
- A web browser (Chrome recommended)
- Git

## Setup

1. **Clone the repo**

   ```bash
   git clone https://github.com/gwenbayar/task-scheduler.git
   cd task-scheduler
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run code generation** (needed for Freezed models and Drift)

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**

   ```bash
   flutter run -d chrome
   ```

## Running Tests

```bash
flutter test
```

The test suite covers domain models, repository logic (via in-memory Drift DB), and the recommender scoring algorithm.

## Project Structure

```
lib/
  core/
    models/          # Freezed domain models (Goal, Task, Event, enums)
    database/        # Drift tables and database (used in tests)
    repositories/    # Abstract interfaces + Supabase implementations
    providers.dart   # Riverpod providers wiring repos to UI
    widgets/         # Shared UI components
  features/
    goals/           # Goals & tasks screen, forms, providers
    calendar/        # Calendar screen, event forms, providers
    recommender/     # Task recommender screen, scoring logic
  app.dart           # GoRouter setup, bottom navigation shell
  main.dart          # App entry point, Supabase initialization
```

Each feature folder is self-contained with its own screens, providers, and widgets. This makes it easy to divide work — one person can work on `features/calendar/` without touching `features/goals/`.

## Supabase

The app uses a shared Supabase project for the database. The connection is already configured in `lib/main.dart`. If you need to set up your own Supabase project:

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** in the dashboard and run:

   ```sql
   create table public.goals (
     id text primary key,
     name text not null,
     type text not null default 'completable',
     description text,
     created_at timestamptz not null default now(),
     updated_at timestamptz not null default now()
   );

   create table public.tasks (
     id text primary key,
     name text not null,
     goal_id text references public.goals(id) on delete set null,
     priority text not null default 'medium',
     deadline timestamptz,
     estimated_duration_minutes integer,
     effort_level text not null default 'medium',
     status text not null default 'todo',
     created_at timestamptz not null default now(),
     updated_at timestamptz not null default now()
   );

   create table public.events (
     id text primary key,
     name text not null,
     task_id text references public.tasks(id) on delete set null,
     start_time timestamptz not null,
     end_time timestamptz not null,
     is_repeating boolean not null default false,
     recurrence_rule text,
     created_at timestamptz not null default now(),
     updated_at timestamptz not null default now()
   );

   alter table public.goals enable row level security;
   alter table public.tasks enable row level security;
   alter table public.events enable row level security;

   create policy "Allow all access" on public.goals for all using (true) with check (true);
   create policy "Allow all access" on public.tasks for all using (true) with check (true);
   create policy "Allow all access" on public.events for all using (true) with check (true);

   alter publication supabase_realtime add table public.goals;
   alter publication supabase_realtime add table public.tasks;
   alter publication supabase_realtime add table public.events;
   ```

3. Update the `url` and `anonKey` in `lib/main.dart` with your project's values (found in Project Settings > API)
