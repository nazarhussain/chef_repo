name 'mysql'
description 'MySQL server for apps'
run_list "recipe[base::postgresql]"
default_attributes("postgresql" => { "version" => "9.4", "config" =>{ "listen_addresses" => "127.0.0.1", "port" => 5432 }})