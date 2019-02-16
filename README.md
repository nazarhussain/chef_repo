

```
bundle install
bundle exec berks install
bundle exec knife solo prepare root@ip 
bundle exec knife solo cook root@ip 
```
To test

1. Intall Vagrant
2. Run `vagrant up`
3. Run `vagrant ssh-config`
4. Put vagrant config to ~/.ssh/config
5. Run `knife solo prepare vagrant`
6. Run `knife solo cook vagrant`


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