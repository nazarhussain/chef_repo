
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

  end
end