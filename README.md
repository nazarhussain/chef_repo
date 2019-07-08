# Chef Repo
## Ruby on Rails VPS - production environment recipe  

This repo contains pre-configured and generalized set of Chef recipes that can help you to setup a production environment VPS for any Ruby on Rails application. 

### Getting Started 

Use the following code below to clone the repo on your local machine and install dependencies.   

```sh
git clone git@github.com:nazarhussain/chef_repo.git
cd che_repo 
rmv use 2.4
bundle install
bundle exec berks install 
```

### How to setup VPS
To setup any server you need to run following command. 

```sh
bundle exec knife solo prepare root@<ip>
```
This step will create a file `nodes/<ip>.json` file. This is the file where you want to specify how you want to configure your VPS. 
Once you had done specifying every detail of the server in that JSON file. Then run the following command.
Keep that JSON file saved and backup, as it will contain the passwords you specify for different components. 

**Never commit that JSON file to any version control.**    

```sh
bundle exec knife solo cook root@ip
```

### Components 
Following components will be setup on your VPS with following Chef recipes.


Component | Version | Definition
|---|---|---|
| rbenv | Latest | Ruby version manager
| Ruby | * | MRI standard ruby. 
| PostgresSQL | * | Database server
| NodeJS | * | For NPM dependencies and sprockets
| OpenJDK | Latest | For compile time dependencies
| Monit | Latest | For process monitoring   

`*` Can be specified in JSON file

### How to test with Docker  

You can run your VPS configuration file against a local docker to test it. 

```sh
docker pull ubuntu      # Pull Ubuntu container 
docker run --name chef-repo ubuntu:bionic
```


1. Install Vagrant
2. Run `vagrant up`
3. Run `vagrant ssh-config`
4. Put vagrant config to ~/.ssh/config
5. Run `knife solo prepare vagrant`
6. Run `knife solo cook vagrant`

### Components 
Here is the list of each component you can specify in the JSON config file. For each component there is a role attached. So you have to add that role to `run_list` to execute. Your JSON configuration looks like something. 

```json5
{
  "run_list":[],
  "automatic": {
    "ipaddress": "ip"
  }
}
```
What ever component you choose from below, you have to add it to `run_list` and also specify its configuration if required. e.g. If you want to add **ruby** component. Your JSON file should look like something. 
```json5
{
  "run_list":["role[ruby]"],
  
  "ruby": {
    "version": "2.4.5"  // Version of Ruby to user on the server
  },
  
  "automatic": {
    "ipaddress": "ip"
  }
}
```

For the list of components, please look for the this [sample file](docs/specs.json5)  

## Troubleshooting

** Invalid Checksum Error with Nosdejs **

If faced invalid checksum error, use follwoing config 

```
"nodejs": {
    "version": "6.12.0",
    "binary": {
      "checksum": "f011ba"
    }
  },
```
and visit https://nodejs.org/dist/v<version_number>/SHASUMS256.txt.asc to cehck valid cehcksum and put in your config files. 