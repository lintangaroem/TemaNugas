// lib/screens/home/dialogs/create_project_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:TemaNugas/constants/constant.dart';
import 'package:TemaNugas/services/api/api_services.dart';

class CreateProjectDialog extends StatefulWidget {
  final ApiService apiService;

  const CreateProjectDialog({super.key, required this.apiService});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final newProject = await widget.apiService.createProject(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        _selectedDeadline,
      );
      if (!mounted) return;
      // Return the created project on success
      Navigator.of(context).pop(newProject);
    } catch (e) {
      if (!mounted) return;
      // Return the error on failure
      Navigator.of(context).pop(e);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      helpText: 'PILIH TANGGAL DEADLINE',
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() => _selectedDeadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Buat Proyek Baru')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Proyek*'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nama proyek tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              Text("Deadline Proyek", style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDeadline == null
                            ? 'Pilih Tanggal'
                            : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDeadline!),
                        style: _selectedDeadline == null
                            ? AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600])
                            : AppTextStyles.bodyLarge,
                      ),
                      const Icon(Icons.calendar_today_outlined, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('BATAL'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createProject,
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('BUAT PROYEK'),
        ),
      ],
    );
  }
}