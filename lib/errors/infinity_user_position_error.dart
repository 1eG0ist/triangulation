/*
* Ошибка для обозначения некорректного значения при треангуляции, когда позиция пользователя
* уходит в бесконечнность
* */
class InfinityUserPositionError extends Error {
  InfinityUserPositionError({required this.message});

  final String message;
}