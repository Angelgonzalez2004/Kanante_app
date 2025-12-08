import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  UserModel? _adminUser;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rfcController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
  
  void _showSnackBar(String message, {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: duration,
      ),
    );
  }

  Future<void> _loadAdminProfile() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userModel = await _firebaseService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _adminUser = userModel;
          if (_adminUser != null) {
            _nameController.text = _adminUser!.name;
            _phoneController.text = _adminUser!.phone ?? '';
            _rfcController.text = _adminUser!.rfc ?? '';
            _selectedGender = _adminUser!.gender;
            if (_adminUser!.birthDate != null && _adminUser!.birthDate!.isNotEmpty) {
              _selectedBirthDate = DateTime.parse(_adminUser!.birthDate!);
              _birthDateController.text = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
            } else {
              _birthDateController.text = '';
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al cargar perfil: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Por favor, corrija los errores.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updates = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'rfc': _rfcController.text.trim(),
        'gender': _selectedGender,
        'birthDate': _selectedBirthDate != null ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!) : null,
      };

      await _firebaseService.updateUserProfile(user.uid, updates);
      if (mounted) {
        _showSnackBar('Perfil de administrador actualizado.');
        setState(() => _isEditing = false);
      }
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Material(
      type: MaterialType.transparency,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 32),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nombre',
                              icon: Icons.person_rounded,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Teléfono',
                              icon: Icons.phone_rounded,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone
                            ),
                             const SizedBox(height: 16),
                            _buildTextField(
                              controller: _rfcController,
                              label: 'RFC',
                              icon: Icons.badge_outlined,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            _buildDatePicker(),
                            const SizedBox(height: 16),
                            _buildGenderDropdown(),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isEditing)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.save),
                                    label: const Text('Guardar'),
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                  ),
                                if (_isEditing) const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
                                  label: Text(_isEditing ? 'Cancelar' : 'Editar'),
                                  onPressed: () {
                                    setState(() => _isEditing = !_isEditing);
                                    if (!_isEditing) _loadAdminProfile();
                                  },
                                   style: ElevatedButton.styleFrom(backgroundColor: _isEditing ? Colors.red : Colors.blue, foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        fillColor: enabled ? Colors.white : Colors.grey[200],
        filled: true,
      ),
      keyboardType: keyboardType,
      validator: (val) => (val == null || val.isEmpty) && label == 'Nombre' ? 'El nombre no puede estar vacío' : null,
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _birthDateController,
      readOnly: true,
      onTap: !_isEditing ? null : () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime(2000),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != _selectedBirthDate) {
          setState(() {
            _selectedBirthDate = picked;
            _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Fecha de Nacimiento',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: const OutlineInputBorder(),
        fillColor: _isEditing ? Colors.white : Colors.grey[200],
        filled: true,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      items: const [
        DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
        DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
        DropdownMenuItem(value: 'Prefiero no decirlo', child: Text('Prefiero no decirlo')),
      ],
      onChanged: !_isEditing ? null : (value) {
        setState(() => _selectedGender = value);
      },
      decoration: InputDecoration(
        labelText: 'Género',
        prefixIcon: const Icon(Icons.transgender),
        border: const OutlineInputBorder(),
        fillColor: _isEditing ? Colors.white : Colors.grey[200],
        filled: true,
      ),
      validator: (value) => value == null ? 'Por favor selecciona una opción' : null,
    );
  }
}
