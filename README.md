# Rezio SaaS

A modern, full‑stack video optimization SaaS built with Next.js App Router, Clerk authentication, Prisma, NeonDB, and Cloudinary AI. Rezio lets users upload videos, applies smart compression/transcoding on Cloudinary, and stores rich metadata so videos can be browsed, previewed, and downloaded with significant size savings.

- **Framework**: Next.js 15 (App Router)
- **UI**: Tailwind CSS v4 + DaisyUI, Lucide icons
- **Auth**: Clerk
- **Database**: PostgreSQL via Prisma, NeonDB
- **Media**: Cloudinary (uploads, transforms, thumbnails, previews)


## Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Data Model](#data-model)
- [Environment Variables](#environment-variables)
- [Local Development](#local-development)
- [Seeding and Migrations](#seeding-and-migrations)
- [Core Flows](#core-flows)
  - [Authentication](#authentication)
  - [Video Upload](#video-upload)
  - [Video Library](#video-library)
- [API Reference](#api-reference)
- [Media Processing](#media-processing)
- [Production Deployment](#production-deployment)
- [Security & Compliance](#security--compliance)
- [Testing & Linting](#testing--linting)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)


## Features
- **Sign in/up with Clerk** and middleware‑enforced route protection
- **Two upload modes**:
  - Direct unsigned upload from the browser to Cloudinary with an upload preset
  - Server‑side upload via a Next.js route that streams to Cloudinary
- **Automatic compression and MP4 output** using Cloudinary transformations
- **AI‑driven compression**: Cloudinary `quality:auto` selects perceptually optimal codecs/bitrates for significant size reduction with minimal quality loss
- **AI context‑aware cropping**: auto crops and thumbnails using Cloudinary gravity `auto` to keep salient subjects in frame across sizes
- **Video metadata persistence** (title, description, sizes, duration) in PostgreSQL/NeonDB
- **Beautiful UI** with progress feedback, validation, empty/loading/error states
- **Video previews and thumbnails** via `next-cloudinary`
- **Download optimized videos** in one click


## Architecture
- **App Router** organizes routes under `app/`, with authenticated pages in `app/(app)` and auth pages in `app/(auth)`.
- **Middleware** (`middleware.ts`) uses Clerk to allow public routes (e.g., `/sign-in`, `/home`, `/api/videos`) and protect everything else.
- **APIs** live in `app/api/*` routes:
  - `POST /api/video-upload` streams file buffers to Cloudinary server‑side and persists metadata
  - `GET/POST /api/videos` lists and creates `Video` records
- **Database access** via Prisma Client, generated to `app/generated/prisma`.
- **Media** handled with Cloudinary SDK and `next-cloudinary` helpers for URLs, previews, and thumbnails.


## Directory Structure
```
app/
  (app)/
    layout.tsx            # App shell with sidebar, theme toggle, and Clerk user context
    home/page.tsx         # Video library (dashboard)
    video-upload/page.tsx # Upload UI with direct/SSR upload logic
    social-share/page.tsx # (WIP) Social share page
  (auth)/
    sign-in/[[...sign-in]]/page.tsx  # Clerk sign-in UI
    sign-up/[[...sign-up]]/page.tsx  # Clerk sign-up UI
  api/
    videos/route.ts       # GET list, POST create Video
    video-upload/route.ts # POST server-side video upload to Cloudinary
    image-upload/route.ts # POST server-side image upload to Cloudinary
  layout.tsx              # Root layout with ClerkProvider
components/
  VideoCard.tsx           # Video card with thumbnail/preview, stats, and download
prisma/
  schema.prisma           # Prisma models
  migrations/             # SQL migrations
```


## Data Model
Prisma model for `Video`:

```prisma
model Video {
  id             String   @id @default(cuid())
  title          String
  description    String?
  publicId       String
  originalSize   String
  compressedSize String
  duration       Float
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt
}
```

Note: Early migration stored `duration` as `TEXT`; the current schema defines it as `Float`. Run latest migrations and ensure your DB is up to date.


## Environment Variables
Create a `.env` file at the project root with:

```bash
# Database
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DBNAME?schema=public"

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_live_or_test"
CLERK_SECRET_KEY="sk_live_or_test"

# Cloudinary
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="your_cloud_name"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="unsigned_preset_name"  # for direct client uploads
CLOUDINARY_API_KEY="your_api_key"         # for server-side uploads
CLOUDINARY_API_SECRET="your_api_secret"   # for server-side uploads
```

Also ensure your Cloudinary preset is unsigned and allows the `video` resource type if you rely on direct client uploads.


## Local Development
```bash
# 1) Install dependencies
npm install

# 2) Generate Prisma client
npx prisma generate

# 3) Apply migrations
npx prisma migrate deploy
# or during active development
npx prisma migrate dev

# 4) Run the dev server
npm run dev
# open http://localhost:3000
```

Scripts (from `package.json`):
- `dev`: run Next.js dev server
- `prebuild`/`postinstall`: `prisma generate`
- `build`: Next.js build
- `start`: start production server
- `lint`: run Next.js ESLint


## Seeding and Migrations
- Prisma migrations live in `prisma/migrations`.
- Use `npx prisma migrate dev` during development to evolve the schema.
- Use `npx prisma migrate deploy` in CI/CD to apply committed migrations.


## Core Flows
### Authentication
- Clerk wraps the app in `ClerkProvider` (`app/layout.tsx`).
- `middleware.ts` routes:
  - Public: `/`, `/home`, `/sign-in`, `/sign-up`, `/api/videos`
  - All other routes require auth; unauthenticated users are redirected to `/sign-in`.

### Video Upload
Two paths are supported in `app/(app)/video-upload/page.tsx`:
1) **Direct to Cloudinary** (preferred for large files to avoid 413s)
   - Requires `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` and `NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET`.
   - Client uploads to `https://api.cloudinary.com/v1_1/<cloudName>/video/upload`.
   - Then calls `POST /api/videos` to persist metadata.
2) **Server‑side upload**
   - Sends a `FormData` payload to `POST /api/video-upload`.
   - API streams the file to Cloudinary and persists the record.

Both record: `title`, `description`, `publicId`, `originalSize`, `compressedSize`, `duration`.

### Video Library
- `app/(app)/home/page.tsx` fetches `GET /api/videos` and renders `VideoCard` grid with:
  - Cloudinary thumbnail (image) and 15s preview (video)
  - Original vs compressed sizes, duration, time since upload
  - Download button using full‑res Cloudinary video URL


## API Reference
All endpoints are App Router routes.

- `GET /api/videos`
  - Returns an array of `Video` ordered by `createdAt desc`.
  - Public (allowed by middleware) to simplify initial UX.

- `POST /api/videos`
  - Body: `{ title: string; description?: string; publicId: string; originalSize: string; compressedSize: string; duration?: number }`
  - Persists a `Video` record. Returns 201 with the created entity.

- `POST /api/video-upload`
  - Auth required (Clerk enforced in handler).
  - FormData: `file` (File), `title`, `description`, `originalSize`.
  - Streams to Cloudinary as MP4 with `quality:auto` and stores DB record.

- `POST /api/image-upload`
  - Auth required.
  - FormData: `file` (File). Useful for thumbnails/avatars if needed later.

Notes:
- Prisma client is generated to `app/generated/prisma` and imported from there in API routes.
- Remember to disconnect Prisma in long‑lived serverless environments after operations.


## Media Processing
- Cloudinary transformations for server‑side upload (`/api/video-upload`):
  - `resource_type: "video"`, `folder: "video-uploads"`
  - `transformation: [{ quality: "auto", fetch_format: "mp4" }]`
- Thumbnails via `getCldImageUrl` and previews via `getCldVideoUrl` from `next-cloudinary`.
- Preview uses `rawTransformations: ["e_preview:duration_15:max_seg_9:min_seg_dur_1"]` for fast hover playback.


## Production Deployment
- Recommended: **Vercel** for Next.js hosting.
- Set required environment variables in your host (see above).
- Ensure the database is reachable from the hosting environment; for Vercel, use a managed Postgres (Neon, Supabase, RDS) and set `DATABASE_URL`.
- Run `npx prisma migrate deploy` during build or as a post‑deploy step.
- Configure Next.js `images.remotePatterns` (already set for Cloudinary and Clerk).


## Security & Compliance
- Authentication via Clerk; ensure proper domain and redirect URLs in Clerk dashboard.
- API routes that mutate state require authentication.
- Consider moving `GET /api/videos` behind auth in production if privacy is needed.
- Validate file size client‑side (70MB cap in UI) and server‑side as needed.
- Never expose `CLOUDINARY_API_SECRET` to the client – only use it server‑side.


## Testing & Linting
- ESLint: `npm run lint`
- Add your preferred test framework (Jest/Playwright) as you evolve the product.


## Troubleshooting
- "Upload failed" on direct uploads: verify `NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET` is unsigned and allows videos.
- 401 from API: ensure Clerk keys are configured and you are signed in.
- Prisma client path: generated into `app/generated/prisma`; run `npx prisma generate` if missing.
- Migration mismatch (e.g., `duration` type): run latest migrations or adjust the DB column type to `double precision`.


## Contributing
1. Fork the repo and create a feature branch.
2. Install dependencies and set up `.env`.
3. Implement changes with clear commits.
4. Ensure builds and lint pass.
5. Open a pull request with context and screenshots where helpful.


## License
This project is licensed under the MIT License. See `LICENSE` if present, or include one when publishing.
