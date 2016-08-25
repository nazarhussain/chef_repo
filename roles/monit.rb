name 'monit'
description 'Install and configure the monit'
run_list 'recipe[base::monit]'
default_attributes(
    monit: {
        interval: 60,
        event_slots: 0,
        port: 2812,
        username: 'monit',
        password: '',
        email: {
        	server: '',
        	port: '',
        	username: '',
        	password: '', 
        	recipients: ''
        }
    }
)
