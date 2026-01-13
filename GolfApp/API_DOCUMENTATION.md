# Golf Backend API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Authentication Flow](#authentication-flow)
3. [Registration Flow](#registration-flow)
4. [API Endpoints](#api-endpoints)
5. [Error Handling](#error-handling)
6. [Swift Integration Guide](#swift-integration-guide)

---

## Overview

This backend uses **Firebase Authentication** for user authentication. The backend does not handle passwords or authentication directly — Firebase manages all authentication logic. The backend only verifies Firebase ID tokens and maintains user profiles and game data.

### Base URL
```
http://localhost:8088
```

### Authentication Header
All protected endpoints require a Firebase ID token in the Authorization header:
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
         │  (Google/Apple/Email)  │                        │
         │───────────────────────>│                        │
         │                        │                        │
         │  2. Returns ID Token   │                        │
         │<───────────────────────│                        │
         │                        │                        │
         │  3. API Request                                 │
         │  Authorization: Bearer <token>                  │
         │────────────────────────────────────────────────>│
         │                        │                        │
         │                        │  4. Verify token       │
         │                        │<───────────────────────│
         │                        │                        │
         │                        │  5. Token valid ✓      │
         │                        │───────────────────────>│
         │                        │                        │
         │  6. API Response                                │
         │<────────────────────────────────────────────────│
```

### How It Works

1. **User signs in with Firebase** on the Swift app (Google, Apple, Email/Password)
2. **Firebase returns an ID token** (JWT) valid for 1 hour
3. **Swift app sends API requests** with the token in the `Authorization` header
4. **Backend verifies the token** using Firebase Admin SDK
5. **Backend processes the request** if token is valid
6. **ID tokens auto-refresh** — always call `getIDToken()` before requests

### Token Expiration
- ID tokens expire after **1 hour**
- Firebase SDK automatically refreshes tokens
- Always fetch a fresh token before API calls using `getIDToken()`

---

## Registration Flow

With Firebase, registration and login are essentially the same process:

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Swift App     │      │    Firebase     │      │  Golf Backend   │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │  1. Create account     │                        │
         │  (or sign in)          │                        │
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
         │  6. POST /auth/sync                             │
         │     { "username": "player1" }                   │
         │────────────────────────────────────────────────>│
         │                        │                        │
         │  7. User created ✓                              │
         │<────────────────────────────────────────────────│
```

### Steps:

1. User creates Firebase account (or signs in)
2. App receives Firebase ID token
3. App calls `GET /auth/check` to see if user profile exists
4. If `exists: false` → Show username selection screen
5. If `exists: true` → User is returning, go to home
6. For new users: Call `POST /auth/sync` with chosen username
7. Backend creates user profile linked to Firebase UID

---

## API Endpoints

### Authentication Endpoints

#### Check User Exists
Check if the authenticated Firebase user has a profile in the backend.

```
GET /api/v1/auth/check
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200 OK):**
```json
{
    "exists": true,
    "firebaseUid": "abc123xyz789"
}
```

**Use Case:** Call after Firebase sign-in to determine if user needs to create a profile.

---

#### Sync/Register User
Create a new user profile or return existing one.

```
POST /api/v1/auth/sync
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

**Request Body:**
```json
{
    "username": "player1"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| username | string | Yes | 3-100 characters, unique |

**Response (200 OK):**
```json
{
    "id": 1,
    "username": "player1",
    "email": "user@example.com",
    "avatarUrl": "https://lh3.googleusercontent.com/...",
    "globalScore": 0,
    "ranking": null
}
```

**Error Response (400 Bad Request):**
```json
{
    "timestamp": "2025-12-05T10:30:00.123Z",
    "status": 400,
    "error": "Bad Request",
    "message": "Username already exists",
    "path": "/api/v1/auth/sync"
}
```

---

#### Get Current User Profile
Get the authenticated user's profile.

```
GET /api/v1/auth/me
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200 OK):**
```json
{
    "id": 1,
    "username": "player1",
    "email": "user@example.com",
    "avatarUrl": "https://lh3.googleusercontent.com/...",
    "globalScore": 15000,
    "ranking": 42
}
```

---

### User Endpoints

#### Get User by ID
Get a user's profile by ID. Users can only access their own data.

```
GET /api/v1/users/{userId}
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200 OK):**
```json
{
    "id": 1,
    "username": "player1",
    "email": "user@example.com",
    "avatarUrl": "https://example.com/avatar.jpg",
    "globalScore": 15000,
    "ranking": 42
}
```

**Error Response (403 Forbidden):**
```json
{
    "timestamp": "2025-12-05T10:30:00.123Z",
    "status": 403,
    "error": "Forbidden",
    "message": "You can only access your own data",
    "path": "/api/v1/users/5"
}
```

---

#### Update User Profile
Update the authenticated user's profile.

```
PUT /api/v1/users/{userId}
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

**Request Body:**
```json
{
    "username": "newUsername",
    "avatarUrl": "https://example.com/new-avatar.jpg"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| username | string | No | 3-100 characters, unique |
| avatarUrl | string | No | Max 512 characters |

**Response (200 OK):**
```json
{
    "id": 1,
    "username": "newUsername",
    "email": "user@example.com",
    "avatarUrl": "https://example.com/new-avatar.jpg",
    "globalScore": 15000,
    "ranking": 42
}
```

---

#### Upload Avatar
Upload a profile photo. The image is stored in Firebase Storage and the URL is saved to the user's profile.

```
POST /api/v1/users/me/avatar
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
Content-Type: multipart/form-data
```

**Request Body:**
- Form field: `file` - The image file

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| file | File | Yes | Max 5MB, JPEG/PNG/GIF/WebP only |

**Response (200 OK):**
```json
{
    "avatarUrl": "https://storage.googleapis.com/your-bucket/avatars/1_abc123.jpg",
    "message": "Avatar uploaded successfully"
}
```

**Error Responses:**

*File too large (400 Bad Request):*
```json
{
    "timestamp": "2025-12-05T10:30:00.123Z",
    "status": 400,
    "error": "Bad Request",
    "message": "File size exceeds maximum limit of 5MB",
    "path": "/api/v1/users/me/avatar"
}
```

*Invalid file type (400 Bad Request):*
```json
{
    "timestamp": "2025-12-05T10:30:00.123Z",
    "status": 400,
    "error": "Bad Request",
    "message": "Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed",
    "path": "/api/v1/users/me/avatar"
}
```

**Behavior:**
- Automatically deletes previous avatar from Firebase Storage (if it was uploaded via this endpoint)
- Generates unique filename: `{userId}_{uuid}.{extension}`
- Updates user's `avatarUrl` in database
- Returns the public URL of the uploaded image

---

### Level Progress Endpoints

#### Complete Level
Submit level completion data. Updates existing progress only if the new score is better.

```
POST /api/v1/levels/complete
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

**Request Body:**
```json
{
    "levelNumber": 5,
    "timeToPassMs": 45000,
    "score": 1250,
    "stars": 3
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| levelNumber | integer | Yes | Min: 1 |
| timeToPassMs | long | Yes | Min: 0 (milliseconds) |
| score | long | Yes | Min: 0 |
| stars | integer | Yes | 1-3 |

**Response (200 OK):**
```json
{
    "id": 1,
    "levelNumber": 5,
    "timeToPassMs": 45000,
    "score": 1250,
    "stars": 3,
    "createdAt": "2025-12-05T10:30:00",
    "updatedAt": "2025-12-05T10:30:00"
}
```

**Behavior:**
- If level not previously completed → Creates new record
- If level already completed:
  - Updates score only if new score is **higher**
  - Updates stars only if new stars is **higher**
  - Updates time only if new time is **faster** (and score is same or better)
- Automatically updates user's `globalScore`

---

#### Get All Level Progress
Get all level progress for the authenticated user.

```
GET /api/v1/levels
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200 OK):**
```json
[
    {
        "id": 1,
        "levelNumber": 1,
        "timeToPassMs": 30000,
        "score": 1000,
        "stars": 3,
        "createdAt": "2025-12-01T10:00:00",
        "updatedAt": "2025-12-01T10:00:00"
    },
    {
        "id": 2,
        "levelNumber": 2,
        "timeToPassMs": 45000,
        "score": 850,
        "stars": 2,
        "createdAt": "2025-12-02T11:00:00",
        "updatedAt": "2025-12-02T11:00:00"
    }
]
```

---

#### Get Specific Level Progress
Get progress for a specific level.

```
GET /api/v1/levels/{levelNumber}
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200 OK):**
```json
{
    "id": 1,
    "levelNumber": 5,
    "timeToPassMs": 45000,
    "score": 1250,
    "stars": 3,
    "createdAt": "2025-12-05T10:30:00",
    "updatedAt": "2025-12-05T10:30:00"
}
```

**Error Response (400 Bad Request):**
```json
{
    "timestamp": "2025-12-05T10:30:00.123Z",
    "status": 400,
    "error": "Bad Request",
    "message": "Level progress not found",
    "path": "/api/v1/levels/99"
}
```

---

#### Get User Stats
Get aggregated statistics for the authenticated user.

```
GET /api/v1/levels/stats
```

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response (200 OK):**
```json
{
    "totalScore": 15000,
    "levelsCompleted": 12,
    "totalStars": 30
}
```

---

## Error Handling

All errors follow a consistent format:

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
| 403 | Forbidden | Trying to access another user's data |
| 404 | Not Found | Resource doesn't exist |
| 500 | Internal Server Error | Server-side error |

### Common Error Messages

| Message | Cause | Solution |
|---------|-------|----------|
| "Invalid or expired Firebase token" | Token expired or malformed | Get fresh token with `getIDToken()` |
| "Username already exists" | Username taken | Choose different username |
| "User not found" | User profile doesn't exist | Call `/auth/sync` first |
| "You can only access your own data" | Accessing other user's resource | Use correct user ID |
| "Level progress not found" | Level not completed yet | Complete the level first |

---

## Swift Integration Guide

### Setup

1. Add Firebase SDK to your project (FirebaseAuth)
2. Configure Firebase in your app

### API Client

```swift
import Foundation
import FirebaseAuth

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:8088"
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    
    private init() {
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic Request Method
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        // Get fresh Firebase token
        guard let user = Auth.auth().currentUser else {
            throw APIError.notAuthenticated
        }
        
        let token = try await user.getIDToken()
        
        // Build request
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Execute request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle errors
        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 400, 404:
            let error = try decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(error.message)
        default:
            throw APIError.unknown
        }
    }
}

