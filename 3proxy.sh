#!/bin/bash

set -e  # Останавливает выполнение скрипта при любой ошибке

# Функция для проверки успешности выполнения команды
check_success() {
    if [ $? -ne 0 ]; then
        echo "Ошибка: $1"
        exit 1
    fi
}

# Обновление и установка необходимых пакетов
sudo apt update
sudo apt install -y build-essential git ca-certificates curl
check_success "Не удалось установить необходимые пакеты"

# Установка Docker
echo "Установка Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
check_success "Не удалось установить Docker"

# Клонирование репозитория 3proxy
git clone https://github.com/z3APA3A/3proxy.git
cd 3proxy
check_success "Не удалось клонировать репозиторий 3proxy"

# Сборка и установка 3proxy
ln -s Makefile.Linux Makefile
make
sudo make install
check_success "Не удалось собрать и установить 3proxy"

# Создание необходимых директорий и копирование файлов
sudo mkdir -p /usr/local/3proxy/bin/
sudo cp ./bin/3proxy /usr/local/bin/
sudo mkdir -p /var/log/3proxy
check_success "Не удалось создать необходимые директории"

# Настройка прав доступа
sudo chown -R root:root /usr/local/3proxy
sudo chmod 755 /usr/local/bin/3proxy
sudo chmod 644 /usr/local/3proxy/conf/3proxy.cfg
sudo chmod 755 /var/log/3proxy
check_success "Не удалось настроить права доступа"

# Запрос данных пользователя
read -p "Введите имя пользователя: " username
while true; do
    read -s -p "Введите пароль: " password
    echo
    read -s -p "Подтвердите пароль: " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Пароли не совпадают. Попробуйте снова."
done

while true; do
    read -p "Введите порт (1024-65535): " port
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
        break
    else
        echo "Неверный порт. Попробуйте снова."
    fi
done

# Создание конфигурационного файла
cat << EOF | sudo tee /usr/local/3proxy/conf/3proxy.cfg
nserver 8.8.8.8
nserver 8.8.4.4

log /var/log/3proxy/3proxy-%y%m%d.log D
rotate 60

users $username:CL:$password
auth strong
allow *

proxy -p$port
EOF
check_success "Не удалось создать конфигурационный файл"

# Создание файла службы systemd
cat << EOF | sudo tee /usr/lib/systemd/system/3proxy.service
[Unit]
Description=3proxy tiny proxy server
Documentation=man:3proxy(1)
After=network.target

[Service]
Environment=CONFIGFILE=/usr/local/3proxy/conf/3proxy.cfg
ExecStart=/usr/local/bin/3proxy \${CONFIGFILE}
ExecReload=/bin/kill -SIGUSR1 \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=60s
LimitNOFILE=65536
LimitNPROC=32768
RuntimeDirectory=3proxy

[Install]
WantedBy=multi-user.target
Alias=3proxy.service
EOF
check_success "Не удалось создать файл службы systemd"

# Перезагрузка демона systemd и запуск службы 3proxy
sudo systemctl daemon-reload
sudo systemctl enable 3proxy
sudo systemctl start 3proxy
check_success "Не удалось запустить службу 3proxy"

echo "3proxy и Docker успешно установлены и запущены."
echo "Настройки 3proxy:"
echo "Пользователь: $username"
echo "Порт: $port"
echo "Конфигурационный файл: /usr/local/3proxy/conf/3proxy.cfg"
echo "Лог-файлы: /var/log/3proxy/"
echo "Docker установлен и текущий пользователь добавлен в группу docker."
echo "Возможно, потребуется перезагрузка или выход из системы для применения изменений группы."
