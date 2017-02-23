#
# Cookbook Name:: base
# Recipe:: rails
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'nginx'

# Setting default values
applications_root = node[:rails][:applications_root]
applications = node[:rails][:applications]

# Installing application specifc packages
if applications
  applications.each do |app, app_info|
    if app_info['packages']
      packages = app_info['packages']
      packages = packages.split(' ') if packages.is_a? String
      packages.each do |package|
        package package
      end
    end
  end
end


# Setting up applications
if applications
  applications.each do |app, app_info|
    rails_env = app_info['rails_env'] || "production"
    deploy_user = app_info['deploy_user']
    app_env = app_info['env'].dup || {}
    app_env['RAILS_ENV'] = rails_env

    sys_env_file = Chef::Util::FileEdit.new('/etc/environment')
    app_env.each do |name, val|
      sys_env_file.insert_line_if_no_match /^#{name}\=/, "#{name}=\"#{val}\""
      sys_env_file.write_file
    end

    directory "#{applications_root}/#{app}" do
      recursive true
      group deploy_user
      owner deploy_user
    end

    ['config', 'shared', 'shared/config', 'shared/sockets', 'shared/pids', 'shared/cache', 'shared/log', 'shared/system', 'shared/scripts', 'shared/tmp', 'releases'].each do |dir|
      directory "#{applications_root}/#{app}/#{dir}" do
        recursive true
        group deploy_user
        owner deploy_user
      end
    end

    ['sockets', 'pids', 'cache'].each do |dir|
      link "#{applications_root}/#{app}/shared/tmp/#{dir}" do
        to "#{applications_root}/#{app}/shared/#{dir}"
        link_type :symbolic
      end
    end

    # Load default information by convention
    db_info = {}.merge(app_info['database_info'] || {})
    if db_info
      if node[:db_type] == 'mysql'
        db_info['adapter'] = 'mysql2'
        db_info['host'] = node[:mysql][:bind_address] unless db_info['host']
        db_info['username'] = node[:mysql][:users].map{|user, info| user if info[:databases].include?(db_info['database']) }.reject{|a| a.nil?}.first unless db_info['username']
        db_info['password'] = node[:mysql][:users].map{|user, info| info[:password] if info[:databases].include?(db_info['database']) }.reject{|a| a.nil?}.first unless db_info['password']
        db_info['pool'] = 5 unless db_info['pool']
        db_info['timeout'] = 5000 unless db_info['timeout']
      end

      if node[:db_type] == 'postgresql'
        db_info['adapter'] = 'postgresql'
        db_info['host'] = node[:postgresql][:config][:listen_addresses] unless db_info['host']
        db_info['username'] = node[:postgresql][:users].map{|user, info| user if info[:databases].include?(db_info['database']) }.reject{|a| a.nil?}.first unless db_info['username']
        db_info['password'] = node[:postgresql][:users].map{|user, info| info[:password] if info[:databases].include?(db_info['database']) }.reject{|a| a.nil?}.first unless db_info['password']
        db_info['pool'] = 5 unless db_info['pool']
        db_info['timeout'] = 5000 unless db_info['timeout']
      end

      # Creating database.yml
      template "#{applications_root}/#{app}/shared/config/database.yml" do
        owner deploy_user
        group deploy_user
        mode 0600
        source "database.yml.erb"
        variables :database_info => db_info, :rails_env => rails_env
      end
    end

    if !app_info['backend'].nil? and app_info['backend'] != true

      ssl_extras = []
      enable_ssl = false
      reset_redis = app_info['reset_redis'] || false
      redirect_to_https = false

      # Loading up SSL Information
      if app_info['ssl_info']
        template "#{applications_root}/#{app}/shared/config/certificate.crt" do
          owner deploy_user
          group 'developers'
          mode 0644
          source "app_cert.crt.erb"
          variables :app_crt=> app_info['ssl_info']['crt']
        end

        template "#{applications_root}/#{app}/shared/config/certificate.key" do
          owner deploy_user
          group 'developers'
          mode 0644
          source "app_cert.key.erb"
          variables :app_key=> app_info['ssl_info']['key']
        end

        enable_ssl = true
        ssl_extras = app_info['ssl_info']['extras'] || []
        nginx_extras = app_info['nginx_extras'] || []
        redirect_to_https = app_info['ssl_info']['redirect_to_https'] || false
      end


      # Enable and set the Nginx
      template "/etc/nginx/sites-available/#{app}.conf" do
        source "app_nginx.conf.erb"
        variables :name => app,
                  :domain_names => app_info['domain_names'],
                  :applications_root=> applications_root,
                  :enable_ssl => enable_ssl,
                  :ssl_extras => ssl_extras,
                  :nginx_extras => nginx_extras,
                  :redirect_to_https => redirect_to_https
        notifies :reload, resources(:service => "nginx")
      end

      # Setting up puma configuration
      template "#{applications_root}/#{app}/shared/config/puma.rb" do
        mode 0644
        source "app_puma.rb.erb"
        variables(
          :name => app,
          :rails_env=>rails_env,
          :deploy_user => deploy_user,
          :applications_root=> applications_root,
          :number_of_workers => app_info['number_of_workers'] || 2,
          :min_threads => app_info['min_threads'] || 3,
          :max_threads => app_info['max_threads'] || 10,
          :reset_redis => reset_redis
        )
      end

      # Setting up puma startup script
      template "#{applications_root}/#{app}/shared/scripts/puma.sh" do
        mode 0750
        source "app_puma.sh.erb"
        variables(
            :name => app,
            :rails_env=>rails_env,
            :deploy_user => deploy_user,
            :applications_root=> applications_root,
            :number_of_workers => app_info['number_of_workers'] || 2,
            :min_threads => app_info['min_threads'] || 3,
            :max_threads => app_info['max_threads'] || 10
        )
      end

      nginx_site 'default' do
        action :disable
        enable false
      end

      nginx_site "#{app}.conf" do
        action :enable
        enable true
      end
    end

    logrotate_app "#{app}" do
      cookbook "logrotate"
      path ["#{applications_root}/#{app}/current/log/*.log"]
      frequency "daily"
      rotate 14
      compress true
      create "644 #{deploy_user} #{deploy_user}"
    end
  end
end