# Admin Product Creation - User Test Guide

## Complete Admin Flow Testing

### Step 1: Admin Login
1. Open the Flutter app
2. Navigate to the login screen
3. Login with admin credentials:
   - Email: `admin@example.com` (or your admin email)
   - Password: Your admin password
4. **Expected Result**: Admin login successful message and redirect to Admin Panel

### Step 2: Access Product Management
1. From Admin Panel main screen, look for "Management Tools" section
2. Click on **"Product Management"** option
   - Title: "Product Management"
   - Subtitle: "Add, edit, and manage product catalog with images"
3. **Expected Result**: Navigate to Product List Management Screen

### Step 3: Add New Product
1. On Product List Management screen, look for the "Add Product" button (usually a + icon)
2. Click **"Add Product"** button
3. **Expected Result**: Navigate to Product Management Screen with empty form

### Step 4: Fill Product Form
Fill out all the required fields:

#### Basic Information
- **Product Name**: Enter product name (e.g., "iPhone 15 Pro")
- **Description**: Enter detailed description
- **Category**: Select from dropdown (Electronics, Clothing, etc.)

#### Pricing
- **Price**: Enter original price (e.g., 999.99)
- **Sale Price**: Enter discounted price (e.g., 899.99)
- **Stock**: Enter available quantity (e.g., 50)

#### Product Status (Optional toggles)
- **On Sale**: Toggle if product is on sale
- **Popular**: Toggle if product is popular
- **Best Seller**: Toggle if it's a best seller
- **Flash Sale**: Toggle for flash sale
- **Flash Sale End**: If flash sale is enabled, pick end date

#### Images
- Add product image URLs in the images section

### Step 5: Save Product
1. Click **"Save Product"** button
2. **Expected Results**:
   - Loading indicator appears
   - Success message: "Product created successfully!"
   - Return to Product List Management Screen
   - New product appears in the list

## API Integration Details

### Backend Endpoint
- **URL**: `https://backendd-ankp.onrender.com/api/v1/admin/product`
- **Method**: POST
- **Auth**: Bearer token (automatically handled)

### Request Payload Format
```json
{
  "name": "Product Name",
  "description": "Product description",
  "category": "Electronics",
  "price": 999.99,
  "salePrice": 899.99,
  "discount": 10,
  "isOnSale": true,
  "isPopular": false,
  "isBestSeller": false,
  "isFlashSale": false,
  "flashSaleEnd": "2024-12-31T23:59:59.000Z",
  "images": ["image1.jpg", "image2.jpg"],
  "stock": 50
}
```

## Troubleshooting

### Authentication Issues
- **Problem**: "Admin authentication required" error
- **Solution**: Log out completely and log back in with admin credentials

### API Connection Issues
- **Problem**: Network errors or timeouts
- **Solution**: Check internet connection and backend server status

### Form Validation Errors
- **Problem**: Required fields not filled
- **Solution**: Ensure all required fields (name, description, category, price, stock) are filled

### Console Debugging
Check Flutter debug console for detailed logs:
- Authentication status
- Form validation details
- API request/response data
- Error messages

## Success Indicators
- ✅ Admin login redirects to Admin Panel
- ✅ Product Management navigation works
- ✅ Product form loads with all fields
- ✅ Form validation works properly
- ✅ API call succeeds (check console logs)
- ✅ Success message displays
- ✅ Product appears in backend at `/products` endpoint

## Next Steps
After successful product creation:
1. Verify product appears in main product list
2. Test product editing functionality
3. Test product deletion if needed
4. Verify product shows up for regular users in the shop

---

**Note**: This implementation includes comprehensive debugging logs. Check the Flutter console for detailed information about each step of the process.
