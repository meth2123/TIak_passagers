import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';

typedef OnLocationSelected = void Function(LatLng location, String address);

class DestinationBottomSheet extends StatefulWidget {
  final OnLocationSelected onLocationSelected;

  const DestinationBottomSheet({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<DestinationBottomSheet> createState() =>
      _DestinationBottomSheetState();
}

class _DestinationBottomSheetState extends State<DestinationBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [
    {
      'name': 'Almadies',
      'address': 'Quartier, Dakar',
      'lat': 14.7416,
      'lng': -17.5104
    },
    {
      'name': 'Médina',
      'address': 'Quartier, Dakar',
      'lat': 14.6963,
      'lng': -17.0476
    },
    {
      'name': 'Plateau',
      'address': 'Quartier, Dakar',
      'lat': 14.6928,
      'lng': -17.0369
    },
    {
      'name': 'Yoff',
      'address': 'Quartier, Dakar',
      'lat': 14.7493,
      'lng': -17.1403
    },
    {
      'name': 'Pikine',
      'address': 'Banlieue, Région de Dakar',
      'lat': 14.7667,
      'lng': -17.1437
    },
  ];

  List<Map<String, dynamic>> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = _suggestions;
    _searchController.addListener(_filterSuggestions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSuggestions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSuggestions = _suggestions
          .where((suggestion) =>
              suggestion['name']
                  .toString()
                  .toLowerCase()
                  .contains(query) ||
              suggestion['address']
                  .toString()
                  .toLowerCase()
                  .contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Où allez-vous ?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          leading: CloseButton(
            color: AppColors.primary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Entrez destination...',
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
            ),

            // Suggestions List
            Expanded(
              child: _filteredSuggestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun résultat trouvé',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _filteredSuggestions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            suggestion['name'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            suggestion['address'],
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          onTap: () {
                            widget.onLocationSelected(
                              LatLng(
                                suggestion['lat'] as double,
                                suggestion['lng'] as double,
                              ),
                              suggestion['name'],
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

