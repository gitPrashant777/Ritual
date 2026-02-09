// lib/services/api_config.dart
class ApiConfig {
  // Backend base URL with /api/v1 prefix
  static const String currentBaseUrl = 'https://backendd-ankp.onrender.com/api/v1';

  // API endpoints (matching your backend structure)
  static const String productsEndpoint = '/products';
  static const String productCategoriesEndpoint = '/products/category/{category}';
  static const String productTagsEndpoint = '/products/tag/{tag}';
  static const String popularProductsEndpoint = '/products/popular';
  static const String bestSellersProductsEndpoint = '/products/best-sellers';
  static const String flashSale = '/products/flash-sale';
  static const String productId = '/products/{id}';
  static const String getAllProducts = '/admin/products';
  static const String createNewProduct = '/admin/product';
  static const String updateProduct = '/admin/product/{id}';
  static const String deleteProduct = '/admin/product/{id}';
  static const String toggleProductSaleStatus = '/admin/product/{id}/sale';
  static const String reviewsEndpoint = '/product/review';
  static const String allReviewEndpoint = '/product/{id}/reviews';
  static const String deleteReview = '/product/{productId}/{reviewId}';
  static const String registerUserEndpoint = '/register';
  static const String loginUserEndpoint = '/login';
  static const String logoutUserEndpoint = '/logout';
  static const String forgotPasswordEndpoint = '/password/forgot';
  static const String resetPasswordEndpoint = '/reset/{token}';
  static const String profileEndpoint = '/profile';//get logged-in user details
  static const String updateProfileEndpoint = '/profile/update';
  static const String updateUserPasswordEndpoint = '/password/update';
  static const String getAllAdminsEndpoint = '/admin/users';
  static const String getSingleUserEndpoint = '/admin/user/{id}';
  static const String updateUserRoleEndpoint = '/admin/user/{id}';
  static const String deleteUserEndpoint = '/admin/user/{id}';
  static const String newOrderEndpoint = '/new/order';
  static const String getOrderByIdEndpoint = '/order/{id}';
  static const String getAllOrdersOfUserEndpoint = '/orders/user';
  static const String updateOrderStatusEndpoint = '/admin/order/{id}';
  static const String deleteOrderEndpoint = '/admin/order/{id}';
  static const String getAllOrdersEndpoint = '/admin/orders';
  static const String processPaymentsEndpoint = '/payment/process';
  static const String getRazorpayKeyEndpoint = '/getKey';
  static const String verifyPaymentEndpoint = '/paymentVerification';
  static const String createNewSupportTicketEndpoint = '/support/ticket';
  static const String getSupportTicketsEndpoint = '/support/tickets';
  static const String supportTicketStatusEndpoint = '/admin/support/ticket/{id}';
  static const String faqsEndpoint = '/faqs';
  static const String notificationsEndpoint = '/notifications';
  static const String notificationReadStatusEndpoint = '/notifications/{id}/read';
  static const String notificationCreateEndpoint = '/admin/notification';
  static const String searchEndpoint = '/search';
  static const String searchDataEndpoint = '/search/data';
  static const String addressEndpoint = '/account/addresses';
  static const String newAddressEndpoint = '/account/addresses';
  static const String updateAddressEndpoint = '/account/addresses/{id}';
  static const String deleteAddressEndpoint = '/account/addresses/{id}';
  static const String updateUserPreferencesEndpoint = '/personalization/preferences';
  static const String toggleUserNotificationsEndpoint = '/personalization/notifications';
  static const String cartEndpoint = '/cart';
  static const String addProductToCartEndpoint = '/cart';

  // --- THIS IS THE FIX ---
  // The endpoints must match your API documentation from the screenshot
  static const String updateCartItemQuantityEndpoint = '/cart/{productId}';
  static const String deleteCartItemEndpoint = '/cart/{productId}';
  // --- END OF FIX ---

  static const String wishlistEndpoint = '/account/wishlist';
  static const String addProductToWishlistEndpoint = '/account/wishlist';
  static const String deleteWishlistProductEndpoint = '/account/wishlist/{productId}';
  static const String settingsEndpoint = '/settings/language';
  static const String locationEndpoint = '/settings/location';


  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token', // Standard Bearer token format
  };
}

/*
User{
_id string
readOnly: true
name  string
email string
avatar  {
public_id string
url string
}
role  string
Enum:
[ user, admin ]
walletBalance number
preferences {
< * >:  [...]
}
language  string
location  string
notificationsEnabled  boolean
createdAt string($date-time)
}
}*/

/*
UserRegistration{
name* string
example: John Doe
email* string($email)
example: john.doe@example.com
password* string
example: password123
avatar  string
example: base64encodedimage
}*/

/*
Product{
_id string
readOnly: true
name  string
description string
category  string
price number
salePrice number
discount  number
isOnSale  boolean
isPopular boolean
isBestSeller  boolean
isFlashSale boolean
flashSaleEnd  string($date-time)
images  [Image{
public_id string
url string
}]
stock integer
tags  [string]
ratings number
numOfReviews  integer
reviews [Review{
_id string
readOnly: true
user  string
name  string
rating  number
comment string
}]
user  string
variants  [Variant{
size  string
color string
colorCode string
colorImage  Image{
public_id string
url string
}
stock integer
available boolean
}]
}
*/

/*
ProductInput{
name  string
example: Wireless Headphones
description string
example: High-fidelity sound, noise-cancelling.
category  string
example: Electronics
price number
example: 199.99
images  [[...]]
stock integer
example: 150
}
*/

/*
Image{
public_id string
url string
}
*/


/*
Variant{
size  string
color string
colorCode string
colorImage  Image{
public_id string
url string
}
stock integer
available boolean
}
*/

/*
Review{
_id string
readOnly: true
user  string
name  string
rating  number
comment string
}
*/

/*
Order{
shippingInfo  {
address string
city  string
state string
country string
pinCode integer
phoneNo number
}
orderItems  [{
name  string
price number
quantity  number
image string
product string
}]
paymentInfo {
id  string
status  string
}
itemPrice number
taxPrice  number
shippingPrice number
totalPrice  number
paidAt  string($date-time)
user  string
orderStatus string
deliveredAt string($date-time)
}
*/

/*
CartItem{
productId string
quantity  integer
}
*/

/*
Address{
_id string
readOnly: true
street  string
city  string
state string
country string
postalCode  string
isDefault boolean
}
*/

/*
AddressInput{
street* string
city* string
state* string
country* string
postalCode* string
isDefault boolean
default: false
}
*/