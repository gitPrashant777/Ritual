import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';

class StockUpdateDialog extends StatefulWidget {
  final ProductModel product;
  final Function(ProductModel, int, int, bool) onUpdate;

  const StockUpdateDialog({
    super.key,
    required this.product,
    required this.onUpdate,
  });

  @override
  State<StockUpdateDialog> createState() => _StockUpdateDialogState();
}

class _StockUpdateDialogState extends State<StockUpdateDialog> {
  late TextEditingController stockController;
  late TextEditingController maxOrderController;
  late bool isOutOfStock;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    maxOrderController = TextEditingController(text: widget.product.maxOrderQuantity.toString());
    isOutOfStock = widget.product.isOutOfStock;
    
    // Add listeners for real-time validation
    stockController.addListener(_validateInputs);
    maxOrderController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    stockController.dispose();
    maxOrderController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    setState(() {
      hasError = false;
      errorMessage = '';

      int? stockQuantity = int.tryParse(stockController.text);
      int? maxOrderQuantity = int.tryParse(maxOrderController.text);

      // Validate stock quantity
      if (stockQuantity == null || stockQuantity < 0) {
        hasError = true;
        errorMessage = 'Stock quantity must be a valid number (0 or greater)';
        return;
      }

      // Validate max order quantity
      if (maxOrderQuantity == null || maxOrderQuantity <= 0) {
        hasError = true;
        errorMessage = 'Max order quantity must be greater than 0';
        return;
      }

      // Max order quantity should not exceed 5
      if (maxOrderQuantity > 5) {
        hasError = true;
        errorMessage = 'Max order quantity cannot exceed 5';
        return;
      }

      // Max order quantity should not exceed available stock
      if (maxOrderQuantity > stockQuantity && stockQuantity > 0) {
        hasError = true;
        errorMessage = 'Max order quantity cannot exceed available stock (${stockQuantity})';
        return;
      }
    });
  }

  void _updateStock() {
    _validateInputs();
    
    if (hasError) {
      return;
    }

    int stockQuantity = int.parse(stockController.text);
    int maxOrderQuantity = int.parse(maxOrderController.text);
    
    // Auto-set out of stock if quantity is 0
    bool finalOutOfStock = isOutOfStock || stockQuantity == 0;

    widget.onUpdate(
      widget.product,
      stockQuantity,
      maxOrderQuantity,
      finalOutOfStock,
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} updated successfully!'),
        backgroundColor: successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Update Stock',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Text(
              widget.product.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              widget.product.brandName ?? "Rituals",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: defaultPadding),
            
            // Stock Quantity Input
            Text(
              'Stock Quantity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: stockController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                hintText: 'Enter stock quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            
            const SizedBox(height: defaultPadding),
            
            // Max Order Quantity Input
            Text(
              'Max Order Quantity (Per Customer)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Maximum 5 items per order. Cannot exceed available stock.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: maxOrderController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1), // Limit to single digit
              ],
              decoration: InputDecoration(
                hintText: 'Enter max order quantity (1-5)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            
            const SizedBox(height: defaultPadding),
            
            // Out of Stock Toggle
            Row(
              children: [
                Checkbox(
                  value: isOutOfStock,
                  onChanged: (value) {
                    setState(() {
                      isOutOfStock = value ?? false;
                    });
                  },
                  activeColor: primaryColor,
                ),
                const Text('Mark as Out of Stock'),
              ],
            ),
            
            // Error Message
            if (hasError) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Info Box
            const SizedBox(height: defaultPadding),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Smart Stock Control',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Maximum 5 items per customer order\n'
                    '• Max order cannot exceed available stock\n'
                    '• Automatic out-of-stock when quantity is 0\n'
                    '• Prevents overselling and inventory issues',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: hasError ? null : _updateStock,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update Stock'),
        ),
      ],
    );
  }
}
