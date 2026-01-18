# Golf Backend API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Authentication Flow](#authentication-flow)
3. [Registration Flow](#registration-flow)
4. [Core Concepts](#core-concepts)
5. [API Endpoints](#api-endpoints)
   - [Authentication](#authentication-endpoints)
   - [User](#user-endpoints)
   - [Level Progress](#level-progress-endpoints)
   - [Daily Challenge](#daily-challenge-endpoints)
   - [Skins](#skins-endpoints)
6. [Score Calculation](#score-calculation)
7. [Daily Challenge System](#daily-challenge-system)
8. [Skins System](#skins-system)
9. [Error Handling](#error-handling)

---

## Overview

This backend uses **Firebase Authentication** for user authentication. The backend verifies Firebase ID tokens and maintains user profiles, game progress, daily challenges, and cosmetic skins.

### Base URL
```
http://localhost:8089
```

### Authentication Header
All protected endpoints require a Firebase ID token:
```
Authorization: Bearer <firebase_id_token>
```

---

## Authentication Flow

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Swift App     │      │    Firebase     │      │  Golf Backend   │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │  1. Sign in            │                        │
         │───────────────────────>│                        │
         │                        │                        │
         │  2. ID Token           │                        │
         │<───────────────────────│                        │
         │                        │                        │
         │  3. API Request with Bearer token               │
         │────────────────────────────────────────────────>│
         │                        │                        │
         │                        │  4. Verify token       │
         │                        │<───────────────────────│
         │                        │                        │
         │  5. API Response                                │
         │<────────────────────────────────────────────────│
```

---

## Registration Flow

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Swift App     │      │    Firebase     │      │  Golf Backend   │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │  1. Create account     │                        │
         │───────────────────────>│                        │
         │                        │                        │
         │  2. ID Token           │                        │
         │<───────────────────────│                        │
         │                        │                        │
         │  3. GET /auth/check                             │
         │────────────────────────────────────────────────>│
         │                        │                        │
         │  4. { "exists": false }                         │
         │<────────────────────────────────────────────────│
         │                        │                        │
         │  5. Show "Choose Username" screen               │
         │                        │                        │
         │  6. POST /auth/sync { "username": "player1" }   │
         │────────────────────────────────────────────────>│
         │                        │                        │
         │  7. User created with default skin & 0 coins    │
         │<────────────────────────────────────────────────│
```

---

## Core Concepts

### User Entity

Each user has the following attributes:

| Field | Type | Description |
|-------|------|-------------|
| id | Long | Unique identifier |
| firebaseUid | String | Firebase authentication UID |
| username | String | Unique display name (3-100 chars) |
| email | String | Email from Firebase |
| avatarUrl | String | Profile picture URL |
| globalScore | Long | Sum of all level scores |
| ranking | Long | Position in global leaderboard |
| coins | Long | In-game currency (starts at 0) |
| equippedSkin | String | Currently equipped skin ID (default: "default") |

### Coins (In-Game Currency)

Coins are earned through:
- **Daily Challenge rewards** - Based on leaderboard position at end of day
- Future: Other gameplay achievements

Coins are spent on:
- **Purchasing skins** - Cosmetic items with varying prices

### Score System

Scores are calculated on the **backend** using the formula:
```
score = (stars × 1000) + max(0, (parTimeMs - timeToPassMs) / 100)
```

The client sends only `stars` and `timeToPassMs`; the backend calculates and stores the score.

---

## API Endpoints

### Authentication Endpoints

#### Check User Exists
```
GET /api/v1/auth/check
```
Returns whether the authenticated Firebase user has a profile in the backend.

**Response Fields:**
- `exists` (boolean) - Whether user profile exists
- `firebaseUid` (string) - The Firebase UID

---

#### Sync/Register User
```
POST /api/v1/auth/sync
```
Creates a new user profile or returns existing one.

**Request Fields:**
- `username` (string, required) - Unique username, 3-100 characters

**Response Fields:**
- `id`, `username`, `email`, `avatarUrl`, `globalScore`, `ranking`, `coins`, `equippedSkin`

**Logic:**
1. Check if user exists by Firebase UID
2. If exists → Return existing user
3. If not exists → Validate username uniqueness → Create user with 0 coins and "default" skin

---

#### Get Current User Profile
```
GET /api/v1/auth/me
```
Returns the authenticated user's full profile including coins and equipped skin.

---

### User Endpoints

#### Get User by ID
```
GET /api/v1/users/{userId}
```
Returns user profile. Users can only access their own data.

---

#### Update User Profile
```
PUT /api/v1/users/{userId}
```
Updates username and/or avatar URL.

**Request Fields:**
- `username` (string, optional) - New username
- `avatarUrl` (string, optional) - New avatar URL

**Logic:**
1. Verify user is updating their own profile
2. If username provided and different → Validate uniqueness → Update
3. If avatarUrl provided → Update

---

#### Upload Avatar
```
POST /api/v1/users/me/avatar
```
Uploads profile image to Firebase Storage.

**Request:** Multipart form data with `file` field

**Logic:**
1. Validate file type (JPEG, PNG, GIF, WebP) and size (max 5MB)
2. If user has existing Firebase Storage avatar → Delete it
3. Upload new image with unique filename
4. Update user's avatarUrl in database

---

### Level Progress Endpoints

#### Complete Level
```
POST /api/v1/levels/complete
```
Submits level completion. Score is calculated on backend.

**Request Fields:**
- `levelNumber` (integer, required) - Level number (min: 1)
- `timeToPassMs` (long, required) - Completion time in milliseconds
- `stars` (integer, required) - Stars earned (1-3)

**Note:** Score field is NOT sent by client. Backend calculates it.

**Response Fields:**
- `id`, `levelNumber`, `timeToPassMs`, `score`, `stars`, `createdAt`, `updatedAt`

**Logic:**
1. Calculate score: `(stars × 1000) + max(0, (parTimeMs - timeToPassMs) / 100)`
2. Find existing progress for this level
3. If no existing progress → Create new record
4. If existing progress:
   - Update if new score is higher
   - If same score, update if time is faster
5. Recalculate user's globalScore (sum of all level scores)

---

#### Get All Level Progress
```
GET /api/v1/levels
```
Returns all completed levels for the user, ordered by level number.

---

#### Get Specific Level Progress
```
GET /api/v1/levels/{levelNumber}
```
Returns progress for a specific level.

---

#### Get User Stats
```
GET /api/v1/levels/stats
```
Returns aggregated statistics.

**Response Fields:**
- `totalScore` (long) - Sum of all level scores
- `levelsCompleted` (long) - Number of levels completed
- `totalStars` (long) - Sum of all stars earned

---

### Daily Challenge Endpoints

#### Get Today's Challenge
```
GET /api/v1/daily-challenge
```
Returns today's daily challenge with user's participation stats.

**Response Fields:**
- `id` (long) - Challenge ID
- `challengeDate` (date) - The date of the challenge
- `fileUrl` (string) - URL to the challenge file in Firebase Storage
- `title` (string, optional) - Challenge title
- `description` (string, optional) - Challenge description
- `createdAt` (datetime) - When the challenge was created
- `totalParticipants` (long) - Number of unique users who attempted
- `userAttempts` (long) - Current user's number of attempts
- `userBestStars` (integer, nullable) - Current user's best stars for this challenge

---

#### Get Challenge by Date
```
GET /api/v1/daily-challenge/date/{date}
```
Returns challenge for a specific date. Date format: `YYYY-MM-DD`

---

#### Submit Daily Challenge Attempt
```
POST /api/v1/daily-challenge/complete
```
Submits an attempt for today's challenge. Users can submit multiple attempts.

**Request Fields:**
- `timeToPassMs` (long, required) - Completion time in milliseconds
- `strokes` (integer, required) - Number of strokes taken
- `stars` (integer, required) - Stars earned (1-3)

**Note:** Score is calculated on backend using same formula as levels.

**Response Fields:**
- `id`, `score`, `timeToPassMs`, `strokes`, `stars`, `completedAt`, `userId`, `username`, `avatarUrl`

**Logic:**
1. Find today's challenge (error if none exists)
2. Calculate score from stars and time
3. Create new attempt record (all attempts are saved, not just best)

---

#### Get My Attempts (Today)
```
GET /api/v1/daily-challenge/my-attempts
```
Returns all of the user's attempts for today's challenge, ordered by stars (desc) then time (asc).

---

#### Get My Attempts by Date
```
GET /api/v1/daily-challenge/my-attempts/{date}
```
Returns user's attempts for a specific date's challenge.

---

#### Get Today's Leaderboard
```
GET /api/v1/daily-challenge/leaderboard?limit=100
```
Returns the leaderboard for today's challenge.

**Query Parameters:**
- `limit` (integer, optional, default: 100) - Maximum entries to return

**Response:** Array of leaderboard entries

**Leaderboard Entry Fields:**
- `rank` (integer) - Position (1-based)
- `userId` (long) - User ID
- `username` (string) - Display name
- `avatarUrl` (string, nullable) - Profile picture
- `stars` (integer) - Best stars achieved
- `bestTimeMs` (long) - Best time in milliseconds
- `strokes` (integer) - Strokes for best attempt
- `score` (long) - Calculated score
- `achievedAt` (datetime) - When best attempt was made
- `coinsReward` (long) - Coins user will receive (based on rank)

**Ranking Logic:**
1. **Primary sort:** Stars (descending) - More stars = higher rank
2. **Secondary sort:** Time (ascending) - Same stars, faster time = higher rank
3. Only best attempt per user is considered

---

#### Get Leaderboard by Date
```
GET /api/v1/daily-challenge/leaderboard/{date}?limit=100
```
Returns leaderboard for a specific date's challenge.

---

#### [Admin] Create Daily Challenge
```
POST /api/v1/daily-challenge/admin/create
```
Creates a new daily challenge. Should be called by admin/scheduler.

**Request Fields:**
- `challengeDate` (date, required) - Date for the challenge (format: YYYY-MM-DD)
- `fileUrl` (string, required) - URL to challenge file in Firebase Storage
- `title` (string, optional) - Challenge title
- `description` (string, optional) - Challenge description

**Logic:**
1. Validate no challenge exists for this date
2. Create challenge record

---

#### [Admin] Distribute Rewards for Date
```
POST /api/v1/daily-challenge/admin/distribute-rewards/{date}
```
Manually triggers reward distribution for a specific date.

**Response Fields:**
- `date` (date) - The challenge date
- `usersRewarded` (integer) - Number of users who received rewards
- `totalCoinsDistributed` (long) - Total coins distributed

**Logic:**
1. Find challenge for date
2. Verify rewards not already distributed
3. Get best attempt per user, ranked by stars then time
4. Distribute coins based on rank
5. Mark challenge as rewards distributed

---

#### [Admin] Distribute All Pending Rewards
```
POST /api/v1/daily-challenge/admin/distribute-all-rewards
```
Distributes rewards for all past challenges that haven't been processed.

**Response:** Array of RewardDistributionResult

---

### Skins Endpoints

#### Get All Skins
```
GET /api/v1/skins
```
Returns all available skins with ownership and equipped status.

**Response:** Array of skin objects

**Skin Fields:**
- `id` (string) - Unique skin identifier
- `name` (string) - Display name
- `description` (string) - Skin description
- `price` (long) - Cost in coins
- `imageUrl` (string) - Path to skin image
- `owned` (boolean) - Whether current user owns this skin
- `equipped` (boolean) - Whether this skin is currently equipped

---

#### Get Owned Skins
```
GET /api/v1/skins/owned
```
Returns only the skins owned by the current user.

---

#### Get Equipped Skin
```
GET /api/v1/skins/equipped
```
Returns the currently equipped skin.

---

#### Buy Skin
```
POST /api/v1/skins/buy
```
Purchases a skin using coins.

**Request Fields:**
- `skinId` (string, required) - ID of the skin to purchase

**Response Fields:**
- `skinId` (string) - Purchased skin ID
- `skinName` (string) - Skin display name
- `pricePaid` (long) - Coins spent
- `remainingCoins` (long) - User's new coin balance
- `message` (string) - Success message

**Logic:**
1. Validate skin exists
2. Validate user doesn't already own it
3. Validate user has sufficient coins
4. Deduct coins from user
5. Add skin to user's collection

**Errors:**
- "Skin not found" - Invalid skin ID
- "You already own this skin" - Already purchased
- "Not enough coins" - Insufficient balance

---

#### Equip Skin
```
POST /api/v1/skins/equip
```
Sets a skin as the user's active skin.

**Request Fields:**
- `skinId` (string, required) - ID of the skin to equip

**Response:** The equipped skin object

**Logic:**
1. Validate skin exists
2. Validate user owns the skin (or it's "default")
3. Update user's equippedSkin field

**Errors:**
- "Skin not found" - Invalid skin ID
- "You don't own this skin" - Not purchased

---

## Score Calculation

All scores are calculated on the backend, not sent by the client.

### Formula
```
score = (stars × 1000) + max(0, (parTimeMs - timeToPassMs) / 100)
```

### Components
- **Base Score:** Stars × 1000 (1★ = 1000, 2★ = 2000, 3★ = 3000)
- **Time Bonus:** Points for completing faster than par time
  - Each 100ms under par = +1 point
  - No penalty for being slower than par

### Par Time Configuration
Configured in `application.properties`:
```properties
score.level.par-time-ms=60000
score.daily-challenge.par-time-ms=60000
```

### Examples (60 second par time)
| Stars | Time | Calculation | Score |
|-------|------|-------------|-------|
| 3 | 45s | 3000 + (60000-45000)/100 | 3150 |
| 3 | 60s | 3000 + 0 | 3000 |
| 3 | 70s | 3000 + 0 | 3000 |
| 2 | 50s | 2000 + (60000-50000)/100 | 2100 |
| 1 | 30s | 1000 + (60000-30000)/100 | 1300 |

---

## Daily Challenge System

### Overview

Daily challenges are special levels that change every day. Users compete for the best performance and earn coins based on their leaderboard position at the end of the day.

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         DAY LIFECYCLE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  00:00 ─────── Challenge for today becomes active ──────────>   │
│                                                                 │
│  Throughout day: Users submit attempts                          │
│    - GET /daily-challenge → Get challenge info                  │
│    - POST /daily-challenge/complete → Submit attempt            │
│    - GET /daily-challenge/leaderboard → View rankings           │
│                                                                 │
│  23:59 ─────── Last chance to submit attempts ──────────────>   │
│                                                                 │
│  00:05 (next day) ─── Automatic reward distribution ────────>   │
│    - Leaderboard is finalized                                   │
│    - Coins distributed based on final rankings                  │
│    - Challenge marked as "rewards distributed"                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Leaderboard Ranking

Users are ranked by:
1. **Stars (primary):** More stars = higher rank
2. **Time (secondary):** If same stars, faster time wins

Only the user's **best attempt** counts for the leaderboard (best = most stars, then fastest time).

### Reward Tiers

| Rank | Coins |
|------|-------|
| 1st | 1000 |
| 2nd | 750 |
| 3rd | 500 |
| 4th | 300 |
| 5th | 200 |
| 6th-10th | 150 |
| 11th+ | 50 (participation) |

### Automatic Reward Distribution

Scheduled tasks run automatically (configured in `application.properties`):

```properties
daily-challenge.rewards.cron=0 5 0 * * *      # 00:05 daily - distribute yesterday's rewards
daily-challenge.missed-rewards.cron=0 10 0 * * *  # 00:10 daily - catch any missed distributions
```

### Challenge Storage

Each daily challenge has:
- **challengeDate** - Unique date (one challenge per day)
- **fileUrl** - Link to Firebase Storage containing the level data
- **title/description** - Optional metadata
- **rewardsDistributed** - Flag to prevent double distribution

---

## Skins System

### Overview

Skins are cosmetic items that users can purchase with coins and equip on their golf ball.

### Skin Configuration

Skins are defined in `application.properties`:
```properties
skins.available[0]=default,Default Ball,The classic white golf ball,0,skins/default.png
skins.available[1]=golden,Golden Ball,A shiny golden golf ball,500,skins/golden.png
# Format: id,name,description,price,imageUrl
```

### Available Skins

| ID | Name | Price |
|----|------|-------|
| default | Default Ball | 0 (free) |
| golden | Golden Ball | 500 |
| fire | Fire Ball | 1000 |
| ice | Ice Ball | 1000 |
| rainbow | Rainbow Ball | 2000 |
| diamond | Diamond Ball | 5000 |
| galaxy | Galaxy Ball | 7500 |
| legendary | Legendary Ball | 10000 |

### Ownership Rules

1. **Default skin** is always owned by all users
2. Other skins must be purchased with coins
3. Each skin can only be purchased once
4. Purchased skins are permanently owned

### Equipment

- Users can equip any skin they own
- Only one skin can be equipped at a time
- Equipped skin is stored in user's `equippedSkin` field
- New users start with "default" skin equipped

---

## Error Handling

### Error Response Format
```json
{
    "timestamp": "2025-12-05T10:30:00.123456Z",
    "status": 400,
    "error": "Bad Request",
    "message": "Detailed error message",
    "path": "/api/v1/endpoint"
}
```

### HTTP Status Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Validation error, invalid input |
| 401 | Unauthorized | Missing/invalid/expired Firebase token |
| 403 | Forbidden | Accessing another user's data |
| 404 | Not Found | Resource doesn't exist |
| 500 | Internal Server Error | Server-side error |

### Common Error Messages

| Message | Cause |
|---------|-------|
| "Invalid or expired Firebase token" | Token expired |
| "Username already exists" | Username taken |
| "User not found" | Profile doesn't exist |
| "No challenge available for today" | No daily challenge created |
| "No challenge found for date: X" | Invalid date |
| "Rewards have already been distributed" | Double distribution attempt |
| "Skin not found" | Invalid skin ID |
| "You already own this skin" | Already purchased |
| "Not enough coins" | Insufficient balance |
| "You don't own this skin" | Trying to equip unowned skin |

---

## Endpoints Summary

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/auth/check` | Check if user exists |
| POST | `/api/v1/auth/sync` | Create/get user profile |
| GET | `/api/v1/auth/me` | Get current user |

### User
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users/{id}` | Get user by ID |
| PUT | `/api/v1/users/{id}` | Update profile |
| POST | `/api/v1/users/me/avatar` | Upload avatar |

### Level Progress
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/levels/complete` | Submit level completion |
| GET | `/api/v1/levels` | Get all progress |
| GET | `/api/v1/levels/{levelNumber}` | Get level progress |
| GET | `/api/v1/levels/stats` | Get statistics |

### Daily Challenge
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/daily-challenge` | Get today's challenge |
| GET | `/api/v1/daily-challenge/date/{date}` | Get challenge by date |
| POST | `/api/v1/daily-challenge/complete` | Submit attempt |
| GET | `/api/v1/daily-challenge/my-attempts` | Get my attempts (today) |
| GET | `/api/v1/daily-challenge/my-attempts/{date}` | Get my attempts by date |
| GET | `/api/v1/daily-challenge/leaderboard` | Get today's leaderboard |
| GET | `/api/v1/daily-challenge/leaderboard/{date}` | Get leaderboard by date |
| POST | `/api/v1/daily-challenge/admin/create` | [Admin] Create challenge |
| POST | `/api/v1/daily-challenge/admin/distribute-rewards/{date}` | [Admin] Distribute rewards |
| POST | `/api/v1/daily-challenge/admin/distribute-all-rewards` | [Admin] Distribute all pending |

### Skins
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/skins` | Get all skins |
| GET | `/api/v1/skins/owned` | Get owned skins |
| GET | `/api/v1/skins/equipped` | Get equipped skin |
| POST | `/api/v1/skins/buy` | Purchase skin |
| POST | `/api/v1/skins/equip` | Equip skin |

---

## Database Entities

### Users Table
- `id` - Primary key
- `firebase_uid` - Firebase UID (unique)
- `username` - Display name (unique)
- `email` - Email address
- `avatar_url` - Profile picture URL
- `global_score` - Sum of all level scores
- `ranking` - Global leaderboard position
- `coins` - In-game currency balance
- `equipped_skin` - Currently equipped skin ID

### Level Progress Table
- `id` - Primary key
- `user_id` - Foreign key to users
- `level_number` - Level identifier
- `time_to_pass_ms` - Completion time
- `score` - Calculated score
- `stars` - Stars earned (1-3)
- Unique constraint: (user_id, level_number)

### Daily Challenges Table
- `id` - Primary key
- `challenge_date` - Date (unique)
- `file_url` - Firebase Storage URL
- `title` - Optional title
- `description` - Optional description
- `rewards_distributed` - Boolean flag
- `created_at` - Creation timestamp

### Daily Challenge Attempts Table
- `id` - Primary key
- `user_id` - Foreign key to users
- `daily_challenge_id` - Foreign key to daily_challenges
- `score` - Calculated score
- `time_to_pass_ms` - Completion time
- `strokes` - Number of strokes
- `stars` - Stars earned (1-3)
- `completed_at` - Attempt timestamp

### User Skins Table
- `id` - Primary key
- `user_id` - Foreign key to users
- `skin_id` - Skin identifier
- `purchased_at` - Purchase timestamp
- Unique constraint: (user_id, skin_id)
