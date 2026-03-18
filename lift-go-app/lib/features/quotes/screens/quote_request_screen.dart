import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../repositories/quotes_repository.dart';

class QuoteRequestScreen extends ConsumerStatefulWidget {
  const QuoteRequestScreen({super.key});

  @override
  ConsumerState<QuoteRequestScreen> createState() => _QuoteRequestScreenState();
}

class _QuoteRequestScreenState extends ConsumerState<QuoteRequestScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Service type
  String? _selectedServiceType;

  // Step 2: Move details
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _moveDate;

  // Step 3: Photos
  final List<XFile> _selectedPhotos = [];

  // Step 4: Survey option
  String _surveyOption = 'submit'; // or 'virtual_survey'

  bool _isSubmitting = false;

  static const _serviceTypes = [
    'Local Move',
    'Long Distance',
    'International',
    'Office Move',
    'Storage',
    'Packing Only',
    'Piano Moving',
    'Vehicle Transport',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedServiceType != null;
      case 1:
        return _originController.text.trim().isNotEmpty &&
            _destinationController.text.trim().isNotEmpty &&
            _moveDate != null;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(limit: 5);
    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos.clear();
        _selectedPhotos.addAll(images.take(5));
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(quotesRepositoryProvider).createQuoteRequest({
        'service_type': _selectedServiceType,
        'origin_address': _originController.text.trim(),
        'destination_address': _destinationController.text.trim(),
        'preferred_move_date': _moveDate?.toIso8601String(),
        'survey_type': _surveyOption,
        'source': 'mobile_app',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote request submitted! We\'ll be in touch soon.'),
          ),
        );
        context.go('/quotes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Quote'),
        leading: BackButton(onPressed: () {
          if (_currentStep > 0) {
            _prevPage();
          } else {
            context.pop();
          }
        }),
      ),
      body: Column(
        children: [
          // Progress bar
          _StepProgressBar(currentStep: _currentStep, totalSteps: 5),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1ServiceType(
                  selectedType: _selectedServiceType,
                  onSelect: (t) => setState(() => _selectedServiceType = t),
                ),
                _Step2MoveDetails(
                  originController: _originController,
                  destinationController: _destinationController,
                  moveDate: _moveDate,
                  onDatePicked: (d) => setState(() => _moveDate = d),
                ),
                _Step3Photos(
                  photos: _selectedPhotos,
                  onPickPhotos: _pickPhotos,
                  onRemove: (i) => setState(() => _selectedPhotos.removeAt(i)),
                ),
                _Step4Survey(
                  value: _surveyOption,
                  onChanged: (v) => setState(() => _surveyOption = v),
                ),
                _Step5Confirmation(
                  serviceType: _selectedServiceType ?? '',
                  origin: _originController.text,
                  destination: _destinationController.text,
                  moveDate: _moveDate,
                  photoCount: _selectedPhotos.length,
                  surveyOption: _surveyOption,
                ),
              ],
            ),
          ),

          // Bottom nav
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevPage,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _currentStep == 4
                      ? ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Submit Request'),
                        )
                      : ElevatedButton(
                          onPressed: _canProceed ? _nextPage : null,
                          child: const Text('Next'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Bar
// ---------------------------------------------------------------------------

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                _stepLabel(currentStep),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  String _stepLabel(int step) {
    const labels = [
      'Service Type',
      'Move Details',
      'Photos',
      'Survey',
      'Confirm',
    ];
    return labels[step];
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Service Type
// ---------------------------------------------------------------------------

class _Step1ServiceType extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String> onSelect;

  const _Step1ServiceType({required this.selectedType, required this.onSelect});

  static const _serviceTypes = [
    ('Local Move', Icons.home_outlined),
    ('Long Distance', Icons.map_outlined),
    ('International', Icons.flight_outlined),
    ('Office Move', Icons.business_outlined),
    ('Storage', Icons.storage_outlined),
    ('Packing Only', Icons.inventory_2_outlined),
    ('Piano Moving', Icons.piano_outlined),
    ('Vehicle Transport', Icons.directions_car_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What service do you need?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the type of moving service you require.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: _serviceTypes.map((entry) {
              final label = entry.$1;
              final icon = entry.$2;
              final isSelected = selectedType == label;
              return InkWell(
                onTap: () => onSelect(label),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 28,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Move Details
// ---------------------------------------------------------------------------

class _Step2MoveDetails extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final DateTime? moveDate;
  final ValueChanged<DateTime> onDatePicked;

  const _Step2MoveDetails({
    required this.originController,
    required this.destinationController,
    required this.moveDate,
    required this.onDatePicked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move Details',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us where you\'re moving from and to.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: originController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Origin address / city',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: destinationController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Destination address / city',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) onDatePicked(picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Preferred move date',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                moveDate != null
                    ? DateFormat('dd MMM yyyy').format(moveDate!)
                    : 'Select date',
                style: moveDate != null
                    ? Theme.of(context).textTheme.bodyMedium
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Photos
// ---------------------------------------------------------------------------

class _Step3Photos extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onRemove;

  const _Step3Photos({
    required this.photos,
    required this.onPickPhotos,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Photos',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Add up to 5 photos of items you need moved. This helps us give you a more accurate quote.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: photos.length < 5 ? onPickPhotos : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outline,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 40, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      photos.length < 5
                          ? 'Tap to add photos (${photos.length}/5)'
                          : 'Maximum 5 photos added',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photos[i].path,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: colorScheme.surfaceContainerLow,
                            child: Icon(Icons.image_outlined,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(i),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Optional — you can skip this step',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — Survey option
// ---------------------------------------------------------------------------

class _Step4Survey extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _Step4Survey({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you want to proceed?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose between a virtual survey or a direct quote submission.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          _SurveyOption(
            value: 'virtual_survey',
            groupValue: value,
            icon: Icons.video_call_outlined,
            title: 'Schedule Virtual Survey',
            subtitle:
                'Our team will video call you to assess your belongings and give you an accurate quote.',
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          _SurveyOption(
            value: 'submit',
            groupValue: value,
            icon: Icons.send_outlined,
            title: 'Submit for Quote',
            subtitle:
                'Send your request now and we\'ll prepare an estimate based on the details provided.',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SurveyOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;

  const _SurveyOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
            const SizedBox(width: 8),
            Icon(icon,
                size: 28,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5 — Confirmation summary
// ---------------------------------------------------------------------------

class _Step5Confirmation extends StatelessWidget {
  final String serviceType;
  final String origin;
  final String destination;
  final DateTime? moveDate;
  final int photoCount;
  final String surveyOption;

  const _Step5Confirmation({
    required this.serviceType,
    required this.origin,
    required this.destination,
    required this.moveDate,
    required this.photoCount,
    required this.surveyOption,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Request',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Please confirm the details below before submitting.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ConfirmRow(
                    icon: Icons.category_outlined,
                    label: 'Service Type',
                    value: serviceType,
                  ),
                  const Divider(),
                  _ConfirmRow(
                    icon: Icons.location_on_outlined,
                    label: 'From',
                    value: origin.isNotEmpty ? origin : '—',
                  ),
                  const Divider(),
                  _ConfirmRow(
                    icon: Icons.location_on,
                    label: 'To',
                    value: destination.isNotEmpty ? destination : '—',
                  ),
                  const Divider(),
                  _ConfirmRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Move Date',
                    value: moveDate != null
                        ? DateFormat('dd MMM yyyy').format(moveDate!)
                        : 'Not specified',
                  ),
                  const Divider(),
                  _ConfirmRow(
                    icon: Icons.photo_library_outlined,
                    label: 'Photos',
                    value: photoCount > 0
                        ? '$photoCount photo${photoCount > 1 ? 's' : ''}'
                        : 'None',
                  ),
                  const Divider(),
                  _ConfirmRow(
                    icon: Icons.video_call_outlined,
                    label: 'Survey',
                    value: surveyOption == 'virtual_survey'
                        ? 'Virtual Survey'
                        : 'Direct Quote',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Our team will review your request and get back to you within 24 hours.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
