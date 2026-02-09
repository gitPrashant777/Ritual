# User Existence Check & Auto-Registration Navigation

## Feature Overview

When a user tries to login with an email that doesn't exist in the system, the app will:

1. **Check User Existence**: Verify if the email is registered in the backend
2. **Show Friendly Message**: Display "Account not found. Redirecting to registration..."
3. **Auto-Navigate**: Automatically redirect to registration page after 2 seconds
4. **Welcome Message**: Show welcome message on registration page

## Implementation Details

### 1. User Existence Check Service

**Location**: `lib/services/auth_api_service.dart`

**Method**: `checkUserExists(String email)`

**How it works**:
- Tries multiple backend endpoints to check user existence
- Falls back to dummy login attempt if no dedicated endpoint exists
- Returns `true` if user exists, `false` if not found

**Endpoints Tested**:
- `/auth/check-user`
- `/auth/user-exists`
- `/users/exists`
- `/check-email`
- `/users/check`

### 2. Enhanced Login Flow

**Location**: `lib/screens/auth/views/login_screen.dart`

**Process**:
1. User enters email and password
2. **Admin Check**: If email is `Ritualsadmin@gmail.com`, use admin login
3. **User Existence Check**: For regular users, check if email exists first
4. **Auto-Redirect**: If user doesn't exist, show message and navigate to signup
5. **Normal Login**: If user exists, proceed with regular login

### 3. Error Handling

**Multiple Detection Points**:
- Pre-login user existence check
- Login response error messages
- Exception handling during login

**Error Messages Detected**:
- "user not found"
- "user does not exist"
- "account not found"
- "email not found"
- "no user found"
- "user doesn't exist"

### 4. User Experience Flow

#### Scenario 1: Existing User
```
User enters credentials → Login attempt → Success → Navigate to Home/Admin
```

#### Scenario 2: Non-existent User
```
User enters credentials → User existence check → Not found → 
Orange message "Account not found. Redirecting..." → 
Wait 2 seconds → Navigate to Registration → 
Blue welcome message "Welcome! Please create your account..."
```

#### Scenario 3: Wrong Password (Existing User)
```
User enters credentials → Login attempt → Invalid password error → 
Red error message → Stay on login screen
```

## Visual Indicators

### 1. Account Not Found Message
- **Color**: Orange background
- **Icon**: Info outline icon
- **Duration**: 3 seconds
- **Content**: "Account not found. Redirecting to registration..."

### 2. Welcome Message (Registration)
- **Color**: Blue background  
- **Icon**: Info outline icon
- **Duration**: 3 seconds
- **Content**: "Welcome! Please create your account to continue."

### 3. Error Messages
- **Color**: Red background
- **Content**: Specific error based on issue

## Backend Compatibility

The system works with various backend response formats:

### User Not Found Responses:
- Standard error messages
- HTTP status codes
- JSON error objects
- Custom error formats

### Fallback Method:
If no dedicated user-check endpoint exists:
- Attempts login with dummy password
- Analyzes error response to determine if user exists
- Distinguishes between "user not found" vs "wrong password"

## Testing Scenarios

### Test Case 1: New User Registration Flow
1. Enter non-existent email in login
2. Verify orange message appears
3. Verify auto-navigation to signup after 2 seconds
4. Verify welcome message on signup screen

### Test Case 2: Existing User Login
1. Enter existing user credentials
2. Verify normal login flow
3. Verify navigation to appropriate home screen

### Test Case 3: Wrong Password
1. Enter existing email with wrong password
2. Verify red error message
3. Verify stays on login screen

### Test Case 4: Admin Login
1. Enter `Ritualsadmin@gmail.com`
2. Verify admin login flow
3. Verify navigation to admin panel

## Configuration

### Admin Email
- **Email**: `Ritualsadmin@gmail.com`
- **Behavior**: Bypasses user existence check
- **Navigation**: Direct to admin panel

### Timing
- **Message Display**: 3 seconds
- **Auto-Navigation Delay**: 2 seconds
- **Total User Wait Time**: 2 seconds before redirect

### Customization Points
- Error message text
- Timing delays
- Color schemes
- Navigation routes
- Backend endpoint URLs

## Benefits

1. **Better UX**: Clear guidance for new users
2. **Reduced Confusion**: Automatic redirection eliminates guesswork
3. **Faster Registration**: Direct path from login attempt to registration
4. **Error Prevention**: Prevents repeated failed login attempts
5. **Backend Agnostic**: Works with various backend implementations
