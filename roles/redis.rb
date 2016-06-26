name 'redis'
description 'Redis server for apps'
run_list "recipe[redisio]", "recipe[redisio::enable]"
default_attributes("redisio" => { "version" => "2.8.7", "name" => "-server"})