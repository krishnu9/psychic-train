import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import '../../models/tables.dart';

/// Shows a bottom sheet for creating a custom exercise.
/// Returns the newly created [Exercise], or null if cancelled.
Future<Exercise?> showCreateExerciseSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _CreateExerciseForm(ref: ref),
  );
}

class _CreateExerciseForm extends StatefulWidget {
  final WidgetRef ref;
  const _CreateExerciseForm({required this.ref});

  @override
  State<_CreateExerciseForm> createState() => _CreateExerciseFormState();
}

class _CreateExerciseFormState extends State<_CreateExerciseForm> {
  final _nameController = TextEditingController();
  String _category = ExerciseCategories.chest;
  String _equipment = EquipmentTypes.barbell;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Custom Exercise',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Exercise name'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            dropdownColor: AppColors.surfaceLight,
            items: ExerciseCategories.all
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _equipment,
            decoration: const InputDecoration(labelText: 'Equipment'),
            dropdownColor: AppColors.surfaceLight,
            items: EquipmentTypes.all
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _equipment = v);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                final repo = widget.ref.read(exerciseRepositoryProvider);
                final id = await repo.create(
                  name: name,
                  category: _category,
                  targetMuscle: _category,
                  equipment: _equipment,
                );
                final exercise = await repo.getById(id);
                if (context.mounted) Navigator.pop(context, exercise);
              },
              child: const Text('Add Exercise'),
            ),
          ),
        ],
      ),
    );
  }
}