// MARK: - Error Types

enum APIError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case serverError(String)
    case unknown
}

struct APIErrorResponse: Decodable {
    let timestamp: String
    let status: Int
    let error: String
    let message: String
    let path: String
}
```

### Models

```swift
// MARK: - User

struct UserResponse: Codable {
    let id: Int
    let username: String
    let email: String?
    let avatarUrl: String?
    let globalScore: Int
    let ranking: Int?
}

struct CheckResponse: Codable {
    let exists: Bool
    let firebaseUid: String
}

struct SyncUserRequest: Codable {
    let username: String
}

struct UpdateProfileRequest: Codable {
    let username: String?
    let avatarUrl: String?
}

// MARK: - Level Progress

struct LevelCompleteRequest: Codable {
    let levelNumber: Int
    let timeToPassMs: Int
    let score: Int
    let stars: Int
}

struct LevelProgressResponse: Codable {
    let id: Int
    let levelNumber: Int
    let timeToPassMs: Int
    let score: Int
    let stars: Int
    let createdAt: String
    let updatedAt: String
}

struct UserStats: Codable {
    let totalScore: Int
    let levelsCompleted: Int
    let totalStars: Int
}

// MARK: - Avatar

struct AvatarUploadResponse: Codable {
    let avatarUrl: String
    let message: String
}
```

### Auth Service

```swift
import FirebaseAuth

