# koha-xslt-from-github

Automate grabbing xslt files from GitHub to store and use locally

This script is meant to be used with the koha-foreach command. For each site it will look in github for a matching branch in the format v<major_version>.<minor_version>/<koha_instance_name>. If it does not it exist, it will do nothing. If it does exist, it will copy the xsl files from the repo to /var/lib/koha/<koha_instance_name> and update the xslt system preferences to point to the files.

This script only uses libraries already used by Koha, so no external dependencies are needed.

If you are not using ByWater's repos ( and you probably aren't ) you'll want to modify this script.

# Usage

`update-xslt-from-github --confirm --verbose`

## Options
```
-c --confirm: Run in production mode
-v --verbose: Extra output for debugging
-s --shortname: Set the shortname to be used for looking for the repo in GitHub, defaults to the Koha instance name
-t --target: Set the instance of Koha on this server to operate on, defaults to the value of --shortname
-r --repo: Set the github repo to look for xslt files in, defaults to bywatersolutions/bywater-koha-xslt
```

If none of the following are set, all will be used. If one or more are set, only those specified will be used.

```
--opacdetails: Set the opac details xslt file.
--opacresults: Set the opac results xslt file.
--opaclists: Sets the opac lists xslt to the same file as opac results. If a file URL is specified, use that instead
--staffdetails: Set the staff details xslt file.
--staffresults: Set the staff results xslt file.
--stafflists: Sets the staff lists xslt to the same file as staff results. If a file URL is specified, use that instead
````

Running without `--confirm` will run the script in test mode. Verbosity is forced in test mode.

Crontab example:
`@hourly instancename-koha /path/to/koha-xslt-from-github/update-xslt-from-github --confirm`
