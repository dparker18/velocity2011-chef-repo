Welcome to Velocity 2011!

This repository is used in the Infrastructure Automation with Opscode Chef workshop.

Getting Started
====

Prior to this workshop, we sent out installation instructions to help you get started. You should be done with the Getting Started portion of the Opscode Help Site Knowledge Base and have the following:

* Ruby, Chef and knife plugins for EC2 and Rackspace installed.
* Your user private key file.
* An organization created in the Opscode Hosted Chef server.
* The organization validation client private key file.

Your key files should be located in ~/.chef. This repository uses a `knife.rb` that is configured to search for them there.

Environment Setup
====

Some environment variables should be exported prior to using the knife configuration in this repository.

    export ORGNAME="your_organization_name"
    export OPSCODE_USER="your_opscode_username" # if different than your local username

The demonstration portion will use Amazon AWS EC2. If you want to follow along using the same commands:

    export AWS_ACCESS_KEY_ID="amazon aws access key id"
    export AWS_SECRET_ACCESS_KEY="amazon aws secret access key"

Optionally if you are using Rackspace Cloud instead of AWS, export the following and check `knife rackspace server create -h` for options you'll need to use to modify the EC2 commands.

    export RACKSPACE_API_KEY="rackspace cloud api key"
    export RACKSPACE_API_USERNAME="rackspace cloud api username"

You'll work from the velocity2011-chef-repo directory you cloned from GitHub.

AWS SSH Keypair
====

The demonstration uses a pregenerated SSH keypair in AWS. You can generate a keypair in the AWS console, or with HybridFox in Firefox, or through the EC2 command-line tools. This is different than the demonstration `velocity` user (described below), and is used to log into the target systems as the `ubuntu` user for the initial Chef bootstrap.

The example commands will use a key named `velocity-2011-aws`. You can name this anything you like, but it has to be reflected in the knife ec2 commands.

Set up Velocity User
====

We set up a `velocity` user in a data bag item as part of the demonstration. You'll need to generate an SSH keypair and modify the user item with the public key.

    ssh-keygen -f ~/.ssh/velocity2011-demo.pem

Then modify the data bag. It contains a placeholder string that we can easily replace.

    perl -pi -e "s#SSH_PUB_KEY#$(cat ~/.ssh/velocity2011-demo.pem.pub)#" data_bags/users/velocity.json

The data bag item has a htauth password for Nagios webui set. The login is:

    Username: velocity
    Password: velocity2011

You can generate a new SHA password with htpasswd on your workstation (if you have htpasswd)

    htpasswd -n -s velocity

Copy the `{SHA}...` string and replace the field in the data bag item, then reupload it to the Chef Server.

     knife data bag from file users velocity.json

Upload Repository
====

Perform the following commands to upload everything in the repository to the Opscode Hosted Chef server.

    knife cookbook upload -a
    rake roles
    rake databag:upload_all
    knife environment from file production.rb
    knife environment from file staging.rb

Launch Infrastructure
====

We're going to launch several instances in Amazon EC2 to run our basic infrastructure. At the end, we'll have several "production" instances running:

* Ubuntu 10.04 with base AMIs from Canonical.
* Nagios - we want to monitor our production infrastructure.
* Load balancer - haproxy load balancer in front of our application.
* 3 front end web servers - running mediawiki.
* 1 database master - running mysql.

We've kept it simple, but easy to expand upon. The workshop will discuss how we might expand and integrate new systems and services.

Amazon EC2
----

Launch the infrastructure in Amazon EC2 with the following commands:

    knife ec2 server create -G default -I ami-e4d42d8d -f m1.small \
      -S velocity-2011-aws -i ~/.ssh/velocity-2011-aws.pem -x ubuntu \
      -E production -r 'role[base],role[monitoring]'

    knife ec2 server create -G default -I ami-e4d42d8d -f m1.small \
      -S velocity-2011-aws -i ~/.ssh/velocity-2011-aws.pem -x ubuntu \
      -E production -r 'role[base],role[mediawiki_database_master]'

    knife ec2 server create -G default -I ami-e4d42d8d -f m1.small \
      -S velocity-2011-aws -i ~/.ssh/velocity-2011-aws.pem -x ubuntu \
      -E production -r 'role[base],role[mediawiki],recipe[mediawiki::db_bootstrap]'

    # optional if you want to see load balancing
    knife ec2 server create -G default -I ami-e4d42d8d -f m1.small \
      -S velocity-2011-aws -i ~/.ssh/velocity-2011-aws.pem -x ubuntu \
      -E production -r 'role[base],role[mediawiki]'

    knife ec2 server create -G default -I ami-e4d42d8d -f m1.small \
      -S velocity-2011-aws -i ~/.ssh/velocity-2011-aws.pem -x ubuntu \
      -E production -r 'role[base],role[mediawiki_load_balancer]'

