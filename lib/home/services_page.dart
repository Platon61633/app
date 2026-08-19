import 'package:flutter/material.dart';

import 'construction_modal.dart';
import 'map.dart';
import 'tree_cutting_modal.dart';

/// Стартовая вкладка "Услуги" со списком карточек (Покос / Спил / Строй).
class ServicesPage extends StatelessWidget {
  const ServicesPage({
    super.key,
    required this.cartCount,
    required this.onCartPressed,
    required this.onServiceSelected,
  });

  final int cartCount;
  final VoidCallback onCartPressed;
  final ValueChanged<MapSelectionResult> onServiceSelected;

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceCard(
        title: 'Покос',
        subtitle: 'Профессиональная услуга по покосу травы и кустарников',
        icon: Icons.grass_rounded,
        onSelected: onServiceSelected,
      ),
      _ServiceCard(
        title: 'Спил',
        subtitle: 'Удаление деревьев и безопасный спил стволов',
        icon: Icons.forest_rounded,
        onSelected: onServiceSelected,
        // У "Спила" нет площади для выделения на карте — вместо экрана
        // с картой сразу открываем форму с адресом, временем,
        // количеством деревьев и комментарием.
        onTap: () async {
          // Ждём полного закрытия модалки и только потом добавляем заказ
          // в корзину: если вызвать setState (через onServiceSelected) до
          // того, как лист закончил закрываться, Flutter падает с
          // "_dependents.isEmpty" / "build dirty widget in the wrong
          // build scope" — тот же паттерн, что и у карты ниже.
          final result = await openTreeCuttingModal(context);
          if (result != null && context.mounted) {
            onServiceSelected(result);
          }
        },
      ),
      _ServiceCard(
        title: 'Строй',
        subtitle: 'Строительные работы и благоустройство участка',
        icon: Icons.construction_rounded,
        onSelected: onServiceSelected,
        // Как и у "Спила" — своя форма вместо карты: тут важны тип работ
        // и площадь в м², а не многоугольник на местности.
        onTap: () async {
          final result = await openConstructionModal(context);
          if (result != null && context.mounted) {
            onServiceSelected(result);
          }
        },
      ),
    ];

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 52),
                  const Text(
                    'Услуги',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Выберите нужную услугу',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: service,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: IconButton.filled(
                onPressed: onCartPressed,
                icon: const Icon(Icons.shopping_cart_rounded),
                tooltip: 'Корзина',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<MapSelectionResult> onSelected;
  // Если не задан — по умолчанию открывается экран выбора площади на карте.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ??
            () async {
              final result = await Navigator.push<MapSelectionResult>(
                context,
                MaterialPageRoute(builder: (_) => MapScreen(serviceName: title)),
              );
              if (result != null && context.mounted) {
                onSelected(result);
              }
            },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F6F8B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 30, color: const Color(0xFF1F6F8B)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
