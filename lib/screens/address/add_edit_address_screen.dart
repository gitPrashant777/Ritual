import 'package:flutter/material.dart';
import 'package:shop/constants.dart'; // Ensure defaultPadding is defined here or replace with 16.0
import 'package:shop/services/address_api_service.dart';

import '../../models/AddressModel.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address; // If null, it's Add mode. If provided, it's Edit mode.

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = AddressApiService();

  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _zipController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(text: widget.address?.street ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController = TextEditingController(text: widget.address?.state ?? '');
    _countryController = TextEditingController(text: widget.address?.country ?? '');
    _zipController = TextEditingController(text: widget.address?.postalCode ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newAddress = AddressModel(
      id: widget.address?.id,
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
      postalCode: _zipController.text.trim(),
      isDefault: _isDefault,
    );

    bool success;
    if (widget.address == null) {
      success = await _apiService.addAddress(newAddress);
    } else {
      success = await _apiService.updateAddress(widget.address!.id!, newAddress);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true); // Return true to refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? "Add New Address" : "Edit Address"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Or defaultPadding
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: "Street Address", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: "City", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: "State", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: "Country", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(labelText: "Postal Code", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Set as default address"),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0b3323), // Primary Color
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.address == null ? "Save Address" : "Update Address"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}