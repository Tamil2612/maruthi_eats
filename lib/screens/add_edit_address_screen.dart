import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/address_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(13.0827, 80.2707); // Default to Chennai
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _authService = AuthService();
  bool _saving = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _selectedLocation = LatLng(widget.address!.latitude, widget.address!.longitude);
      _labelController.text = widget.address!.label;
      _addressController.text = widget.address!.fullAddress;
    } else {
      _getCurrentLocation();
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
    setState(() {
      _selectedLocation = location;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));
    
    // Reverse geocoding to get address string
    try {
      List<geo.Placemark> placemarks = await geo.Geocoding().placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addr = "${p.name}, ${p.subLocality}, ${p.locality}, ${p.postalCode}";
        setState(() {
          _addressController.text = addr;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.address == null ? 'Add Address' : 'Edit Address')),
      body: Column(
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
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: Icon(Icons.location_on, color: AppColors.maroon, size: 40),
                  ),
                ),
                Positioned(
                  bottom: 16.h,
                  right: 16.w,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _getCurrentLocation,
                    child: _isLoadingLocation 
                      ? SizedBox(width: 20.w, height: 20.h, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.maroon))
                      : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20.r, offset: Offset(0, -10.h)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Address Details", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.maroon)),
                    16.verticalSpace,
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        hintText: 'Address Label (e.g. Home, Work)',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    12.verticalSpace,
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Full Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    24.verticalSpace,
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const CircularProgressIndicator(color: AppColors.maroon)
                            : const Text('Save Address'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    final fullAddr = _addressController.text.trim();

    if (label.isEmpty || fullAddr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _authService.saveAddress(
        uid: _authService.currentUser!.uid,
        addressId: widget.address?.id,
        label: label,
        fullAddress: fullAddr,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
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
