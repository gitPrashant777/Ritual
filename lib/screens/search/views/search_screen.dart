import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/search_api_service.dart';

// Ensure this points to the file you uploaded previously
import 'components/search_form.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchApiService _searchService = SearchApiService();

  // State variables
  List<ProductModel> _searchResults = [];
  List<String> _recentSearches = [];
  List<String> _popularSearches = [];

  bool _isSearching = false;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Fetch History & Popular items on load
  Future<void> _loadInitialData() async {
    try {
      final history = await _searchService.getSearchHistory();
      final popular = await _searchService.getPopularSearches();

      if (mounted) {
        setState(() {
          _recentSearches = history;
          _popularSearches = popular;
        });
      }
    } catch (e) {
      print("Error loading initial search data: $e");
    }
  }

  // Perform the API search
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      // --- FIX IS HERE ---
      // The service already returns List<ProductModel>, so we assign it directly.
      // We removed the lines that tried to do result['products'].
      final results = await _searchService.searchProducts(query: query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search failed: $e")),
        );
      }
    }
  }

  // Debounce to avoid API spam
  void _onSearchChanged(String? query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (query != null) {
        _performSearch(query);
      }
    });
  }

  // Clear history via API
  Future<void> _clearAllHistory() async {
    final success = await _searchService.clearSearchHistory();
    if (success && mounted) {
      setState(() {
        _recentSearches = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),
              // Header
              Row(
                children: [
                  const BackButton(),
                  const SizedBox(width: defaultPadding / 2),
                  Expanded(
                    child: Text(
                      "Search",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding),

              // Search Input
              SearchForm(
                autofocus: true,
                onChanged: _onSearchChanged,
                onFieldSubmitted: (value) {
                  if (value != null) _performSearch(value);
                },
                onTabFilter: () {
                  // Placeholder for filter
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Filters coming soon")),
                  );
                },
              ),

              const SizedBox(height: defaultPadding),

              // Content Area
              Expanded(
                child: _isSearching ? _buildSearchResults() : _buildDefaultView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Search Results Grid
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/icons/Search.svg",
              height: 64,
              colorFilter: ColorFilter.mode(
                Theme.of(context).disabledColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: defaultPadding),
            Text(
              "No items found",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text("Try different keywords", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Found ${_searchResults.length} results",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: defaultPadding),
        Expanded(
          child: GridView.builder(
            itemCount: _searchResults.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: defaultPadding,
              mainAxisSpacing: defaultPadding,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) => ProductCard(
              image: _searchResults[index].image,
              brandName: _searchResults[index].brandName ?? "Rituals",
              title: _searchResults[index].title,
              price: _searchResults[index].price,
              priceAfetDiscount: _searchResults[index].priceAfetDiscount,
              dicountpercent: _searchResults[index].dicountpercent,
              product: _searchResults[index],
              press: () {
                Navigator.pushNamed(
                  context,
                  productDetailsScreenRoute,
                  arguments: _searchResults[index],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // 2. Default View (History & Popular)
  Widget _buildDefaultView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches Section
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Searches",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearAllHistory,
                  child: const Text("Clear All", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _recentSearches.map((search) {
                return InkWell(
                  onTap: () => _performSearch(search),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(search, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: defaultPadding * 2),
          ],

          // Popular Searches Section
          if (_popularSearches.isNotEmpty) ...[
            Text(
              "Popular Searches",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: defaultPadding),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _popularSearches.map((search) {
                return InkWell(
                  onTap: () => _performSearch(search),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 16, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(search, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}