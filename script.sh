#!/bin/bash
USERNAME="pet-clinic"

create_user(){

   if ! id "$USERNAME" &>/dev/null; then
	echo "Creating user: $USERNAME"
	useradd -m "$USERNAME"

   else
	echo "User $USERNAME already exists."
   

   fi
}
create_user

cp ./install-java.sh /home/${USERNAME}/install-java.sh
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
chmod +x /home/${USERNAME}/install-java.sh
sudo -u ${USERNAME} /home/${USERNAME}/install-java.sh

