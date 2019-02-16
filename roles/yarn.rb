name 'yarn'
description 'Install configure yarn package manager'
run_list "recipe[yarn::default]"
default_attributes("yarn" => { "package" => { "upgrade" => true}})