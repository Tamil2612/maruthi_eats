import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/address_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(13.0827, 80.2707); // Default Chennai
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  
  String _selectedType = 'Home';
  bool _saving = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _selectedLocation = LatLng(widget.address!.latitude, widget.address!.longitude);
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

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
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

  void _updateLocation(LatLng location) async {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));

    try {
      // Geocoding package does NOT support Web. Skip auto-address on browsers to prevent crash.
      if (!kIsWeb) {
        List<geo.Placemark> placemarks = await geo.Geocoding()
            .placemarkFromCoordinates(location.latitude, location.longitude);
        if (!mounted || placemarks.isEmpty) return;
        final p = placemarks.first;
        final components = [
          p.name,
          p.subLocality,
          p.locality,
          p.postalCode,
        ].where((s) => s != null && s.isNotEmpty && s.toLowerCase() != "null").toList();

        final addr = components.join(", ");
        setState(() {
          _addressController.text = addr;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.address == null ? 'Add Address' : 'Edit Address')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 15),
                      onMapCreated: (c) => _mapController = c,
                      onCameraMove: (pos) => _selectedLocation = pos.target,
                      onCameraIdle: () => _updateLocation(_selectedLocation),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 30.h),
                        child: Icon(Icons.location_on, color: AppColors.maroon, size: 40.r),
                      ),
                    ),
                    Positioned(
                      bottom: 16.h,
                      right: 16.w,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: _getCurrentLocation,
                        child: _isLoadingLocation
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.maroon))
                            : const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  color: AppColors.white,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("Receiver's Details"),
                        16.verticalSpace,
                        _buildTextField(
                          controller: _nameController,
                          label: "Recipient Name",
                          icon: Icons.person_outline,
                        ),
                        16.verticalSpace,
                        _buildTextField(
                          controller: _phoneController,
                          label: "Contact Number",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        24.verticalSpace,

                        _sectionTitle("Address Details"),
                        16.verticalSpace,
                        _buildTextField(
                          controller: _addressController,
                          label: "Full Address",
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        24.verticalSpace,

                        _sectionTitle("Save As"),
                        12.verticalSpace,
                        Row(
                          children: [
                            _typeChip("Home", Icons.home_rounded),
                            12.horizontalSpace,
                            _typeChip("Work", Icons.business_rounded),
                            12.horizontalSpace,
                            _typeChip("Other", Icons.place_rounded),
                          ],
                        ),
                        if (_selectedType == 'Other') ...[
                          16.verticalSpace,
                          _buildTextField(
                            controller: _labelController,
                            label: "Address Type (e.g. Parents, Gym)",
                            icon: Icons.label_outline,
                          ),
                        ],
                        120.verticalSpace, // Spacing for bottom button
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(color: AppColors.maroon)
                      : const Text('SAVE ADDRESS'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.maroon, letterSpacing: 0.5),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.r),
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
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.maroon : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isSelected ? AppColors.maroon : AppColors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.gold : AppColors.textDark, size: 20.r),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details')));
      return;
    }

    final finalLabel = _selectedType == 'Other' ? customLabel : _selectedType;
    if (finalLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter address type')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
