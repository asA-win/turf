import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class AddTurfScreen extends ConsumerStatefulWidget {
  final Turf? turf;
  const AddTurfScreen({super.key, this.turf});

  @override
  ConsumerState<AddTurfScreen> createState() => _AddTurfScreenState();
}

class _AddTurfScreenState extends ConsumerState<AddTurfScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _descriptionController;
  late TextEditingController _pitchInfoController;
  late TextEditingController _equipmentController;
  late TextEditingController _turfTypeController;
  
  List<String> _selectedSports = [];
  List<String> _selectedAmenities = [];
  
  final List<String> _availableSports = ['Football', 'Cricket', 'Badminton', 'Tennis', 'Basketball', 'Volleyball', 'Table Tennis'];
  final List<String> _availableAmenities = ['Parking', 'UPI', 'Water', 'Washroom', 'CCTV', 'Changing Room', 'Locker', 'First Aid'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.turf?.name);
    _locationController = TextEditingController(text: widget.turf?.location);
    _priceController = TextEditingController(text: widget.turf?.pricePerHour.toString());
    _imageUrlController = TextEditingController(text: widget.turf?.imageUrl);
    _latController = TextEditingController(text: widget.turf?.latitude?.toString());
    _lngController = TextEditingController(text: widget.turf?.longitude?.toString());
    _descriptionController = TextEditingController(text: widget.turf?.description);
    
    _selectedSports = widget.turf?.sportTypes?.split(',').map((e) => e.trim()).toList() ?? ['Football', 'Cricket'];
    _selectedAmenities = widget.turf?.amenities?.split(',').map((e) => e.trim()).toList() ?? ['Parking', 'UPI', 'Water'];
    
    _pitchInfoController = TextEditingController(text: widget.turf?.pitchInfo ?? '1 Nets');
    _equipmentController = TextEditingController(text: widget.turf?.equipmentProvided);
    _turfTypeController = TextEditingController(text: widget.turf?.turfType ?? 'Artificial');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _descriptionController.dispose();
    _pitchInfoController.dispose();
    _equipmentController.dispose();
    _turfTypeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioClientProvider);
      final data = {
        'name': _nameController.text,
        'location': _locationController.text,
        'price_per_hour': double.parse(_priceController.text),
        'image_url': _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
        'latitude': _latController.text.isNotEmpty ? double.parse(_latController.text) : null,
        'longitude': _lngController.text.isNotEmpty ? double.parse(_lngController.text) : null,
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        'sport_types': _selectedSports.join(','),
        'amenities': _selectedAmenities.join(','),
        'pitch_info': _pitchInfoController.text,
        'equipment_provided': _equipmentController.text.isNotEmpty ? _equipmentController.text : null,
        'turf_type': _turfTypeController.text,
      };

      if (widget.turf != null) {
        await dio.put('/turfs/${widget.turf!.id}', data: data);
      } else {
        await dio.post('/turfs/', data: data);
      }

      // Refresh turfs list
      ref.invalidate(fetchTurfsProvider(null, null));
      ref.invalidate(fetchMyTurfsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.turf != null ? 'Turf updated successfully!' : 'Turf added successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.turf != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Turf' : 'Add New Turf', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Basic Information', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Turf Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location/Address'),
                validator: (value) => value!.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              Text('Sports & Amenities', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Available Sports', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableSports.map((sport) {
                  final isSelected = _selectedSports.contains(sport);
                  return FilterChip(
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSports.add(sport);
                        } else {
                          _selectedSports.remove(sport);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryGreen,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Amenities', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryGreen,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text('Venue Info', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pitchInfoController,
                decoration: const InputDecoration(labelText: 'Pitch Info', hintText: '1 Nets, 7x7 Field'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _turfTypeController,
                decoration: const InputDecoration(labelText: 'Turf Type', hintText: 'Artificial, Natural'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _equipmentController,
                decoration: const InputDecoration(labelText: 'Equipment Provided', hintText: 'Balls, Bat, etc. (Optional)'),
              ),
              const SizedBox(height: 32),
              Text('Pricing & Images', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price Per Hour (Rs.)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(isEditing ? 'UPDATE TURF' : 'SAVE TURF'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
