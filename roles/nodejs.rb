name 'yarn'
description 'Install configure nodejs'
run_list "recipe[nodejs::nodejs_from_binary]"
default_attributes("nodejs" => { "version" => "8.9.3"})