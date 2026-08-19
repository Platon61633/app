import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format_utils.dart';
import 'map.dart';

/// Ставки за м² по типу работ — условные значения-заглушки, как и цена за
/// дерево при спиле или "площадь * 5" у покоса; поменять — минутное дело.
const Map<String, int> _constructionRates = {
  'Забор': 3000,
  'Терраса / настил': 4000,
  'Мощение / плитка': 2000,
  'Другое': 2500,
};

/// Открывает форму оформления "Строя" отдельным экраном — по той же схеме,
/// что и "Спил": обычная страница вместо модального окна снизу, без риска
/// словить ассерт-ошибку Flutter при закрытии клавиатуры во время
/// Navigator.pop().
Future<MapSelectionResult?> openConstructionModal(BuildContext context) {
  return Navigator.push<MapSelectionResult>(
    context,
    MaterialPageRoute(builder: (_) => const ConstructionScreen()),
  );
}

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _commentController = TextEditingController();
  String _workType = _constructionRates.keys.first;
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _confirm() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите адрес')),
      );
      return;
    }

    final area = int.tryParse(_areaController.text.trim());
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите площадь работ в м²')),
      );
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите время')),
      );
      return;
    }

    final price = area * (_constructionRates[_workType] ?? 0);
    final comment = _commentController.text.trim();
    // Отдельного поля "тип работ" в заказе нет — чтобы не трогать бэкенд,
    // просто добавляем его первой строкой в комментарий: и на "Мои заказы",
    // и в корзине это будет видно без доработки схемы заказа.
    final typeLine = 'Тип работ: $_workType';

    final selection = MapSelectionResult(
      serviceName: 'Строй',
      area: area,
      price: price,
      address: address,
      note: '',
      comment: comment.isEmpty ? typeLine : '$typeLine\n$comment',
      scheduledAt: _selectedDateTime!,
    );

    // Обычный Navigator.pop у полноценной страницы — тот же безопасный путь,
    // что и у "Покоса"/"Спила".
    Navigator.of(context).pop(selection);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateText = _selectedDateTime == null
        ? 'Время не выбрано'
        : formatDateTimeRu(_selectedDateTime!);
    final area = int.tryParse(_areaController.text.trim()) ?? 0;
    final price = area * (_constructionRates[_workType] ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Строительные работы')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  hintText: 'Где нужно выполнить работы',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Тип работ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _constructionRates.keys.map((type) {
                  final selected = type == _workType;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _workType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _areaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Площадь работ',
                  hintText: 'Например, 40',
                  suffixText: 'м²',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedDateText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDateTime,
                    child: const Text('Выбрать время'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  hintText: 'Опишите, что нужно сделать',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Цена: $price рублей',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: const Text('Далее'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
