#!/usr/bin/ruby

# == Synopsis
#
# reposman: manages your repositories with Redmine
#
# == Usage
#
#    reposman [OPTIONS...] -s [DIR] -r [HOST]
#     
#  Examples:
#    reposman --svn-dir=/var/svn --redmine-host=redmine.example.net --scm subversion
#    reposman -s /var/git -r redmine.example.net -u http://svn.example.net --scm git
#
# == Arguments (mandatory)
#
#   -s, --svn-dir=DIR         use DIR as base directory for svn repositories
#   -r, --redmine-host=HOST   assume Redmine is hosted on HOST. Examples:
#                             -r redmine.example.net
#                             -r http://redmine.example.net
#                             -r https://example.net/redmine
#
# == Options
#
#   -o, --owner=OWNER         owner of the repository. using the rails login
#                             allow user to browse the repository within
#                             Redmine even for private project. If you want to share repositories
#                             through Redmine.pm, you need to use the apache owner.
#   --scm=SCM                 the kind of SCM repository you want to create (and register) in
#                             Redmine (default: Subversion). reposman is able to create Git 
#                             and Subversion repositories. For all other kind (Bazaar,
#                             Darcs, Filesystem, Mercurial) you must specify a --command option
#   -u, --url=URL             the base url Redmine will use to access your
#                             repositories. This option is used to automatically
#                             register the repositories in Redmine. The project
#                             identifier will be appended to this url. Examples:
#                             -u https://example.net/svn
#                             -u file:///var/svn/
#                             if this option isn't set, reposman won't register
#                             the repositories in Redmine
#   -c, --command=COMMAND     use this command instead of "svnadmin create" to
#                             create a repository. This option can be used to
#                             create repositories other than subversion and git kind.
#                             This command override the default creation for git and subversion.
#   -f, --force               force repository creation even if the project
#                             repository is already declared in Redmine
#   -t, --test                only show what should be done
#   -h, --help                show help and exit
#   -v, --verbose             verbose
#   -V, --version             print version and exit
#   -q, --quiet               no log
#
# == References
# 
# You can find more information on the redmine's wiki : http://www.redmine.org/wiki/redmine/HowTos


require 'getoptlong'
require 'rdoc/usage'
require 'soap/wsdlDriver'
require 'find'
require 'etc'

Version = "1.1"
SUPPORTED_SCM = %w( Subversion Darcs Mercurial Bazaar Git Filesystem )

opts = GetoptLong.new(
                      ['--svn-dir',      '-s', GetoptLong::REQUIRED_ARGUMENT],
                      ['--redmine-host', '-r', GetoptLong::REQUIRED_ARGUMENT],
                      ['--owner',        '-o', GetoptLong::REQUIRED_ARGUMENT],
                      ['--url',          '-u', GetoptLong::REQUIRED_ARGUMENT],
                      ['--command' ,     '-c', GetoptLong::REQUIRED_ARGUMENT],
                      ['--scm',                GetoptLong::REQUIRED_ARGUMENT],
                      ['--test',         '-t', GetoptLong::NO_ARGUMENT],
                      ['--force',        '-f', GetoptLong::NO_ARGUMENT],
                      ['--verbose',      '-v', GetoptLong::NO_ARGUMENT],
                      ['--version',      '-V', GetoptLong::NO_ARGUMENT],
                      ['--help'   ,      '-h', GetoptLong::NO_ARGUMENT],
                      ['--quiet'  ,      '-q', GetoptLong::NO_ARGUMENT]
                      )

$verbose      = 0
$quiet        = false
$redmine_host = ''
$repos_base   = ''
$svn_owner    = 'root'
$use_groupid  = true
$svn_url      = false
$test         = false
$force        = false
$scm          = 'Subversion'

def log(text,level=0, exit=false)
  puts text unless $quiet or level > $verbose
  exit 1 if exit
end

def system_or_raise(command)
  raise "\"#{command}\" failed" unless system command
end

module SCM

  module Subversion
    def self.create(path)
      system_or_raise "svnadmin create #{path}"
    end
  end

  module Git
    def self.create(path)
      Dir.mkdir path
      Dir.chdir(path) do
        system_or_raise "git --bare init --shared"
        system_or_raise "git-update-server-info"
      end
    end
  end

end