Finally, we'll also launch a single instance for our "staging" environment with the full application stack. We don't need a load balancer here as it's just one system.

    knife ec2 server create -G default -I ami-e4d42d8d -f m1.small \
      -S velocity-2011-aws -i ~/.ssh/velocity-2011-aws.pem -x ubuntu -E staging \
      -r 'role[base],role[mediawiki_database_master],role[mediawiki],recipe[mediawiki::db_bootstrap]'

Rackspace Cloud
----

Launch the infrastructure in Rackspace Cloud with the following commands.

    knife rackspace server create --flavor 2 --image 49 \
      -E production -r 'role[base],role[monitoring]'

    knife rackspace server create --flavor 2 --image 49 \
      -E production -r 'role[base],role[mediawiki_database_master]'

    knife rackspace server create --flavor 2 --image 49 \
      -E production -r 'role[base],role[mediawiki],recipe[mediawiki::db_bootstrap]'

    # optional if you want to see load balancing
    knife rackspace server create --flavor 2 --image 49 \
      -E production -r 'role[base],role[mediawiki]'

    knife rackspace server create --flavor 2 --image 49 \
      -E production -r 'role[base],role[mediawiki_load_balancer]'

Finally, we'll also launch a single instance for our "staging" environment with the full application stack. We don't need a load balancer here as it's just one system.

    knife rackspace server create --flavor 2 --image 49 -E staging \
      -r 'role[base],role[mediawiki_database_master],role[mediawiki],recipe[mediawiki::db_bootstrap]'

Custom Report Handler
====

We have a cookbook called `chef_handler` that can be used to drop off custom report/exception handlers. We have one to work with MediaWiki's API, in the `mediawiki::api_update` recipe. Let's add this recipe to the nodes with role `mediawiki` in production. Then run Chef on them:

    knife exec -E 'nodes.transform("role:mediawiki AND chef_environment:production") {|n| n.run_list << "recipe[mediawiki::api_update]"}'
    knife ssh 'role:mediawiki AND chef_environment:production' -x velocity -i ~/.ssh/velocity2011-demo.pem -a cloud.public_hostname 'sudo chef-client'

Then visit the URL of the Load Balancer. It will display the `Main_Page` of MediaWiki with a link to the last Chef run status, as well as a link to a static HTML page with general node information.

Decommissioning Nodes
====

Use knife to decommission nodes at the cloud provider level and on the Opscode Hosted Chef server. The knife commands used above will create nodes and clients named after the API-assigned cloud instance ID. This will be something like:

* Amazon EC2: i-f948d297
* Rackspace Cloud: 20030026

Get a list of nodes, clients and cloud instances with knife:

    knife node list
    knife client list
    knife ec2 server list
    knife rackspace server list

To delete the instance from the cloud provider, use the appropriate command:

    knife ec2 server delete i-f948d297
    knife rackspace server delete 20030026

This will display information about the instance and ask for confirmation to delete. This does not delete the node or the client data from the Opscode Hosted Chef server. That is done separately because Chef doesn't know whether you might want to keep that data for historical or reporting purposes. To delete the node and client data, use knife:

    knife node delete i-f948d297
    knife client delete i-f948d297

If you delete a node from the Chef server, then you'll want to run chef-client again on nodes that may have it in their configuration, such as the Nagios monitoring server or the load balancer.

    knife ssh 'role:monitoring OR role:mediawiki_load_balancer' -x velocity -i ~/.ssh/velocity2011-demo.pem -a cloud.public_hostname 'sudo chef-client'

License and Author
====

Author:: Joshua Timberman (<joshua@opscode.com>)

Copyright:: 2011, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
