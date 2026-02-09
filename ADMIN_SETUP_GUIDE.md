# Rituals Admin Setup Guide

## Admin Credentials

**Admin Email:** `Ritualsadmin@gmail.com`
**Default Password:** `admin123@`

## Admin Access Rules

### Who Can Access Admin Panel
- **ONLY** `Ritualsadmin@gmail.com` can access admin features
- No other email addresses have admin privileges
- The system automatically checks email address and sets admin status

### Login Behavior

#### For Admin (Ritualsadmin@gmail.com):
1. **Login Screen**: Shows "Login as Admin" button
2. **After Login**: Navigates directly to Admin Panel
3. **Auto-Login**: After app restart, goes directly to Admin Panel if logged in

#### For Regular Users:
1. **Login Screen**: Shows "Log in" button  
2. **After Login**: Navigates to Home Screen
3. **Auto-Login**: After app restart, goes to Home Screen if logged in

### Admin Account Creation

The system automatically handles admin account creation:

1. **First Time**: If admin account doesn't exist in backend, it will be created automatically
2. **Default Setup**: Uses `Ritualsadmin@gmail.com` with password `admin123@`
3. **Password Change**: Admin can change password anytime through admin panel

### Technical Implementation

- **Email Check**: `UserSession.isAdminEmail()` validates admin email
- **Session Storage**: Admin status persists across app restarts
- **Auto-Discovery**: System creates admin account if it doesn't exist in backend
- **Secure**: Only the specific email gets admin privileges

### Testing Admin Login

1. Open the app
2. Enter email: `Ritualsadmin@gmail.com`
3. Enter password: `admin123@`
4. Tap "Login as Admin"
5. Should navigate to Admin Panel

### Regular User Testing

1. Use any other email (like `rishiarora2705@gmail.com`)
2. Should navigate to Home Screen (not Admin Panel)
3. No admin features accessible

## Security Notes

- Admin privileges are hardcoded to specific email only
- Backend authentication still required
- Session management ensures proper access control
- Auto-login respects admin/user distinction

## Backend Integration

The system works with your MERN backend at `https://mern-backend-t3h8.onrender.com`:
- Creates admin account if needed
- Handles authentication tokens
- Manages user sessions properly
