import 'package:flutter/material.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';

class InventoryProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  Color _getStockStatusColor() {
    if (product.isOutOfStock || product.stockQuantity <= 0) {
      return errorColor;
    } else if (product.stockQuantity <= 5) {
      return warningColor;
    } else {
      return successColor;
    }
  }

  String _getStockStatusText() {
    if (product.isOutOfStock || product.stockQuantity <= 0) {
      return "OUT OF STOCK";
    } else if (product.stockQuantity <= 5) {
      return "LOW STOCK";
    } else {
      return "IN STOCK";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Row(
            children: [
              // Product Image
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: NetworkImageWithLoader(
                    product.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(width: defaultPadding),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Brand Name
                    Text(
                      product.brandName ?? "Rituals",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stock Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStockStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStockStatusColor().withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStockStatusText(),
                        style: TextStyle(
                          color: _getStockStatusColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stock Information
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Stock Quantity
                  Text(
                    "Stock: ${product.stockQuantity}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _getStockStatusColor(),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Max Order Quantity
                  Text(
                    "Max Order: ${product.maxOrderQuantity}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(
                    "₹${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Edit Button
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
