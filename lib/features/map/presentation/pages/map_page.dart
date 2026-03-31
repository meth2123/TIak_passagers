import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/services/location_service.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  MapboxMap? _mapboxMap;
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  bool _isLoadingLocation = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoadingLocation = true);

    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();

    if (position != null && mounted) {
      setState(() {
        _currentLocation = position;
        _pickupLocation = position;
        _isLoadingLocation = false;
      });

      // Center map on current location
      _mapboxMap?.setCamera(CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: 15.0,
      ));

      // Add current location marker
      _addMarker(position, 'current_location');
    } else {
      setState(() => _isLoadingLocation = false);
      // Default to Dakar center
      _centerOnDakar();
    }
  }

  void _centerOnDakar() {
    const dakarCenter = LatLng(14.6937, -17.4441);
    _mapboxMap?.setCamera(CameraOptions(
      center: Point(coordinates: Position(dakarCenter.longitude, dakarCenter.latitude)),
      zoom: 12.0,
    ));
  }

  void _addMarker(LatLng position, String markerId) {
    _mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
      manager.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(position.longitude, position.latitude)),
        iconImage: markerId == 'current_location' ? 'marker-current' : 'marker-destination',
      ));
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Set map style
    mapboxMap.loadStyleURI(AppConstants.mapboxStyleUrl);

    // Initialize location if not already done
    if (_currentLocation == null) {
      _initializeLocation();
    }
  }

  void _onMapTap(MapContentGestureContext context) {
    final screenCoordinate = context.point;
    final latLng = screenCoordinate.coordinates;

    setState(() {
      if (_pickupLocation == null) {
        _pickupLocation = LatLng(latLng.lat.toDouble(), latLng.lng.toDouble());
        _addMarker(_pickupLocation!, 'pickup');
      } else if (_dropoffLocation == null) {
        _dropoffLocation = LatLng(latLng.lat.toDouble(), latLng.lng.toDouble());
        _addMarker(_dropoffLocation!, 'dropoff');
      }
    });
  }

  void _clearMarkers() {
    setState(() {
      _pickupLocation = null;
      _dropoffLocation = null;
    });
    // TODO: Clear map annotations
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapWidget(
            key: const ValueKey('mapWidget'),
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
            cameraOptions: CameraOptions(
              center: _currentLocation != null
                  ? Point(coordinates: Position(_currentLocation!.longitude, _currentLocation!.latitude))
                  : Point(coordinates: Position(-17.4441, 14.6937)), // Dakar center
              zoom: 12.0,
            ),
          ),

          // Loading overlay
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),

          // Top search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),

          // Current location button
          Positioned(
            bottom: 200,
            right: 16,
            child: _buildCurrentLocationButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppStrings.whereTo,
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: _pickupLocation != null
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textHint),
                  onPressed: _clearMarkers,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onTap: () {
          // TODO: Navigate to search screen
        },
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_pickupLocation == null) {
      return _buildPickupPanel();
    } else if (_dropoffLocation == null) {
      return _buildDropoffPanel();
    } else {
      return _buildTripRequestPanel();
    }
  }

  Widget _buildPickupPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Où allez-vous ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Touchez la carte pour définir votre destination',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À partir de',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        '500 FCFA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropoffPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Départ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 5),
            width: 2,
            height: 20,
            color: AppColors.border,
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Destination',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to trip request
              },
              child: const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripRequestPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route info
          Row(
            children: [
              const Icon(Icons.directions, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '8.2 km · ~22 min',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '1 750 FCFA',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Prix basé sur le trajet réel parcouru',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to payment selection
              },
              child: const Text('RÉSERVER'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return FloatingActionButton(
      onPressed: _initializeLocation,
      backgroundColor: Colors.white,
      child: const Icon(
        Icons.my_location,
        color: AppColors.primary,
      ),
    );
  }
}
