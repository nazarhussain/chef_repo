name 'ruby'
description 'Install the specific versions of ruby'
run_list 'recipe[build-essential::default]', 'recipe[base::ruby]'
default_attributes("ruby" => { "version" => "1.9.3-p448"}, "rbenv" => {"git_repository" => "https://github.com/rbenv/rbenv.git"})