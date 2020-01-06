LDAP configuration

We have created an ldap test user called `john` with password `123456`.

Packages for use:

| role   |  debian packages  |
|--------|-------------------|
| server | slapd, ldap-utils |
| client | nscd, libnss-ldap |

LDAP server is installed on the manage node.  We use `dc=cluster,dc=local` as the domain name. The password of `admin` is set to `abc`. The content of `add_content.ldif`
is in this repository, to be used like this:
```
ldapadd -x -D cn=admin,dc=cluster,dc=local -W -f add_content.ldif
```

When you install `libnss-ldap` for client, the configuration will pop out automatrically, fill in ldap server address: `ldap://10.8.15.136`; Then modify `/etc/nsswitch.conf` to add `ldap` authentication.
```
passwd:         files systemd ldap
group:          files systemd ldap
```
Afterwards, run `sudo pam-auth-update` to add the functionality to auto create the home directory for LDAP users.