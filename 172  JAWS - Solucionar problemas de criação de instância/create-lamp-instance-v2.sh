#!/bin/bash
DATE=`date '+%Y-%m-%d %H:%M:%S'`
 echo
 echo "rodando create-instance.sh on "$DATE
 echo

# definindo instancia
   instanceType="t3.small" # esta linha decide o tipo da instancia que será "t3.small"
   echo "Instance Type: "$instanceType # Imprimi qual foi o tipo da instancia provisionada
  profile="default" # definindo o profile default
  echo "Profile: "$profile # Imprimi o profile
 
  echo
  echo "Procurando valores de conta..."
  
  # Pegar a vpcId
  vpc="" # Inicializa a variável 'vpc' com uma string vazia
  while [[ "$vpc" == "" ]] ; do # Inicia um loop while que continua enquanto a variável 'vpc' for uma string vazia
    for i in $(aws ec2 describe-regions | grep RegionName | cut -d '"' -f4) ; do # Itera sobre as regiões obtidas a partir do comando 'aws ec2 describe-regions'
      region=$i; # Atribui a região atual à variável 'region'
      vpc=$(aws ec2 describe-vpcs --region $i --filters "Name=tag:Name,Values='Cafe VPC'" --profile $profile | grep VpcId | cut -d '"' -f4 | sed -n 1p ); # Obtém o ID da VPC para a VPC especificada com a tag "Cafe VPC" na região atual
      if [[ "$vpc" != "" ]]; then # Verifica se a variável 'vpc' não é uma string vazia
          break; # Sai do loop se um ID de VPC não vazio for encontrado
      fi
    done
  done
  echo
  echo "VPC: "$vpc # Imprime o ID da VPC
  echo "Region: "$region # Imprime a região encontrada
  
  vpc=$(aws ec2 describe-vpcs \ 
  --filters "Name=tag:Name,Values='Cafe VPC'" \
  --region $region \ 
  --profile $profile | grep VpcId | cut -d '"' -f4 | sed -n 1p)
  echo "VPC: "$vpc
  
  # get subnetId
  subnetId=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values='Cafe Public Subnet 1'" \
  --region $region \
  --profile $profile \
  --query "Subnets[*]" | grep SubnetId | cut -d '"' -f4 | sed -n 1p)
  echo "Subnet Id: "$subnetId
  
  # Get keypair name
  key=$(aws ec2 describe-key-pairs \
  --profile $profile --region $region | grep KeyName | cut -d '"' -f4 )
  echo "Key: "$key
  
  # Get AMI ID
  imageId=$(aws ssm get-parameters \
  --names '/aws/service/ami-amazon-linux-latest/amazon/amzn2-ami-hvm-2.0-x86_64-gp2' \
  --profile $profile \
  --region $region | grep ami- | cut -d '"' -f4 | sed -n 2p)
  echo "AMI ID: "$imageId
  
  #check for existing cafe instance
  existingEc2Instance=$(aws ec2 describe-instances \
  --region $region \
  --profile $profile \
  --filters "Name=tag:Name,Values=cafeserver" "Name=instance-state-name,Values=running" \
  | grep InstanceId | cut -d '"' -f4)
  if [[ "$existingEc2Instance" != "" ]]; then
    echo
    echo "WARNING: Found existing running EC2 instance with instance ID "$existingEc2Instance"."
    echo "This script will not succeed if it already exists. "
    echo "Would you like to delete it? [Y/N]"
    echo ">>"
  
    validResp=0
    while [ $validResp -eq 0 ];
    do
        read answer
        if [[ "$answer" == "Y" || "$answer" == "y" ]]; then
            echo
            echo "Deleting the existing instance..."
            aws ec2 terminate-instances --instance-ids $existingEc2Instance --region $region --profile $profile
            #wait for confirmation it was terminated
            aws ec2 wait instance-terminated --instance-ids $existingEc2Instance --region $region --profile $profile
            validResp="1"
        elif [[ "$answer" == "N" || "$answer" == "n" ]]; then
            echo "Ok, exiting."
            exit 1
        else
            echo "Please reply with Y or N."
        fi
    done
  
    sleep 10 #give it 10 seconds before trying to delete the SG this instance used.
  fi
  
  #check for existing cafeSG security Group
  existingMpSg=$(aws ec2 describe-security-groups \
  --region $region \
  --query "SecurityGroups[?contains(GroupName, 'cafeSG')]" \
  --profile $profile | grep GroupId | cut -d '"' -f4)
  
  if [[ "$existingMpSg" != "" ]]; then
   echo
   echo "WARNING: Found existing security group with name "$existingMpSg"."
   echo "This script will not succeed if it already exists. "
   echo "Would you like to delete it? [Y/N]"
   echo ">>"
 
   validResp=0
   while [ $validResp -eq 0 ];
   do
       read answer
       if [[ "$answer" == "Y" || "$answer" == "y" ]]; then
           echo
           echo "Deleting the existing security group..."
           aws ec2 delete-security-group --group-id $existingMpSg --region $region --profile $profile
           validResp="1"
       elif [[ "$answer" == "N" || "$answer" == "n" ]]; then
           echo "Ok, exiting."
           exit 1
       else
           echo "Please reply with Y or N."
       fi
   done
   sleep 10 #give it 10 seconds before trying to recreate the SG
 fi

 # CREATE a security group and capture the name of it
 echo
 echo "Creating a new security group..."
 securityGroup=$(aws ec2 create-security-group --group-name "cafeSG" \
 --description "cafeSG" \
 --region $region \
 --group-name "cafeSG" \
 --vpc-id $vpc --profile $profile | grep GroupId | cut -d '"' -f4 )
 echo "Security Group: "$securityGroup
 
 # Open ports in the security group
 echo
 echo "Opening port 22 in the new security group"
 aws ec2 authorize-security-group-ingress \
 --group-id $securityGroup \
 --protocol tcp \
 --port 22 \
 --cidr 0.0.0.0/0 \
 --region $region \
 --profile $profile
 
 echo "Opening port 80 in the new security group"
 aws ec2 authorize-security-group-ingress \
 --group-id $securityGroup \
 --protocol tcp \
 --port 8080 \
 --cidr 0.0.0.0/0 \
 --region $region \
 --profile $profile
 
 echo
 echo "Creating an EC2 instance in "$region
 instanceDetails=$(aws ec2 run-instances \
 --image-id $imageId \
 --count 1 \
 --instance-type $instanceType \
 --region $region \
 --subnet-id $subnetId \
--security-group-ids $securityGroup \
 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cafeserver}]' \
 --associate-public-ip-address \
 --iam-instance-profile Name=LabInstanceProfile \
 --profile $profile \
 --user-data file://create-lamp-instance-userdata-v2.txt \
 --key-name $key )
 
 #if the create instance command failed, exit this script
 if [[ "$?" -ne "0" ]]; then
   exit 1
 fi
 
 echo
 echo "Instance Details...."
 echo $instanceDetails | python -m json.tool
 
 # Extract instanceId
 instanceId=$(echo $instanceDetails | python -m json.tool | grep InstanceId | sed -n 1p | cut -d '"' -f4)
 echo "instanceId="$instanceId
 echo
 echo "Waiting for a public IP for the new instance..."
 pubIp=""
 while [[ "$pubIp" == "" ]]; do
   sleep 10;
   pubIp=$(aws ec2 describe-instances --instance-id $instanceId --region $region --profile $profile | grep PublicIp | sed -n 1p | cut -d '"' -f4)
 done
 
 echo
 echo "The public IP of your LAMP instance is: "$pubIp
 echo
 echo "Download the Key Pair from the Vocareum page."
 echo
 echo "Then connect using this command (with .pem or .ppk added to the end of the keypair name):"
 echo "ssh -i path-to/"$key" ec2-user@"$pubIp
 echo
 echo "The website should also become available at"
 echo "http://"$pubIp"/cafe/"
 
 echo
 DATE=`date '+%Y-%m-%d %H:%M:%S'`
echo
 echo "Done running create-instance.sh at "$DATE
 echo 

run-instances