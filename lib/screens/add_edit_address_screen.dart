import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/address_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationSuggestion {
  final String title;
  final String subtitle;
  final LatLng location;

  LocationSuggestion({
    required this.title,
    required this.subtitle,
    required this.location,
  });
}

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(13.0827, 80.2707); // Default Chennai

  final _searchController = TextEditingController();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();

  String _selectedType = 'Home';
  bool _saving = false;
  bool _isLoadingLocation = false;
  bool _isSearching = false;

  Timer? _debounceTimer;
  List<LocationSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _selectedLocation =
          LatLng(widget.address!.latitude, widget.address!.longitude);
      _addressController.text = widget.address!.fullAddress;
      _nameController.text = widget.address!.recipientName;
      _phoneController.text = widget.address!.recipientPhone;

      final label = widget.address!.label;
      if (['Home', 'Work'].contains(label)) {
        _selectedType = label;
      } else {
        _selectedType = 'Other';
        _labelController.text = label;
      }
    } else {
      _loadUserDetails();
      _getCurrentLocation();
    }
  }

  Future<void> _loadUserDetails() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.watchUser(user.uid).first;
      if (!mounted || userData == null) return;
      setState(() {
        _nameController.text = userData.name;
        _phoneController.text = userData.phone;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        final latLng = LatLng(position.latitude, position.longitude);
        _updateLocation(latLng);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final search = query.trim();

    if (search.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchLocationSuggestions(search);
    });
  }

  Future<void> _fetchLocationSuggestions(String query) async {
    if (kIsWeb || query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      List<Location> locations = await Geocoding().locationFromAddress(query);
      List<LocationSuggestion> results = [];

      for (var loc in locations.take(5)) {
        try {
          List<Placemark> placemarks = await Geocoding()
              .placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final title = [p.name, p.subLocality]
                .where((s) =>
                    s != null && s.isNotEmpty && s.toLowerCase() != "null")
                .join(", ");

            final subtitle = [p.locality, p.administrativeArea, p.country]
                .where((s) =>
                    s != null && s.isNotEmpty && s.toLowerCase() != "null")
                .join(", ");

            results.add(LocationSuggestion(
              title: title.isNotEmpty ? title : (p.locality ?? "Location"),
              subtitle: subtitle,
              location: LatLng(loc.latitude, loc.longitude),
            ));
          }
        } catch (_) {
          results.add(LocationSuggestion(
            title: query,
            subtitle:
                "${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}",
            location: LatLng(loc.latitude, loc.longitude),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _suggestions = results;
        });
      }
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
      if (mounted) {
        setState(() {
          _suggestions = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _searchController.text =
          suggestion.title.isNotEmpty ? suggestion.title : suggestion.subtitle;
    });
    _updateLocation(suggestion.location);
  }

  void _updateLocation(LatLng location) async {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));

    try {
      if (!kIsWeb) {
        List<Placemark> placemarks = await Geocoding()
            .placemarkFromCoordinates(location.latitude, location.longitude);
        if (!mounted || placemarks.isEmpty) return;
        final p = placemarks.first;
        final components = [
          p.name,
          p.subLocality,
          p.locality,
          p.postalCode,
        ]
            .where(
                (s) => s != null && s.isNotEmpty && s.toLowerCase() != "null")
            .toList();

        final addr = components.join(", ");
        if (addr.isNotEmpty) {
          setState(() {
            _addressController.text = addr;
          });
        }
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _labelController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          widget.address == null ? 'Set Delivery Location' : 'Edit Address',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.maroon,
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Top Map Section
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation,
                        zoom: 16,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      onCameraMove: (pos) => _selectedLocation = pos.target,
                      onCameraIdle: () => _updateLocation(_selectedLocation),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),

                    // Map Center Pin Indicator
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 36.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.textDark,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Order will be delivered here',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            4.verticalSpace,
                            Icon(
                              Icons.location_on_rounded,
                              color: AppColors.maroon,
                              size: 42.r,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Location Search Bar & Suggestions Overlay
                    Positioned(
                      top: 16.h,
                      left: 16.w,
                      right: 16.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.black.withValues(alpha: 0.12),
                                  blurRadius: 14.r,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded,
                                    color: AppColors.maroon, size: 22.r),
                                10.horizontalSpace,
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (val) =>
                                        _fetchLocationSuggestions(val),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search city, area or landmark...',
                                      hintStyle: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.grey,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 12.h),
                                    ),
                                  ),
                                ),
                                if (_isSearching)
                                  SizedBox(
                                    width: 18.w,
                                    height: 18.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.maroon,
                                    ),
                                  )
                                else if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        size: 18.r, color: AppColors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _suggestions = [];
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),

                          // Search Suggestions Dropdown List
                          if (_suggestions.isNotEmpty) ...[
                            6.verticalSpace,
                            Container(
                              constraints: BoxConstraints(maxHeight: 220.h),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.black.withValues(alpha: 0.15),
                                    blurRadius: 16.r,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: AppColors.textDark
                                      .withValues(alpha: 0.06),
                                ),
                                itemBuilder: (context, index) {
                                  final item = _suggestions[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 2.h),
                                    leading: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.maroon
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.location_on_outlined,
                                          color: AppColors.maroon, size: 18.r),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: item.subtitle.isNotEmpty
                                        ? Text(
                                            item.subtitle,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: AppColors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : null,
                                    onTap: () => _selectSuggestion(item),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Floating GPS "Locate Me" Button
                    Positioned(
                      bottom: 24.h,
                      right: 16.w,
                      child: FloatingActionButton.extended(
                        elevation: 4,
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.maroon,
                        onPressed: _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.maroon,
                                ),
                              )
                            : Icon(Icons.my_location_rounded,
                                size: 18.r, color: AppColors.maroon),
                        label: Text(
                          'Locate Me',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroon,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Address Form Section
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24.r)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.08),
                        blurRadius: 16.r,
                        offset: const Offset(0, -6),
                      )
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                            "Receiver's Contact", Icons.person_outline_rounded),
                        12.verticalSpace,
                        _buildTextField(
                          controller: _nameController,
                          label: "Recipient Name",
                          icon: Icons.person,
                        ),
                        12.verticalSpace,
                        _buildTextField(
                          controller: _phoneController,
                          label: "Contact Number",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        20.verticalSpace,

                        _sectionTitle(
                            "Address Details", Icons.location_on_outlined),
                        12.verticalSpace,
                        _buildTextField(
                          controller: _addressController,
                          label: "House / Flat No., Building & Street Address",
                          icon: Icons.location_city_rounded,
                          maxLines: 2,
                        ),
                        20.verticalSpace,

                        _sectionTitle("Save Address As", Icons.label_outlined),
                        12.verticalSpace,
                        Row(
                          children: [
                            _typeChip("Home", Icons.home_rounded),
                            10.horizontalSpace,
                            _typeChip("Work", Icons.business_rounded),
                            10.horizontalSpace,
                            _typeChip("Other", Icons.place_rounded),
                          ],
                        ),
                        if (_selectedType == 'Other') ...[
                          12.verticalSpace,
                          _buildTextField(
                            controller: _labelController,
                            label:
                                "Address Label (e.g. Parents, Friend's House)",
                            icon: Icons.edit_note_rounded,
                          ),
                        ],
                        90.verticalSpace, // Bottom padding for sticky button
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    blurRadius: 12.r,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.maroon,
                      foregroundColor: AppColors.gold,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: _saving
                        ? SizedBox(
                            width: 22.w,
                            height: 22.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.gold,
                            ),
                          )
                        : Text(
                            'SAVE ADDRESS',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18.r, color: AppColors.maroon),
        8.horizontalSpace,
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13.sp, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.r, color: AppColors.maroon),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _typeChip(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.maroon : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.maroon
                  : AppColors.grey.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.gold
                    : AppColors.textDark.withValues(alpha: 0.6),
                size: 20.r,
              ),
              4.verticalSpace,
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textDark,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final fullAddr = _addressController.text.trim();
    final customLabel = _labelController.text.trim();

    if (name.isEmpty || phone.isEmpty || fullAddr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all contact and address details')),
      );
      return;
    }

    final finalLabel = _selectedType == 'Other' ? customLabel : _selectedType;
    if (finalLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address label')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _authService.saveAddress(
        uid: _authService.currentUser!.uid,
        addressId: widget.address?.id,
        label: finalLabel,
        fullAddress: fullAddr,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        recipientName: name,
        recipientPhone: phone,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