class AuthService {
    static let shared = AuthService()
    private let api = APIClient.shared
    
    private init() {}
    
    // MARK: - Sign In with Google
    
    func signInWithGoogle(credential: AuthCredential) async throws -> UserResponse {
        // Sign in with Firebase
        let result = try await Auth.auth().signIn(with: credential)
        
        // Check if user exists in backend
        let check: CheckResponse = try await api.request(endpoint: "/api/v1/auth/check")
        
        if check.exists {
            // Returning user - get profile
            return try await api.request(endpoint: "/api/v1/auth/me")
        } else {
            // New user - needs to pick username
            throw AuthError.needsUsername
        }
    }
    
    // MARK: - Complete Registration
    
    func completeRegistration(username: String) async throws -> UserResponse {
        let request = SyncUserRequest(username: username)
        return try await api.request(
            endpoint: "/api/v1/auth/sync",
            method: "POST",
            body: request
        )
    }
    
    // MARK: - Get Current User
    
    func getCurrentUser() async throws -> UserResponse {
        return try await api.request(endpoint: "/api/v1/auth/me")
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}

enum AuthError: Error {
    case needsUsername
}
```

### Level Service

```swift
class LevelService {
    static let shared = LevelService()
    private let api = APIClient.shared
    
    private init() {}
    
    // MARK: - Complete Level
    
