import 'package:flutter/material.dart';

import 'format_utils.dart';
import 'map.dart';

// Цена за одно дерево при спиле — просто заглушка, как и "площадь * 5"
// для покоса в map.dart; при необходимости легко поменять.
const int _pricePerTree = 1500;

/// Открывает форму оформления "Спила" отдельным экраном (Navigator.push),
/// а не модальным окном снизу.
///
/// Раньше это было showModalBottomSheet + StatefulBuilder с текстовыми
/// полями внутри — такая комбинация в Flutter иногда роняет приложение с
/// ассерт-ошибкой "_dependents.isEmpty" / "build dirty widget in the wrong
/// build scope", если Navigator.pop() происходит, пока в поле ввода ещё
/// есть фокус (открыта клавиатура), и FocusScope.unfocus() перед закрытием
/// это не всегда предотвращает. Обычная страница (как у "Покоса"/"Строя"
/// на карте, как формы входа и регистрации) использует простой и уже
/// проверенный в этом приложении путь Navigator.push/pop без модалок и
/// вложенных StatefulBuilder — там такой ошибки не бывает.
Future<MapSelectionResult?> openTreeCuttingModal(BuildContext context) {
  return Navigator.push<MapSelectionResult>(
    context,
    MaterialPageRoute(builder: (_) => const TreeCuttingScreen()),
  );
}

class TreeCuttingScreen extends StatefulWidget {
  const TreeCuttingScreen({super.key});

  @override
  State<TreeCuttingScreen> createState() => _TreeCuttingScreenState();
}

class _TreeCuttingScreenState extends State<TreeCuttingScreen> {
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();
  int _treeCount = 1;
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _addressController.dispose();
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
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите время')),
      );
      return;
    }

    final selection = MapSelectionResult(
      serviceName: 'Спил',
      area: _treeCount,
      price: _treeCount * _pricePerTree,
      address: address,
      note: '',
      comment: _commentController.text.trim(),
      scheduledAt: _selectedDateTime!,
    );

    // Обычный Navigator.pop у полноценной страницы — тот же путь, что уже
    // безопасно используется у "Покоса"/"Строя" на карте.
    Navigator.of(context).pop(selection);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateText = _selectedDateTime == null
        ? 'Время не выбрано'
        : formatDateTimeRu(_selectedDateTime!);
    final price = _treeCount * _pricePerTree;

    return Scaffold(
      appBar: AppBar(title: const Text('Спил деревьев')),
      // Обычная страница сама ужимается под клавиатуру
      // (resizeToAvoidBottomInset включён у Scaffold по умолчанию),
      // а SingleChildScrollView страхует от переполнения на маленьких
      // экранах — то, ради чего раньше приходилось городить костыли
      // в модальном окне.
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
                  hintText: 'Где нужно спилить деревья',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Количество деревьев',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: _treeCount > 1 ? () => setState(() => _treeCount--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_treeCount',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _treeCount++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
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
                  hintText: 'Например: аварийное дерево у забора',
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
