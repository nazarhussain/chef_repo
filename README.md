

```
bundle install
librarina-chef install
knife solo prepare root@ip 
knife solo cook root@ip 
```
To test

1. Intall Vagrant
2. Run `vagrant up`
3. Run `vagrant ssh-config`
4. Put vagrant config to ~/.ssh/config
5. Run `knife solo prepare vagrant`
6. Run `knife solo cook vagrant`