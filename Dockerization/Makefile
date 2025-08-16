AWS_REGION=ap-south-1
FLASK_IMAGE_NAME=flask-backend
EXPRESS_IMAGE_NAME=express-frontend

.PHONY: build push deploy destroy

# Build Docker Images
build:
	docker build -t ${FLASK_IMAGE_NAME} ./flask-app
	docker build -t ${EXPRESS_IMAGE_NAME} ./express-app

# Push to ECR
push:
	aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin $$(aws sts get-caller-identity --query "Account" --output text).dkr.ecr.${AWS_REGION}.amazonaws.com
	docker tag ${FLASK_IMAGE_NAME}:latest $$(aws sts get-caller-identity --query "Account" --output text).dkr.ecr.${AWS_REGION}.amazonaws.com/${FLASK_IMAGE_NAME}:latest
	docker push $$(aws sts get-caller-identity --query "Account" --output text).dkr.ecr.${AWS_REGION}.amazonaws.com/${FLASK_IMAGE_NAME}:latest

	docker tag ${EXPRESS_IMAGE_NAME}:latest $$(aws sts get-caller-identity --query "Account" --output text).dkr.ecr.${AWS_REGION}.amazonaws.com/${EXPRESS_IMAGE_NAME}:latest
	docker push $$(aws sts get-caller-identity --query "Account" --output text).dkr.ecr.${AWS_REGION}.amazonaws.com/${EXPRESS_IMAGE_NAME}:latest

# Deploy Terraform
deploy:
	cd terraform && terraform init
	cd terraform && terraform apply -auto-approve

#Destroy Terraform
destroy:
	cd terraform && terraform destroy -auto-approve
