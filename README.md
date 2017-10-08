# asm2017arm
Курс УрФУ по ассемблеру для ARM.

### Полезные ссылки:
* [gcc-arm-linux-gnueabihf](https://github.com/offensive-security/gcc-arm-linux-gnueabihf-4.7)
* [gcc-linaro-arm-linux-gnueabi](https://releases.linaro.org/components/toolchain/binaries/latest/arm-linux-gnueabi/)

### Задачи с практик:
1. Вывод факториала по середине консоли, разбитое пробелом по 3 цифры. Число адекватное (влазит в регистр 32бита). Решение в файле `first.s`. Для работоспособности нужно перед запуском экспортировать LINES и COLUMNS в переменные окружения. Работоспособность в терминале 80x25 осуществлена коммитом ранее.
