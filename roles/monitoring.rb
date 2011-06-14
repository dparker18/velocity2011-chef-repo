name "monitoring"
description "Monitoring Server"
run_list(
         "recipe[nagios::server]"
         )

default_attributes(
                   "nagios" => {
                     "server_auth_method" => "htauth"
                   }
                   )
