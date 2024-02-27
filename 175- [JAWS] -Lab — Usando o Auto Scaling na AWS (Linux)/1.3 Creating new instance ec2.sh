#Esse script executa diversas tarefas de inicialização, incluindo a atualização de todos os softwares instalados na caixa e a instalação de um pequeno aplicativo Web PHP que você pode usar para simular uma alta carga de CPU na instância.
find -wholename /root/.*history -wholename /home/*/.*history -exec rm -f {} \;
find / -name 'authorized_keys' -exec rm -f {} \;
rm -rf /var/lib/cloud/data/scripts/* 

#Altere os valores keyname, amiid, httpaccess, subnetid 

#Exemplos:
#AMIID	ami-0dfd45428f2d4af0c
#KEYNAME	vockey
#SUBNETID	subnet-048effd6c6457345b
#HTTPACCESS	sg-0146de76b41eadaa1

aws ec2 run-instances --key-name KEYNAME --instance-type t3.micro --image-id AMIID --user-data file:///home/ec2-user/UserData.txt --security-group-ids HTTPACCESS --subnet-id SUBNETID --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer}]' --output text --query 'Instances[*].InstanceId'

#substituir o NEW-INSTANCE-ID pelo id adquirido.
#EXEMPLO: instance ID: i-0abef19b45caf169c
aws ec2 wait instance-running --instance-ids NEW-INSTANCE-ID

#substituir o NEW-INSTANCE-ID pelo ID adquirido para adquirir o PUBLIC-DNS-ADDRESS
aws ec2 describe-instances --instance-id NEW-INSTANCE-ID --query Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicDnsName

#ALTERE O PUBLIC-DNS-ADDRESS PARA O ENDEREÇO ADQUIRIDO
http://ec2-35-161-65-219.us-west-2.compute.amazonaws.com/index.php