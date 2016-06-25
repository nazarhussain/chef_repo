
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
  provider :system
end

# Setting default values
applications_root = node[:rails][:applications_root]
applications = node[:rails][:applications]

if applications
  monit_check 'nginx' do
    check 'if failed port 80 protocol http request "/" then restart'
    extra [ 'every 5 cycles',
            'group www' ]
  end
end

if applications
  applications.each do |app, app_info|

    rails_env = app_info['rails_env'] || "production"
    shared_path = "#{applications_root}/#{app}/shared"
    current_path = "#{applications_root}/#{app}/current"

    monit_check "#{app}_puma_master" do
      with "with pidfile #{shared_path}/pids/puma.id"
      start_program "#{shared_path}/scripts/puma.sh start"
      stop_program "#{shared_path}/scripts/puma.sh stop"
      extra ['group developers' ]
    end

    (1..(app_info['number_of_workers'] || 2)).each do |i|
      index = i - 1

      monit_check "#{app}_puma_worker_#{index}" do
        with "with pidfile #{shared_path}/pids/puma_worker_#{index}.id"
        start_program false
        stop_program false
        check "if cpu is greater than 70% for 5 cycles then exec \"#{shared_path}/scripts/puma.sh kill_worker #{index}\""
      end
    end

    if app_info[:sidekiq]
      app_info[:sidekiq].each do |sidekiq_name, sidekiq_info|
        start_script = <<-EOS
          /bin/bash -l -c 'cd #{current_path} && bundle exec sidekiq
          --index 0
          --pidfile #{shared_path}/pids/sidekiq_#{sidekiq_name}.pid
          --environment #{rails_env}
          --logfile #{shared_path}/log/sidekiq_#{sidekiq_name}.log
          #{sidekiq_info[:queues].map{|q| " --queue #{q} "}.join(' ')}
          #{"--require #{sidekiq_info[:require]}" if sidekiq_info[:require]}
          --daemon
        EOS

        stop_script = <<-EOS
          /bin/bash -l -c 'cd #{current_path} && bundle exec sidekiqctl stop #{shared_path}/pids/sidekiq_#{sidekiq_name}.pid 15
        EOS

        monit_check "#{app}_sidekiq_#{sidekiq_name}" do
          with "with pidfile #{shared_path}/pids/sidekiq_#{sidekiq_name}.pid"
          start_program start_script.gsub(/[\n|\s+]/,' ')
          stop_program stop_script.gsub(/[\n|\s+]/,' ')
          check "if cpu is greater than 70% for 5 cycles then restart"
        end
      end
    end
  end
end