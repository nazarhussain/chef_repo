#
# Cookbook Name:: base
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# Create Users
node[:base][:users].each do |deploy_user|
	user deploy_user do
		comment "Deployment User #{deploy_user}"
		home "/home/#{deploy_user}"
		shell "/bin/bash"
		supports(:manage_home => true )
	end
end

# Create Group
group 'developers' do
	members node[:base][:users]
end	

# Create/Setup SSH access keys
if node[:base][:keys]
	node[:base][:users].each do |deploy_user|
		directory "/home/#{deploy_user}/.ssh" do
			mode 0700
			owner deploy_user
			group 'developers'
		end

		template "/home/#{deploy_user}/.ssh/authorized_keys" do
			source "authorized_keys.erb"
			mode 0600
			owner deploy_user
			group 'developers'
			variables :keys => node[:base][:keys]
		end
	end
end

# Setup users to have sudo powers
node.normal[:authorization] = {
	:sudo =>{
		:users => node.normal[:base][:users].to_a << 'vagrant' ,
		"groups" => ["developers"],
		"passwordless" => true,
		"include_sudoers_d" => true,
		"sudoers_default" => [
			'env_reset',
			'secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"'
		]
	}
}
include_recipe "sudo"

packages = node.normal[:base][:packages]

if packages.is_a? String
	packages = packages.split(' ')
end

packages.each do |package|
	package package
end