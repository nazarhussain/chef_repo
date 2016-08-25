name 'redis'
description 'Redis server for apps'
run_list "recipe[redisio]", "recipe[redisio::enable]"
default_attributes("redisio" => { "version" => "3.2.3", "name" => "-server", "default_settings" => {"maxmemory" => "500mb"}})