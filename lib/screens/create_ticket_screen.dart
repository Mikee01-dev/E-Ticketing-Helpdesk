import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ticket_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_picker_widget.dart';
import '../utils/validator.dart';
import '../utils/constants.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final ticketController = Get.find<TicketController>();
  final formKey = GlobalKey<FormState>();

  String selectedPriority = TicketPriority.medium;
  String? selectedCategory;
  String? imageUrl;

  final List<String> categories = [
    'Hardware',
    'Software',
    'Network',
    'Account',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Judul Tiket',
                hint: 'Masukkan judul keluhan',
                controller: titleController,
                validator: Validator.validateTitle,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Deskripsi',
                hint: 'Jelaskan keluhan Anda secara detail',
                controller: descriptionController,
                maxLines: 5,
                validator: Validator.validateDescription,
              ),
              const SizedBox(height: 16),
              // Priority
              const Text(
                'Prioritas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityOption(TicketPriority.low, 'Low', Colors.green),
                  const SizedBox(width: 8),
                  _buildPriorityOption(TicketPriority.medium, 'Medium', Colors.orange),
                  const SizedBox(width: 8),
                  _buildPriorityOption(TicketPriority.high, 'High', Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              // Category
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                hint: const Text('Pilih kategori'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              // Image picker
              const Text(
                'Lampiran (Opsional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ImagePickerWidget(
                onImageUploaded: (url) {
                  setState(() {
                    imageUrl = url;
                  });
                },
                initialImageUrl: imageUrl,
              ),
              const SizedBox(height: 32),
              Obx(
                    () => CustomButton(
                  text: 'Buat Tiket',
                  onPressed: _createTicket,
                  isLoading: ticketController.isLoading.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String value, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selectedPriority == value
                ? color.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedPriority == value ? color : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selectedPriority == value ? color : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createTicket() async {
    if (formKey.currentState!.validate()) {
      await ticketController.createTicket(
        title: titleController.text,
        description: descriptionController.text,
        imageUrl: imageUrl,
        category: selectedCategory,
        priority: selectedPriority,
      );
    }
  }
}