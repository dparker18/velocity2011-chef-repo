name "base"
description "Base role applied to all nodes."
run_list(
  "recipe[apt]",
  "recipe[zsh]",
  "recipe[users::sysadmins]",
  "recipe[sudo]",
  "recipe[git]",
  "recipe[build-essential]",
  "recipe[nagios::client]"
)
override_attributes(
  :authorization => {
    :sudo => {
       :users => ["ubuntu"],
       :passwordless => true
     }
   },
   :nagios => {
     :server_role => "monitoring"
   }
)
