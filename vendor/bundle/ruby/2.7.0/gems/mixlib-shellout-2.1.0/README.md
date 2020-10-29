# Mixlib::ShellOut
Provides a simplified interface to shelling out yet still collecting both
standard out and standard error and providing full control over environment,
working directory, uid, gid, etc.

No means for passing input to the subprocess is provided.

## Example
Invoke find(1) to search for .rb files:

      find = Mixlib::ShellOut.new("find . -name '*.rb'")
      find.run_command

If all went well, the results are on `stdout`

      puts find.stdout

`find(1)` prints diagnostic info to STDERR:

      puts "error messages" + find.stderr

Raise an exception if it didn't exit with 0

      find.error!

Run a command as the `www` user with no extra ENV settings from `/tmp`

      cmd = Mixlib::ShellOut.new("apachectl", "start", :user => 'www', :env => nil, :cwd => '/tmp')
      cmd.run_command # etc.

## STDIN Example
Invoke crontab to edit user cron:

      # :input only supports simple strings
      crontab_lines = [ "* * * * * /bin/true", "* * * * * touch /tmp/here" ]
      crontab = Mixlib::ShellOut.new("crontab -l -u #{@new_resource.user}", :input => crontab_lines.join("\n"))
      crontab.run_command

## Windows Impersonation Example
Invoke "whoami.exe" to demonstrate running a command as another user:

      whoami = Mixlib::ShellOut.new("whoami.exe", :user => "username", :domain => "DOMAIN", :password => "password")
      whoami.run_command      

## Platform Support
Mixlib::ShellOut does a standard fork/exec on Unix, and uses the Win32
API on Windows. There is not currently support for JRuby.

## License
Apache 2 Licensed. See LICENSE for full details.

## See Also
* `Process.spawn` in Ruby 1.9
* [https://github.com/rtomayko/posix-spawn](https://github.com/rtomayko/posix-spawn)
