# DevOps Labs
This repo holds a serie of basic cloud architecture used mostly to guide newbies around cloud architecture

Check the README.md inside each directory to see a reference of each architecture.

## Dependencies
These examples expect you to have installed [terraform](https://www.terraform.io/) locally. Although [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) is not required you might need it to troubleshoot things.

You also gonna need a IAM user configured with CLI access. For now this expects this user to have admin powers.
>If this becomes sustainable I might be able to identify all the required IAM actions to be able to run each example🙏🏾. For now ensure no one will have access to your user credentials ⚠️

## Using the examples
If you wanna check the results of running the examples, you can execute `terraform plan` locally to see the resources the example would create. Just ensure you have the proper [AWS environment variables configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) on your environment.🏾


# Roadmap
- [x] Create an EC2 with Apache and a static page  
- [x] Create a Custom VPC with 1 public subnet and a simple static page on Apache
- [x] Host a Wordpress site on a single EC2 machine
- [x] Split the Wordpress between a web-server on the public subnet and move the database to an EC2 machine in a private subnet
- [ ] Replace the Wordpress ec2 database with RDS and use SSM Parameter Store to host the secrets
- [ ] Use 2 AZs
- [ ] Dockerize and use ECS
- [ ] Move the secrets to AWS Secrets Manager
- [ ] Use Kubernetes and AWS EKS