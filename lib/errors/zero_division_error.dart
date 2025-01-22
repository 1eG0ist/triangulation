/*
* Ошибка деления на 0
* */
class ZeroDivisionError extends Error {
  ZeroDivisionError({required this.message});

  final String message;
}