    func completeLevel(
        levelNumber: Int,
        timeMs: Int,
        score: Int,
        stars: Int
    ) async throws -> LevelProgressResponse {
        let request = LevelCompleteRequest(
            levelNumber: levelNumber,
            timeToPassMs: timeMs,
            score: score,
            stars: stars
        )
        
        return try await api.request(
            endpoint: "/api/v1/levels/complete",
            method: "POST",
            body: request
        )
    }
    
    // MARK: - Get All Progress
    
    func getAllProgress() async throws -> [LevelProgressResponse] {
        return try await api.request(endpoint: "/api/v1/levels")
    }
    
    // MARK: - Get Level Progress
    
    func getLevelProgress(levelNumber: Int) async throws -> LevelProgressResponse {
        return try await api.request(endpoint: "/api/v1/levels/\(levelNumber)")
    }
    
    // MARK: - Get Stats
    
    func getStats() async throws -> UserStats {
        return try await api.request(endpoint: "/api/v1/levels/stats")
    }
}
```

### Usage Examples

```swift
// MARK: - App Launch Flow

func handleAppLaunch() async {
    if Auth.auth().currentUser != nil {
        do {
            let user = try await AuthService.shared.getCurrentUser()
            navigateToHome(user: user)
        } catch {
            navigateToLogin()
        }
    } else {
        navigateToLogin()
    }
}

// MARK: - After Google Sign In

func handleGoogleSignIn(credential: AuthCredential) async {
    do {
        let user = try await AuthService.shared.signInWithGoogle(credential: credential)
        navigateToHome(user: user)
    } catch AuthError.needsUsername {
        navigateToUsernameSelection()
    } catch {
        showError(error)
    }
}

// MARK: - Username Selection

func submitUsername(_ username: String) async {
    do {
        let user = try await AuthService.shared.completeRegistration(username: username)
        navigateToHome(user: user)
    } catch {
        showError(error) // e.g., "Username already exists"
    }
}

// MARK: - Level Completion

func onLevelComplete(level: Int, timeMs: Int, score: Int, stars: Int) async {
    do {
        let progress = try await LevelService.shared.completeLevel(
            levelNumber: level,
            timeMs: timeMs,
            score: score,
            stars: stars
        )
        print("Level \(level) saved! Best score: \(progress.score)")
    } catch {
        showError(error)
    }
}

// MARK: - Load Level Select Screen

func loadLevelSelectScreen() async {
    do {
        let allProgress = try await LevelService.shared.getAllProgress()
        let stats = try await LevelService.shared.getStats()
        
        updateUI(progress: allProgress, stats: stats)
    } catch {
        showError(error)
    }
}

// MARK: - Upload Avatar

func uploadAvatar(imageData: Data) async {
    do {
        let response = try await UserService.shared.uploadAvatar(imageData: imageData)
        print("Avatar uploaded: \(response.avatarUrl)")
        updateAvatarUI(url: response.avatarUrl)
    } catch {
        showError(error)
    }
}
```

### User Service (Avatar Upload)

```swift
import Foundation
import FirebaseAuth

class UserService {
    static let shared = UserService()
    private let baseURL = "http://localhost:8088"
    
    private init() {}
    
    func uploadAvatar(imageData: Data) async throws -> AvatarUploadResponse {
        guard let user = Auth.auth().currentUser else {
            throw APIError.notAuthenticated
        }
        
        let token = try await user.getIDToken()
        
        guard let url = URL(string: baseURL + "/api/v1/users/me/avatar") else {
            throw APIError.invalidURL
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(AvatarUploadResponse.self, from: data)
        } else {
            let error = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(error.message)
        }
    }
}
```

---

## Quick Reference

### Endpoints Summary

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/v1/auth/check` | Check if user exists | ✅ |
| POST | `/api/v1/auth/sync` | Create/get user profile | ✅ |
| GET | `/api/v1/auth/me` | Get current user | ✅ |
| GET | `/api/v1/users/{id}` | Get user by ID | ✅ |
| PUT | `/api/v1/users/{id}` | Update user profile | ✅ |
| POST | `/api/v1/users/me/avatar` | Upload avatar image | ✅ |
| POST | `/api/v1/levels/complete` | Submit level completion | ✅ |
| GET | `/api/v1/levels` | Get all level progress | ✅ |
| GET | `/api/v1/levels/{levelNumber}` | Get specific level | ✅ |
| GET | `/api/v1/levels/stats` | Get user statistics | ✅ |

### Public Endpoints (No Auth Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/actuator/**` | Spring Actuator |
| * | `/api/v1/public/**` | Future public endpoints |
