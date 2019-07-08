
# Install dependent packages
packages = %w(autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev)

packages.each do |package|
  package package
end

# Install the rbenv
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

# Install ruby
rbenv_ruby node["ruby"]["version"] do 
	global true
end

# Install bundler to be used for application packages
rbenv_gem "bundler" do
  ruby_version node["ruby"]["version"]
end