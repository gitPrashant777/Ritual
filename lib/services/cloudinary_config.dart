class CloudinaryConfig {
  // Your actual Cloudinary credentials
  static const String cloudName = 'dqzvr8ele';
  static const String apiKey = '563432973578174';
  static const String apiSecret = '12YXpYhh5kaySPjgHPvZcdZtFWk';
  static const String uploadPreset = 'ml_default'; // Default preset, you can create a custom one
  
  // For unsigned uploads (recommended for mobile apps)
  static const String unsignedUploadPreset = 'ml_default'; // We'll use the default for now
  
  // Base URLs
  static const String baseUrl = 'https://api.cloudinary.com/v1_1';
  static String get uploadUrl => '$baseUrl/$cloudName/image/upload';
  static String get videoUploadUrl => '$baseUrl/$cloudName/video/upload';
  
  // Image transformation presets
  static const Map<String, String> imageTransformations = {
    'thumbnail': 'w_150,h_150,c_fill,q_auto,f_auto',
    'medium': 'w_400,h_400,c_fill,q_auto,f_auto',
    'large': 'w_800,h_800,c_fill,q_auto,f_auto',
    'product_main': 'w_600,h_600,c_fill,q_auto,f_auto',
    'product_gallery': 'w_300,h_300,c_fill,q_auto,f_auto',
  };
  
  // Generate image URL with transformations
  static String getImageUrl(String publicId, {String? transformation}) {
    final baseImageUrl = 'https://res.cloudinary.com/$cloudName/image/upload';
    if (transformation != null && imageTransformations.containsKey(transformation)) {
      return '$baseImageUrl/${imageTransformations[transformation]}/$publicId';
    }
    return '$baseImageUrl/$publicId';
  }
  
  // Validate configuration
  static bool get isConfigured {
    return cloudName != 'your_cloud_name' && 
           apiKey != 'your_api_key' && 
           uploadPreset != 'your_upload_preset';
  }
  
  // Get folder path for different image types
  static String getFolderPath(String imageType) {
    switch (imageType) {
      case 'product':
        return 'ecommerce/products';
      case 'user':
        return 'ecommerce/users';
      case 'category':
        return 'ecommerce/categories';
      default:
        return 'ecommerce/general';
    }
  }
}
