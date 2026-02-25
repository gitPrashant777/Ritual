import 'package:flutter/material.dart';
import 'package:shop/constants.dart'; // Ensure you have this or replace defaultPadding
import 'package:shop/services/address_api_service.dart';

import '../../../models/AddressModel.dart';
import '../add_edit_address_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final AddressApiService _apiService = AddressApiService();
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    final addresses = await _apiService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    }
  }




  Future<void> _deleteAddress(String id) async {
    // Optimistic UI update could be done here, but let's stick to safe loading
    final success = await _apiService.deleteAddress(id);
    if (success) {
      _fetchAddresses(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete address')),
        );
      }
    }
  }

  void _navigateToAddEdit(BuildContext context, [AddressModel? address]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(address: address),
      ),
    );

    // If result is true, it means we saved/updated, so refresh list
    if (result == true) {
      _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEdit(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Addresses',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add delivery addresses here',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0b3323).withOpacity(0.1),
                child: const Icon(Icons.location_on, color: Color(0xFF0b3323)),
              ),
              title: Row(
                children: [
                  Text(
                    "${address.city}, ${address.country}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (address.isDefault)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "DEFAULT",
                        style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "${address.street}\n${address.state}, ${address.postalCode}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToAddEdit(context, address);
                  } else if (value == 'delete') {
                    if (address.id != null) _deleteAddress(address.id!);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("Edit")],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}