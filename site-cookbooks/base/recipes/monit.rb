
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

    monit_check "#{app}_puma_master" do
      with "with pidfile #{applications_root}/#{app}/shared/pids/puma.id"
      start_program "#{applications_root}/#{app}/shared/scripts/puma.sh start"
      stop_program "#{applications_root}/#{app}/shared/scripts/puma.sh stop"
      extra ['group developers' ]
    end

    (1..(app_info['number_of_workers'] || 2)).each do |i|
      index = i - 1

      monit_check "#{app}_puma_#{index}" do
        with "with pidfile #{applications_root}/#{app}/shared/pids/puma_#{index}.id"
        start_program false
        stop_program false
        check "if cpu is greater than 80% for 5 cycles then exec \"#{applications_root}/#{app}/shared/scripts/puma.sh kill_worker #{index}\""
      end
    end
  end
end