# Nesta tarefa, você cria uma nova AMI com base na instância que acabou de criar.
# Para criar uma nova AMI baseada nesta instância, no seguinte comando aws ec2 create-image, substitua NEW-INSTANCE-ID pelo valor que você copiou anteriormente e execute o comando ajustado:

aws ec2 create-image --name WebServerAMI --instance-id i-0abef19b45caf169c
#ImageId": "ami-09baaccf62be7583d
