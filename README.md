# 3proxy Installer

Этот скрипт автоматизирует процесс установки и настройки 3proxy и Docker на Ubuntu-подобных системах.

## Описание

Скрипт выполняет следующие действия:

1. Устанавливает необходимые зависимости
2. Клонирует, собирает и устанавливает 3proxy
3. Настраивает 3proxy с пользовательскими параметрами
4. Создает и запускает systemd службу для 3proxy

## Требования

- Ubuntu или Debian-подобная система
- Права суперпользователя (sudo)
- Доступ к интернету

## Использование

1. Скачайте скрипт:
```shell
wget https://raw.githubusercontent.com/lupaev/install_3proxy/main/3proxy.sh
```
2. Сделайте скрипт исполняемым:
```shell
chmod +x 3proxy.sh
```
3. Запустите скрипт:
```shell
sudo ./3proxy.sh
```