begin
  opts.each do |opt, arg|
    case opt
    when '--svn-dir';        $repos_base   = arg.dup
    when '--redmine-host';   $redmine_host = arg.dup
    when '--owner';          $svn_owner    = arg.dup; $use_groupid = false;
    when '--url';            $svn_url      = arg.dup
    when '--scm';            $scm          = arg.dup.capitalize; log("Invalid SCM: #{$scm}", 0, true) unless SUPPORTED_SCM.include?($scm)
    when '--command';        $command =      arg.dup
    when '--verbose';        $verbose += 1
    when '--test';           $test = true
    when '--force';          $force = true
    when '--version';        puts Version; exit
    when '--help';           RDoc::usage
    when '--quiet';          $quiet = true
    end
  end
rescue
  exit 1
end

if $test
  log("running in test mode")
end

# Make sure command is overridden if SCM vendor is not handled internally (for the moment Subversion and Git)
if $command.nil?
  begin
    scm_module = SCM.const_get($scm)
  rescue
    log("Please use --command option to specify how to create a #{$scm} repository.", 0, true)
  end
end

$svn_url += "/" if $svn_url and not $svn_url.match(/\/$/)

if ($redmine_host.empty? or $repos_base.empty?)
  RDoc::usage
end

unless File.directory?($repos_base)
  log("directory '#{$repos_base}' doesn't exists", 0, true)
end

log("querying Redmine for projects...", 1);

$redmine_host.gsub!(/^/, "http://") unless $redmine_host.match("^https?://")
$redmine_host.gsub!(/\/$/, '')

wsdl_url = "#{$redmine_host}/sys/service.wsdl";

begin
  soap = SOAP::WSDLDriverFactory.new(wsdl_url).create_rpc_driver
rescue => e
  log("Unable to connect to #{wsdl_url} : #{e}", 0, true)
end

projects = soap.ProjectsWithRepositoryEnabled

if projects.nil?
  log('no project found, perhaps you forgot to "Enable WS for repository management"', 0, true)
end

log("retrieved #{projects.size} projects", 1)

def set_owner_and_rights(project, repos_path, &block)
  if RUBY_PLATFORM =~ /mswin/
    yield if block_given?
  else
    uid, gid = Etc.getpwnam($svn_owner).uid, ($use_groupid ? Etc.getgrnam(project.identifier).gid : 0)
    right = project.is_public ? 0775 : 0770
    yield if block_given?
    Find.find(repos_path) do |f|
      File.chmod right, f
      File.chown uid, gid, f
    end
  end
end

def other_read_right?(file)
  (File.stat(file).mode & 0007).zero? ? false : true
end

def owner_name(file)
  RUBY_PLATFORM =~ /mswin/ ?
    $svn_owner :
    Etc.getpwuid( File.stat(file).uid ).name  
end

projects.each do |project|
  log("treating project #{project.name}", 1)

  if project.identifier.empty?
    log("\tno identifier for project #{project.name}")
    next
  elsif not project.identifier.match(/^[a-z0-9\-]+$/)
    log("\tinvalid identifier for project #{project.name} : #{project.identifier}");
    next;
  end

  repos_path = $repos_base + "/" + project.identifier

  if File.directory?(repos_path)

    # we must verify that repository has the good owner and the good
    # rights before leaving
    other_read = other_read_right?(repos_path)
    owner      = owner_name(repos_path)
    next if project.is_public == other_read and owner == $svn_owner

    if $test
      log("\tchange mode on #{repos_path}")
      next
    end

    begin
      set_owner_and_rights(project, repos_path)
    rescue Errno::EPERM => e
      log("\tunable to change mode on #{repos_path} : #{e}\n")
      next
    end

    log("\tmode change on #{repos_path}");

  else
    # if repository is already declared in redmine, we don't create
    # unless user use -f with reposman
    if $force == false and not project.repository.nil?
      log("\trepository for project #{project.identifier} already exists in Redmine", 1)
      next
    end

    project.is_public ? File.umask(0002) : File.umask(0007)

    if $test
      log("\tcreate repository #{repos_path}")
      log("\trepository #{repos_path} registered in Redmine with url #{$svn_url}#{project.identifier}") if $svn_url;
      next
    end

    begin
      set_owner_and_rights(project, repos_path) do
        if scm_module.nil?
          system_or_raise "#{$command} #{repos_path}"
        else
          scm_module.create(repos_path)
        end
      end
    rescue => e
      log("\tunable to create #{repos_path} : #{e}\n")
      next
    end

    if $svn_url
      ret = soap.RepositoryCreated project.identifier, $scm, "#{$svn_url}#{project.identifier}"
      if ret > 0
        log("\trepository #{repos_path} registered in Redmine with url #{$svn_url}#{project.identifier}");
      else
        log("\trepository #{repos_path} not registered in Redmine. Look in your log to find why.");
      end
    end

    log("\trepository #{repos_path} created");
  end

end

