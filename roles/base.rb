name 'base'
description 'Base bootstrap for every box'
run_list "recipe[build-essential]", "recipe[base]"
default_attributes(
  "base" => {    
    "users" => ["deploy"]
  }
)