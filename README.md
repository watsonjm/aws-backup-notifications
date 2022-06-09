# README #

This Terraform code can be used to stand up a backup vault, some generic backup plans, and SNS topics for notifications from the backup plans. The backup plans will back up and EC2 instance or EBS volume (if you don't want the whole instance) with these 3 tag key-value pairs:
* backup_plan = Daily-35day-Retention
* backup_plan = Daily-Monthly-1yr-Retention
* backup_plan = Daily-Weekly-Monthly-5yr-Retention

AWS Backup Vault notifications is not visible in the console at this time, if you need to see it or change it, you will have to use [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

You must configure the tags on resources yourself, this code will create the backup resources, but not assign them.

### How do I get set up? ###

* [Download Terraform](https://www.terraform.io/downloads)
    1. Terraform is a simple executable that needs to be in your [PATH](https://docs.microsoft.com/en-us/previous-versions/office/developer/sharepoint-2010/ee537574(v=office.14)). If you want to install it instead, you can follow the [instructions here](https://learn.hashicorp.com/tutorials/terraform/install-cli).
* You'll need an AWS Access Key ID and AWS Secret Access Key for each AWS account where you plan to use this. These 2 variables will need to be updated locally before running in a new AWS account.
    1. [runme/env_vars](/runme/env_vars) shows how to set up these variables for PowerShell or Bash.
    2. You can also accomplish all of this by [installing AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), but that is more complicated for this particular scenario.
* Once you have your AWS credential in environment variables, you can run ```terraform init```, ```terraform plan```, and ```terraform apply```. The exact commands needed are in [runme/runme_temp](/runme/runme_temp). This will initialize terraform, then the plan will show you what it wants to do, and if you like the plan, then you can apply it.
* After the ```terraform apply``` is ran, you will have a new file called terraform.tfstate. This is how Terraform keeps track of everything it has done for the specific environment where it did it. You will either need to rename this file per-account, or just delete it. Normally this file is extremely important for Terraform, but since this repo is basically fire-and-forget, and nothing else is managed via Terraform, we can safely delete it (if the environment actually IS managed by Terraform, contact [John Watson](mailto:jwatson@resultant.com) for help if needed).

### Who do I talk to? ###

* [Richard Cooper](mailto:rcooper@resultant.com)
* [John Watson](mailto:jwatson@resultant.com)
