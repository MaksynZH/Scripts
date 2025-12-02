# Змінні / Variables
ips=()
check_errors="unreachable=[1-9]|failed=[1-9]|rescued=[1-9]|ignored=[1-9]"
ssh_key="$HOME/.ssh/id_ed25519.pub"
ssh_pass="y\GHkPkj|xhsJE6\c^6|"
tagskip=preparationskiptag
name_group=preparation

# Збираємо IP-адреси, перевіряємо їх правильність і продовжуємо далі / We collect IP addresses, check their correctness and continue
while true; do
  read -p "Введіть IP-адреси через пробіл / Enter IP addresses through a space: " -a new_ips
  ips+=("${new_ips[@]}")
  echo "Ви ввели такі IP:"
  printf '%s\n' "${ips[@]}"
  read -p "Чи правильно ви ввели IP-адреси? (y/n) / Did you enter IP addresses correctly? (y/n): " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then break; else echo "Введіть IP ще раз або додайте нові / Enter the IP again or add new ones"; fi
done

# Очищуємо IP-адресу після слова preparation / Clear the IP after the word preparation
sed -i -e "/$name_group/q" $HOME/ansible-infrastructure/hosts

# Додаємо кожний IP окремо з додаванням ansible_user=root / We add each IP separately with the addition of ansible_user=root
for ip in "${ips[@]}"; do
  sed -i "/$name_group/ a $ip ansible_user=root" $HOME/ansible-infrastructure/hosts
done

# Додаємо тег preparationskiptag після кожного #need skip / We add the preparationskiptag tag after each #need skip
sed -i "/#need skip/ a\      tags: $tagskip" $HOME/ansible-infrastructure/awx-initial-install-repo.yml

# Копіюємо ssh ключ на кожний IP / We copy the ssh key to each IP 
for ipssh in "${ips[@]}"; do
  /bin/sshpass -p "$ssh_pass" ssh-copy-id -i "$ssh_key" root@$ipssh
done

# Команда для тестового запуску playbook awx-initial-install-repo.yml / Command to test run playbook awx-initial-install-repo.yml
ansible_check_awx_initial_check=$(/usr/bin/ansible-playbook $HOME/ansible-infrastructure/awx-initial-install-repo.yml --limit "$name_group" --skip-tags $tagskip --check -f 50 2>&1)
exit_code=$?

# Перевіряємо наявність помилок, за їх відсутності запускаємо основну команду / We check the presence of errors, in their absence we start the main command
if [[ $exit_code -ne 0 ]] || echo "$ansible_check_awx_initial_check" | grep -Eq "$check_errors" ; then
  echo "Знайдена помилка:"
  echo "$ansible_check_awx_initial_check"
  else
    /usr/bin/ansible-playbook $HOME/ansible-infrastructure/awx-initial-install-repo.yml --limit "$name_group" -f 50
fi

# Команда для тестового запуску playbook interserver.yaml / Command to test run playbook interserver.yaml
ansible_check_interserver_check=$(/usr/bin/ansible-playbook $HOME/ansible-infrastructure/interserver.yaml --limit "$name_group" --check -f 50 2>&1)
exit_code=$?

# Перевіряємо наявність помилок, за їх відсутності запускаємо основну команду / We check the presence of errors, in their absence we start the main command
if [[ $exit_code -ne 0 ]] || echo "$ansible_check_interserver_check" | grep -Eq "$check_errors" ; then
  echo "Знайдена помилка:"
  echo "$ansible_check_interserver_check"
  else
    /usr/bin/ansible-playbook $HOME/ansible-infrastructure/interserver.yaml --limit "$name_group" -f 50
fi

# Видаляємо тег preparationskiptag після виконаних робіт / We remove the preparationskiptag tag after the work has been completed
sed -i "/tags: $tagskip/d" $HOME/ansible-infrastructure/awx-initial-install-repo.yml

# Завершуємо script без помилок / We complete the script without errors
exit 0