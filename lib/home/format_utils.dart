/// Форматирование даты/времени для отображения в UI приложения.
/// Вынесено в отдельный файл, чтобы им могли пользоваться разные экраны
/// (корзина, "Мои заказы", форма "Спила") без дублирования кода.

/// Форматирует дату/время в привычном виде: "20 августа 2026, 14:30".
String formatDateTimeRu(DateTime value) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day ${months[value.month - 1]} ${value.year}, $hour:$minute';
}
