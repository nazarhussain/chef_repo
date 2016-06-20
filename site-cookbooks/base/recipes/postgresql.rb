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

db_pass = node[:postgresql][:password]

# Check for the password
db_pass = secure_password unless db_pass

# require('openssl')
#
# db_pass = OpenSSL::Digest::MD5.digest("#{db_pass}postgres")
#
# puts '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
# puts db_pass
# puts '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'

node.normal[:postgresql][:password] = {:postgres => db_pass}

# Install MySql
include_recipe 'postgresql::client'
include_recipe 'postgresql::server'


# Create and setup DB users
include_recipe 'database::postgresql'

db_users = node[:postgresql][:users].keys
db_connection = {
    :host => node.normal[:postgresql][:config][:listen_addresses],
    :port => node.normal[:postgresql][:config][:port],
    :username => 'postgres',
    :password => db_pass
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