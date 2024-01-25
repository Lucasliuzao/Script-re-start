#Crie um balanceador de carga de aplicativo
aws elbv2 create-load-balancer \ 
--name my-load-balancer \ 
--subnets subnet-12345678 subnet-23456789 \ 
--security-groups sg-12345678

#Criar um grupo de destino para o load balancer
aws elbv2 create-target-group \ 
--name my-targets \ 
--protocol HTTP \ 
--port 80 \ 
--vpc-id vpc-12345678

#Registrar instâncias do EC2 no grupo de destino
aws elbv2 register-targets \ 
--target-group-arn targetgroup-arn \ 
--targets Id=i-12345678 Id=i-23456789

#Criar um ouvinte para o balanceador de carga
aws elbv2 create-listener \ 
--load-balancer-arn loadbalancer-arn \
--protocol HTTP \ 
--port 80 \ 
--default-actions
Type=forward,TargetGroupArn=targetgroup-arn 

#Verificar a integridade dos destinos registrados
aws elbv2 describe-target-health 
--target-group-arn targetgroup-arn


