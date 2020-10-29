# posix-spawn

`fork(2)` calls slow down as the parent process uses more memory due to the need
to copy page tables. In many common uses of fork(), where it is followed by one
of the exec family of functions to spawn child processes (`Kernel#system`,
`IO::popen`, `Process::spawn`, etc.), it's possible to remove this overhead by using
special process spawning interfaces (`posix_spawn()`, `vfork()`, etc.)

The posix-spawn library aims to implement a subset of the Ruby 1.9 `Process::spawn`
interface in a way that takes advantage of fast process spawning interfaces when
available and provides sane fallbacks on systems that do not.

### FEATURES

 - Fast, constant-time spawn times across a variety of platforms.
 - A largish compatible subset of Ruby 1.9's `Process::spawn` interface and
   enhanced versions of `Kernel#system`, <code>Kernel#`</code>, etc. under
   Ruby >= 1.8.7 (currently MRI only).
 - High level `POSIX::Spawn::Child` class for quick (but correct!)
   non-streaming IPC scenarios.

## BENCHMARKS

The following benchmarks illustrate time needed to fork/exec a child process at
increasing resident memory sizes on Linux 2.6 and MacOS X. Tests were run using
the [`posix-spawn-benchmark`][pb] program included with the package.

[pb]: https://github.com/rtomayko/posix-spawn/tree/master/bin

### Linux

