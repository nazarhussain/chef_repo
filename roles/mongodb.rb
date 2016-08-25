name 'mongodb'
description 'Mongodb server for apps'
run_list 'recipe[mongodb3::default]'
default_attributes({'mongodb3' => {
    'version' => '3.2.9',
    'config' => {
        'mongod' => {
            'net' => {
                'bindIp' => '127.0.0.1'
            }
        }
    }
}})