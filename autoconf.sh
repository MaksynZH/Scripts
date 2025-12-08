# ЗМІННІ
ip_addresses=()
gologin_token=""
sms_prod=""
zero_patient=""
path_ssh_key="~/.ssh/id_ed25519"
ssh_password="y\GHkPkj|xhsJE6\c^6|"
forks_speed=""
run_awx_initial=""
run_awx_clone=""
run_interserver=""
awx_initial_name="awx-initial-install-repo-edit.yml"
awx_clone_name="awx-clone-profiles-repo-edit.yaml"
interserver_name="interserver.yaml"
errors="unreachable=[1-9]|failed=[1-9]|rescued=[1-9]|ignored=[1-9]"
# ПЕРЕВІРКА ВЕДЕНИХ ДАНИХ
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть IP-адреси через пробіл: " -a new_ips
    ip_addresses+=("${new_ips[@]}")
   echo "Ви ввели такі IP:"
    printf '%s\n' "${ip_addresses[@]}"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && ip_addresses=()
done
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть GoLogin Token: " gologin_token
    echo "Ви ввели GoLogin Token: $gologin_token"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && gologin_token=""
done
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть SMS PROD KEY: " sms_prod
    echo "Ви ввели SMS PROD KEY: $sms_prod"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && sms_prod=""
done
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть ZERO PATIENT: " zero_patient
    echo "Ви ввели ZERO PATIENT: $zero_patient"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && zero_patient=""
done
#echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
#confirm="n"
#until [[ $confirm == "y" || $confirm == "Y" ]]; do
#    read -p "Введіть шлях до ssh ключа (Зазвичай це ~/.ssh/id_ed25519 або ~/.ssh/id_rsa): " path_ssh_key
#    echo "Ви ввели шлях до ssh ключа: $path_ssh_key"
#    read -p "Чи правильно? (y/n): " confirm
#    [[ $confirm != "y" && $confirm != "Y" ]] && path_ssh_key=""
#done
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть швидкість команд (forks): " forks_speed
    echo "Ви ввели швидкість: $forks_speed"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && forks_speed=""
done
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть чи запускати файл interserver.yaml (yes/no): " run_interserver
    echo "Ви ввели: $run_interserver"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && run_interserver=""
done
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть чи запускати файл awx-initial-install-repo.yml (yes/no): " run_awx_initial
    echo "Ви ввели: $run_awx_initial"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && run_awx_initial=""
done
echo     # ПРОПУСК МІЖ ЗАПИТАННЯМИ
confirm="n"
until [[ $confirm == "y" || $confirm == "Y" ]]; do
    read -p "Введіть чи запускати файл awx-clone-profiles-repo.yaml (yes/no): " run_awx_clone
    echo "Ви ввели: $run_awx_clone"
    read -p "Чи правильно? (y/n): " confirm
    [[ $confirm != "y" && $confirm != "Y" ]] && run_awx_clone=""
done
# ЗМІНА ФАЙЛІ
printf '\n[%s]\n' "$name_group_ip" | sed -i -e '$r/dev/stdin' hosts
for ip in "${ip_addresses[@]}"; do
  /usr/bin/sed -i "/$name_group_ip/ a $ip ansible_user=root" hosts
done

/usr/bin/sed -i 's/private_key_file = ~\/.ssh\/id_rsa/private_key_file = ~\/.ssh\/id_ed25519/g' ansible.cfg
/usr/bin/sed -i "/private_key_file = ~\/.ssh\/id_ed25519/ a host_key_checking = False" ansible.cfg

/usr/bin/sed -i "s|gologin_token: *|gologin_token: $gologin_token|g" $awx_clone_name
/usr/bin/sed -i '/sms_key:/,/test:/ s/^      prod: */      prod: '"$sms_prod"'/' "$awx_clone_name"
/usr/bin/sed -i "s|zero_patient: *|zero_patient: $zero_patient|g" $awx_clone_name
# ДОДАЄМО SSH KEY
printf '%s\n' "${ip_addresses[@]}" | parallel -j 5 /usr/bin/sshpass -p "$ssh_password" /usr/bin/ssh-copy-id -i "$path_ssh_key" root@{} >/dev/null 2>&1 || true
# ОСНОВНА КОМАНДИ
interserver () {
  ansible_check_interserver_check=$(/usr/bin/ansible-playbook $interserver_name --limit "$name_group_ip" -f "$forks_speed" 2>&1)
  if echo "$ansible_check_interserver_check" | grep -Eq "$errors" ; then
    echo "ЗНАЙДЕНА ПОМИЛКА:"
    echo "$ansible_check_interserver_check" | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}|$errors" | grep -v "UNREACHABLE"
  fi
}
if [[ "$run_interserver" == "yes" ]]; then interserver; fi
awx_initial () {
  ansible_check_awx_initial_check=$(/usr/bin/ansible-playbook $awx_initial_name --limit "$name_group_ip" -f "$forks_speed" 2>&1)
  if echo "$ansible_check_awx_initial_check" | grep -Eq "$errors" ; then
    echo "ЗНАЙДЕНА ПОМИЛКА:"
    echo "$ansible_check_awx_initial_check" | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}|$errors" | grep -v "UNREACHABLE"
  fi
}
if [[ "$run_awx_initial" == "yes" ]]; then awx_initial; fi
awx_clone () {
  ansible_check_awx_clone_check=$(/usr/bin/ansible-playbook $awx_clone_name --limit "$name_group_ip" 2>&1)
  if echo "$ansible_check_awx_clone_check" | grep -Eq "$errors" ; then
    echo "ЗНАЙДЕНА ПОМИЛКА:"
    echo "$ansible_check_awx_clone_check" | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}|$errors" | grep -v "UNREACHABLE"
  fi
}
if [[ "$run_awx_clone" == "yes" ]]; then awx_clone; fi
# ВИДАЛЯЄМО ВСІ ЗМІННИ В ФАЙЛАХ
/usr/bin/sed -i "s/\(gologin_token:\) *.*/\1/" $awx_clone_name
/usr/bin/sed -i 's/^      prod: .*/      prod: /' "$awx_clone_name"
/usr/bin/sed -i "s/\(zero_patient:\) *.*/\1/" $awx_clone_name

/usr/bin/sed -i 's/private_key_file = ~\/.ssh\/id_ed25519/private_key_file = ~\/.ssh\/id_rsa/g' ansible.cfg
/usr/bin/sed -i "/host_key_checking = False/d" ansible.cfg

sed -i "/$name_group_ip/,\$d" hosts
#KIНЕЦЬ