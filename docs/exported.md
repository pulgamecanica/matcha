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
- `404`: User blocked you
- `404`: User is blocked

---
## DELETE /me
**Description**: Delete the current authenticated user account and all related data

**Responses:**
- `204`: User deleted
- `401`: Unauthorized - missing or invalid token

---
## GET /me/pictures
**Description**: List all pictures uploaded by the current user

**Responses:**
- `200`: Returns list of pictures

---
## POST /me/pictures
**Description**: Upload a new picture
**Params:**
- `url` (String, required) - URL of the picture
- `is_profile` (TrueClass) - Set as profile picture

**Responses:**
- `201`: Picture created
- `422`: Invalid data

---
## PATCH /me/pictures/:id
**Description**: Edit a picture (e.g., set as profile)
**Params:**
- `id` (Integer, required) - 
- `is_profile` (TrueClass) - 
- `url` (String) - 

**Responses:**
- `200`: Picture updated
- `404`: Picture not found
- `403`: Not your picture

---
## DELETE /me/pictures/:id
**Description**: Delete a picture
**Params:**
- `id` (Integer, required) - 

**Responses:**
- `200`: Picture deleted
- `404`: Not found
- `403`: Unauthorized

---
## GET /tags
**Description**: List all tags

**Responses:**
- `200`: Returns a list of available tags

---
## POST /tags
**Description**: Create a new tag
**Params:**
- `name` (String, required) - The name of the tag

**Responses:**
- `201`: Tag created
- `422`: Missing or invalid name
- `422`: Tag name already taken

---
## GET /me/tags
**Description**: List all tags for the current user

**Responses:**
- `200`: Returns user’s tags
- `401`: Unauthorized

---
## POST /me/tags
**Description**: Add a tag to the current user
**Params:**
- `name` (String, required) - The name of the tag to add, if tag doesn't exist it's created

**Responses:**
- `200`: Tag added to user
- `422`: Tag name missing or invalid

---
## DELETE /me/tags
**Description**: Remove a tag from the current user
**Params:**
- `name` (String, required) - The name of the tag to remove

**Responses:**
- `200`: Tag removed
- `422`: Missing or invalid tag

---
## GET /me/visits
**Description**: See who has viewed your profile

**Responses:**
- `200`: List of users who viewed you

---
## GET /me/viewed_by
**Description**: See which users you have viewed

**Responses:**
- `200`: List of profiles you viewed

---
## POST /auth/register
**Description**: Register a new user
**Params:**
- `username` (String, required) - Unique username (max 20 characters)
- `email` (String, required) - User email address used for login and verification
- `password` (String, required) - User password (will be securely hashed)
- `first_name` (String, required) - User's first name
- `last_name` (String, required) - User's last name

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
## GET /me/location
**Description**: Returns the last known latitude and longitude of the current user

**Responses:**
- `200`: Returns current location of the user

---
## POST /me/location
**Description**: Record the current user's location (estimated from IP)

**Responses:**
- `200`: Location saved
- `401`: Unauthorized
- `422`: Geolocation service failed

---
## GET /me/location/history
**Description**: Get your full location history

**Responses:**
- `200`: List of location records
- `401`: Unauthorized

---
## POST /me/like
**Description**: Like another user
**Params:**
- `username` (String, required) - The username of the user to like

**Responses:**
- `200`: User liked
- `404`: User not found or unavailable
- `422`: Invalid request

---
## DELETE /me/like
**Description**: Unlike a user
**Params:**
- `username` (String, required) - The username of the user to unlike

**Responses:**
- `200`: User unliked
- `404`: User not found
- `422`: Like does not exist

---
## GET /me/likes
**Description**: Get list of users you have liked

**Responses:**
- `200`: Array of liked user objects

---
## GET /me/liked_by
**Description**: Get list of users you have liked

**Responses:**
- `200`: Array of liked user objects

---
## GET /me/matches
**Description**: Get list of users who liked you back (matches)

**Responses:**
- `200`: Array of matched user objects

---
## GET /me/connections
**Description**: Get all users you are connected with

**Responses:**
- `200`: List of connected users

---
## POST /me/connect
**Description**: Create a connection with a matched user
**Params:**
- `username` (String, required) - The username of the user to connect with

**Responses:**
- `200`: Connection created
- `404`: User not found
- `403`: User is not matched with you
- `422`: Invalid request

---
## DELETE /me/connect
**Description**: Remove an existing connection
**Params:**
- `username` (String, required) - The username of the user to disconnect from

**Responses:**
- `200`: Connection removed
- `403`: You and username are not connected
- `404`: User not found

---
## POST /me/block
**Description**: Block a user by username
**Params:**
- `username` (String, required) - The username of the user to block

**Responses:**
- `200`: User blocked
- `401`: Unauthorized
- `404`: User not found
- `422`: Cannot block yourself

---
## DELETE /me/block
**Description**: Unblock a user by username
**Params:**
- `username` (String, required) - The username of the user to unblock

**Responses:**
- `200`: User unblocked
- `404`: User not found

---
## GET /me/blocked
**Description**: List users you've blocked

**Responses:**
- `200`: Returns a list of blocked users

---
## GET /me/blocked_by
**Description**: List users who have blocked you

**Responses:**
- `200`: Returns a list of users who blocked you

---
