
m_config = node[:monit]

if m_config[:password].empty?
  Chef::Application.fatal!("Monit password attribute is required.")
end

monit 'monit' do
  daemon_interval  m_config[:interval]
  event_slots m_config[:event_slots]
  httpd_port m_config[:port]
  httpd_password m_config[:password]
  httpd_username m_config[:username]
  version '5.25.2'
end

directory '/etc/monit/conf.d' do
  recursive true
  action :delete
end

directory '/etc/monit/conf.d' do
  action :create
end

monit_config 'mail_server' do
  content <<-EOH
SET MAILSERVER #{m_config[:mail][:server]} PORT #{m_config[:mail][:port]}
USERNAME #{m_config[:mail][:username]} 
PASSWORD #{m_config[:mail][:password]}
USING tlsv1 WITH timeout 30 seconds
EOH
end

m_config[:mail][:recipients].each do |r|
  monit_config r do
    content "set alert #{r} not on { instance, action }  "
  end
end

# Setting default values
applications_root = node[:rails][:applications_root]
applications = node[:rails][:applications]

if applications
  monit_check 'nginx.service' do
    with 'with pidfile /var/run/nginx.pid'
    check 'if failed port 80 then restart'
    extra [ 'every 5 cycles',
            'group www' ]
  end
end

if applications
  applications.each do |app, app_info|

    rails_env = app_info['rails_env'] || "production"
    shared_path = "#{applications_root}/#{app}/shared"
    current_path = "#{applications_root}/#{app}/current"
    deploy_user = app_info['deploy_user']

    if !app_info['backend'].nil? and app_info['backend'] != true
      monit_check "#{app}_puma_master" do
        with "with pidfile #{shared_path}/pids/puma.pid"
        start_program "#{shared_path}/scripts/puma.sh start"
        stop_program "#{shared_path}/scripts/puma.sh stop"
        extra ["group #{app}" ]
      end

      (1..(app_info['number_of_workers'] || 2)).each do |i|
        index = i - 1

        monit_check "#{app}_puma_worker_#{index}" do
          with "with pidfile #{shared_path}/pids/puma_worker_#{index}.pid"
          start_program false
          stop_program false
          check "if cpu is greater than 70% for 5 cycles then exec \"#{shared_path}/scripts/puma.sh kill_worker #{index}\""
          extra ["group #{app}" ]
        end
      end
    end

    if app_info[:sidekiq]
      app_info[:sidekiq].each do |sidekiq_name, sidekiq_info|

        if sidekiq_info[:queues]
          monit_check "#{app}_sidekiq_#{sidekiq_name}" do
            with "with pidfile #{shared_path}/pids/sidekiq_#{sidekiq_name}.pid"
            start_program "#{shared_path}/scripts/sidekiq.sh start #{sidekiq_name} '--concurrency #{sidekiq_info[:concurrency] || 2} #{sidekiq_info[:queues].map{|q| " --queue #{q} "}.join(' ')} #{"--require #{sidekiq_info[:require]}" if sidekiq_info[:require]}'"
            stop_program "#{shared_path}/scripts/sidekiq.sh stop #{sidekiq_name}"
            check "if cpu is greater than 70% for 5 cycles then restart"
            extra ["group #{app}-sidekiq" ]
          end
        else sidekiq_info[:config]
          monit_check "#{app}_sidekiq_#{sidekiq_name}" do
            with "with pidfile #{shared_path}/pids/sidekiq_#{sidekiq_name}.pid"
            start_program "#{shared_path}/scripts/sidekiq.sh start #{sidekiq_name}"
            stop_program "#{shared_path}/scripts/sidekiq.sh stop #{sidekiq_name}"
            check "if cpu is greater than 70% for 5 cycles then restart"
            extra ["group #{app}-sidekiq" ]
          end
        end
      end
    end

    if app_info[:rake]
      app_info[:rake].each do |task|
        task_name = "rake_#{task.gsub(':', '_').downcase}"

        start_script = "/bin/su - #{deploy_user} -c 'cd #{current_path} && bundle exec rake #{task} RAILS_ENV=#{rails_env}'"

        stop_script = "/bin/ps aux | grep -ie 'rake #{task}' | awk '{print $2}' | xargs kill -9"

        monit_check "#{app}_#{task_name}" do
          with "matching 'rake #{task}' "
          start_program start_script.gsub(/[\n\s+]/,' ')
          stop_program stop_script.gsub(/[\n\s+]/,' ')
          check "if cpu is greater than 70% for 5 cycles then restart"
          extra ["group #{app}-rake" ]
        end
      end
    end

    if app_info[:scripts]
      app_info[:scripts].each do |script|
        app_info[:scripts].each do |script_name, script_info|
          monit_check "#{app}_script_#{script_name}" do
            with "with pidfile #{script_info[:pid]}"
            start_program "/bin/su - #{deploy_user} -c 'cd #{current_path} && #{script_info[:start_command]}'"
            stop_program "/bin/su - #{deploy_user} -c 'cd #{current_path} && #{script_info[:stop_command]}'"
            check "if cpu is greater than 70% for 5 cycles then restart"
            extra ["group #{app}-scripts" ]
          end
        end
      end
    end
  end
end