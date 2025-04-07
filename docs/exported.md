## GET /me
**Description**: Get the currently authenticated user

**Responses:**
- `200`: User object
- `401`: Missing or invalid token
- `403`: User not confirmed or banned

---
## PATCH /me
**Description**: Update profile fields for the current authenticated user
**Params:**
- `username` (String) - New username (must be unique)
- `first_name` (String) - 
- `last_name` (String) - 
- `gender` (String) - One of: male, female, other
- `sexual_preferences` (String) - One of: male, female, non_binary, everyone
- `biography` (String) - 
- `latitude` (Float) - 
- `longitude` (Float) - 

**Responses:**
- `200`: Profile updated & user object
- `401`: Unauthorized
- `422`: Validation failed

---
## GET /users/:username
**Description**: Fetch the public profile of a user by their username
**Params:**
- `username` (String, required) - The unique username of the user

**Responses:**
- `200`: Public user data
- `404`: User not found or banned

---
## POST /auth/register
**Description**: Register a new user
**Params:**
- `username` (String, required) - Unique username (max 20 characters)
- `email` (String, required) - User email address used for login and verification
- `password` (String, required) - User password (will be securely hashed)
- `first_name` (String, required) - User's first name
- `last_name` (String, required) - User's last name
- `gender` (String, required) - User's gender: one of 'male', 'female', 'other'
- `sexual_preferences` (String, required) - Who the user is interested in: one of 'male', 'female', 'both'

**Responses:**
- `201`: User created
- `422`: Validation error (missing fields, invalid values, or already taken)

---
## POST /auth/login
**Description**: Authenticate an existing user using username and password
**Params:**
- `username` (String, required) - User's unique username
- `password` (String, required) - User's account password

**Responses:**
- `200`: Login successful, session token returned
- `401`: Invalid credentials
- `403`: Email not confirmed or user is banned

---
## POST /auth/social
**Description**: Authenticate or register a user via social login (OAuth provider)
**Params:**
- `provider` (String, required) - OAuth provider (e.g., 'google', 'github', 'intra')
- `provider_user_id` (String, required) - Unique ID returned by the provider for this user
- `first_name` (String) - User's first name (optional if new user)
- `last_name` (String) - User's last name (optional if new user)

**Responses:**
- `200`: User authenticated successfully
- `201`: User created via social login
- `422`: Missing required social login fields

---
## POST /auth/confirm
**Description**: Confirm a user manually (simulated email confirmation)
**Params:**
- `username` (String, required) - Username of the user to confirm

**Responses:**
- `200`: User confirmed
- `404`: User not found

---