![](https://chart.googleapis.com/chart?chbh=a,5,25&chxr=1,0,36,7&chd=t:5.77,10.37,15.72,18.31,19.73,25.13,26.70,29.31,31.44,35.49|0.86,0.82,1.06,0.99,0.79,1.06,0.84,0.79,0.93,0.94&chxs=1N**%20secs&chs=900x200&chds=0,36&chxl=0:|50%20MB|100%20MB|150%20MB|200%20MB|250%20MB|300%20MB|350%20MB|400%20MB|450%20MB|500%20MB&cht=bvg&chdl=fspawn%20%28fork%2Bexec%29|pspawn%20%28posix_spawn%29&chtt=posix-spawn-benchmark%20--graph%20--count%20500%20--mem-size%20500%20%28x86_64-linux%29&chco=1f77b4,ff7f0e&chf=bg,s,f8f8f8&chxt=x,y#.png)

`posix_spawn` is faster than `fork+exec`, and executes in constant time when
used with `POSIX_SPAWN_USEVFORK`.

`fork+exec` is extremely slow for large parent processes.

### OSX

![](https://chart.googleapis.com/chart?chxl=0:|50%20MB|100%20MB|150%20MB|200%20MB|250%20MB|300%20MB|350%20MB|400%20MB|450%20MB|500%20MB&cht=bvg&chdl=fspawn%20%28fork%2Bexec%29|pspawn%20%28posix_spawn%29&chtt=posix-spawn-benchmark%20--graph%20--count%20500%20--mem-size%20500%20%28i686-darwin10.5.0%29&chco=1f77b4,ff7f0e&chf=bg,s,f8f8f8&chxt=x,y&chbh=a,5,25&chxr=1,0,3,0&chd=t:1.95,2.07,2.56,2.29,2.21,2.32,2.15,2.25,1.96,2.02|0.84,0.97,0.89,0.82,1.13,0.89,0.93,0.81,0.83,0.81&chxs=1N**%20secs&chs=900x200&chds=0,3#.png)

`posix_spawn` is faster than `fork+exec`, but neither is affected by the size of
the parent process.

## USAGE

This library includes two distinct interfaces: `POSIX::Spawn::spawn`, a lower
level process spawning interface based on the new Ruby 1.9 `Process::spawn`
method, and `POSIX::Spawn::Child`, a higher level class geared toward easy
spawning of processes with simple string based standard input/output/error
stream handling. The former is much more versatile, the latter requires much
less code for certain common scenarios.

### POSIX::Spawn::spawn

The `POSIX::Spawn` module (with help from the accompanying C extension)
implements a subset of the [Ruby 1.9 Process::spawn][ps] interface, largely
through the use of the [IEEE Std 1003.1 `posix_spawn(2)` systems interfaces][po].
These are widely supported by various UNIX operating systems.

[ps]: http://www.ruby-doc.org/core-1.9/classes/Process.html#M002230
[po]: http://pubs.opengroup.org/onlinepubs/009695399/functions/posix_spawn.html

In its simplest form, the `POSIX::Spawn::spawn` method can be used to execute a
child process similar to `Kernel#system`:

    require 'posix/spawn'
    pid  = POSIX::Spawn::spawn('echo', 'hello world')
    stat = Process::waitpid(pid)

The first line executes `echo` with a single argument and immediately returns
the new process's `pid`. The second line waits for the process to complete and
returns a `Process::Status` object. Note that `spawn` *does not* wait for the
process to finish execution like `system` and does not reap the child's exit
status -- you must call `Process::waitpid` (or equivalent) or the process will
become a zombie.

The `spawn` method is capable of performing a large number of additional
operations, from setting up the new process's environment, to changing the
child's working directory, to redirecting arbitrary file descriptors.

See the Ruby 1.9 [`Process::spawn` documentation][ps] for details and the
`STATUS` section below for a full account of the various `Process::spawn`
features supported by `POSIX::Spawn::spawn`.

### `system`, `popen4`, and <code>`</code>

In addition to the `spawn` method, Ruby 1.9 compatible implementations of
`Kernel#system` and <code>Kernel#\`</code> are provided in the `POSIX::Spawn`
module. The `popen4` method can be used to spawn a process with redirected
stdin, stdout, and stderr objects.

### POSIX::Spawn as a Mixin

The `POSIX::Spawn` module can also be mixed in to classes and modules to include
`spawn` and all utility methods in that namespace:

    require 'posix/spawn'

    class YourGreatClass
      include POSIX::Spawn

      def speak(message)
        pid = spawn('echo', message)
        Process::waitpid(pid)
      end

      def calculate(expression)
        pid, in, out, err = popen4('bc')
        in.write(expression)
        in.close
        out.read
      ensure
        [in, out, err].each { |io| io.close if !io.closed? }
        Process::waitpid(pid)
      end
    end

### POSIX::Spawn::Child

The `POSIX::Spawn::Child` class includes logic for executing child processes and
reading/writing from their standard input, output, and error streams. It's
designed to take all input in a single string and provides all output as single
strings and is therefore not well-suited to streaming large quantities of data
in and out of commands. That said, it has some benefits:

 - **Simple** - requires little code for simple stream input and capture.
 - **Internally non-blocking** (using `select(2)`) - handles all pipe hang cases
   due to exceeding `PIPE_BUF` limits on one or more streams.
 - **Potentially portable** - abstracts lower-level process and stream
   management APIs so the class can be made to work on platforms like Java and
   Windows where UNIX process spawning and stream APIs are not supported.

`POSIX::Spawn::Child` takes the standard `spawn` arguments when instantiated,
and runs the process to completion after writing all input and reading all
output:

    >> require 'posix/spawn'
    >> child = POSIX::Spawn::Child.new('git', '--help')

Retrieve process output written to stdout / stderr, or inspect the process's
exit status:

    >> child.out
    => "usage: git [--version] [--exec-path[=GIT_EXEC_PATH]]\n ..."
    >> child.err
    => ""
    >> child.status
    => #<Process::Status: pid=80718,exited(0)>

Use the `:input` option to write data on the new process's stdin immediately
after spawning:

    >> child = POSIX::Spawn::Child.new('bc', :input => '40 + 2')
    >> child.out
    "42\n"

Additional options can be used to specify the maximum output size (`:max`) and
time of execution (`:timeout`) before the child process is aborted. See the
`POSIX::Spawn::Child` docs for more info.

#### Reading Partial Results

`POSIX::Spawn::Child.new` spawns the process immediately when instantiated.
As a result, if it is interrupted by an exception (either from reaching the
maximum output size, the time limit, or another factor), it is not possible to
access the `out` or `err` results because the constructor did not complete.

If you want to get the `out` and `err` data was available when the process
was interrupted, use the `POSIX::Spawn::Child.build` alternate form to
create the child without immediately spawning the process.  Call `exec!`
to run the command at a place where you can catch any exceptions:

    >> child = POSIX::Spawn::Child.build('git', 'log', :max => 100)
    >> begin
    ?>   child.exec!
    ?> rescue POSIX::Spawn::MaximumOutputExceeded
    ?>   # limit was reached
    ?> end
    >> child.out
    "commit fa54abe139fd045bf6dc1cc259c0f4c06a9285bb\n..."

Please note that when the `MaximumOutputExceeded` exception is raised, the
actual combined `out` and `err` data may be a bit longer than the `:max`
value due to internal buffering.

## STATUS

The `POSIX::Spawn::spawn` method is designed to be as compatible with Ruby 1.9's
`Process::spawn` as possible. Right now, it is a compatible subset.

These `Process::spawn` arguments are currently supported to any of
`Spawn::spawn`, `Spawn::system`, `Spawn::popen4`, and `Spawn::Child.new`:

    env: hash
      name => val : set the environment variable
      name => nil : unset the environment variable
    command...:
      commandline                 : command line string which is passed to a shell
      cmdname, arg1, ...          : command name and one or more arguments (no shell)
      [cmdname, argv0], arg1, ... : command name, argv[0] and zero or more arguments (no shell)
    options: hash
      clearing environment variables:
        :unsetenv_others => true   : clear environment variables except specified by env
        :unsetenv_others => false  : don't clear (default)
      current directory:
        :chdir => str : Not thread-safe when using posix_spawn (see below)
      process group:
        :pgroup => true or 0 : make a new process group
        :pgroup => pgid      : join to specified process group
        :pgroup => nil       : don't change the process group (default)
      redirection:
        key:
          FD              : single file descriptor in child process
          [FD, FD, ...]   : multiple file descriptor in child process
        value:
          FD                        : redirect to the file descriptor in parent process
          :close                    : close the file descriptor in child process
          string                    : redirect to file with open(string, "r" or "w")
          [string]                  : redirect to file with open(string, File::RDONLY)
          [string, open_mode]       : redirect to file with open(string, open_mode, 0644)
          [string, open_mode, perm] : redirect to file with open(string, open_mode, perm)
        FD is one of follows
          :in     : the file descriptor 0 which is the standard input
          :out    : the file descriptor 1 which is the standard output
          :err    : the file descriptor 2 which is the standard error
          integer : the file descriptor of specified the integer
          io      : the file descriptor specified as io.fileno

These options are currently NOT supported:

    options: hash
      resource limit: resourcename is core, cpu, data, etc.  See Process.setrlimit.
        :rlimit_resourcename => limit
        :rlimit_resourcename => [cur_limit, max_limit]
      umask:
        :umask => int
      redirection:
        value:
          [:child, FD]              : redirect to the redirected file descriptor
      file descriptor inheritance: close non-redirected non-standard fds (3, 4, 5, ...) or not
        :close_others => false : inherit fds (default for system and exec)
        :close_others => true  : don't inherit (default for spawn and IO.popen)

The `:chdir` option provided by Posix::Spawn::Child, Posix::Spawn#spawn,
Posix::Spawn#system and Posix::Spawn#popen4 is not thread-safe because
processes spawned with the posix_spawn(2) system call inherit the working
directory of the calling process. The posix-spawn gem works around this
limitation in the system call by changing the working directory of the calling
process immediately before and after spawning the child process.

## ACKNOWLEDGEMENTS

Copyright (c) by
[Ryan Tomayko](http://tomayko.com/about)
and
[Aman Gupta](https://github.com/tmm1).

See the `COPYING` file for more information on license and redistribution.
