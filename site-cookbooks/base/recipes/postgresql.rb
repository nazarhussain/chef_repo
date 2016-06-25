#
# Cookbook Name:: base
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'apt'

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

# Set the global DB for db type
node.normal[:db_type] = 'postgresql'

normal_password = node[:postgresql][:password][:postgres]

# Check for the password
normal_password = secure_password unless normal_password

require('openssl')

# echo -n 'password''postgres' | openssl md5 | sed -e 's/.* /md5/'

db_pass = OpenSSL::Digest::MD5.digest("#{normal_password}postgres")
db_pass = "md5#{db_pass}"

node.default[:postgresql][:password][:postgres] = db_pass
node.save

# Install MySql
include_recipe 'postgresql::client'
include_recipe 'postgresql::server'

node.default[:postgresql][:password][:postgres] = normal_password
node.save


# Create and setup DB users
include_recipe 'database::postgresql'

db_users = node[:postgresql][:users].keys
db_connection = {
    :host => node.normal[:postgresql][:config][:listen_addresses],
    :port => node.normal[:postgresql][:config][:port],
    :username => 'postgres',
    :password => node.normal[:postgresql][:password][:postgres]
}

db_users.each do |db_user|
	postgresql_database_user db_user do
		connection db_connection
		password node[:postgresql][:users][db_user][:password]
		action :create
	end

	node[:postgresql][:users][db_user][:databases].each do |db|
		postgresql_database db do
			connection db_connection
			action :create
		end

		postgresql_database_user db_user do
			connection db_connection 
			database_name db 
			privileges [:all] 
			action :grant 
		end
	end
end