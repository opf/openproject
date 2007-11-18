#!/usr/bin/ruby

# == Synopsis
#
# reposman: manages your svn repositories with Redmine
#
# == Usage
#
#     reposman [ -h | --help ] [ -v | --verbose ] [ -V | --version ] [ -q | --quiet ] -s /var/svn -r redmine.host.org
#     example: reposman --svn-dir=/var/svn --redmine-host=redmine.mydomain.foo
#              reposman -s /var/svn -r redmine.mydomain.foo
#
# == Arguments (mandatory)
# 
# -s, --svn-dir=DIR
#    use DIR as base directory for svn repositories
#
# -r, --redmine-host=HOST
#    assume Redmine is hosted on HOST.
#    you can use :
#    * -r redmine.mydomain.foo        (will add http://)
#    * -r http://redmine.mydomain.foo
#    * -r https://mydomain.foo/redmine
#
# == Options
#
# -o, --owner=OWNER
#    owner of the repository. using the rails login allow user to browse
#    the repository in Redmine even for private project
#
# -u, --url=URL
#    the base url Redmine will use to access your repositories. This
#    will be used to register the repository in Redmine so that user
#    doesn't need to do anything. reposman will add the identifier to this url :
#
#    -u https://my.svn.server/my/reposity/root # if the repository can be access by http
#    -u file:///var/svn/                       # if the repository is local
#    if this option isn't set, reposman won't register the repository
#
# -t, --test
#    only show what should be done
#
# -h, --help:
#    show help and exit
#
# -v, --verbose
#    verbose
#
# -V, --version
#    print version and exit
#
# -q, --quiet
#    no log
#

require 'getoptlong'
require 'rdoc/usage'
require 'soap/wsdlDriver'
require 'find'
require 'etc'

Version = "1.0"

opts = GetoptLong.new(
                      ['--svn-dir',      '-s', GetoptLong::REQUIRED_ARGUMENT],
                      ['--redmine-host', '-r', GetoptLong::REQUIRED_ARGUMENT],
                      ['--owner',        '-o', GetoptLong::REQUIRED_ARGUMENT],
                      ['--url',          '-u', GetoptLong::REQUIRED_ARGUMENT],
                      ['--test',         '-t', GetoptLong::NO_ARGUMENT],
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
$svn_url      = false
$test         = false

def log(text,level=0, exit=false)
  return if $quiet or level > $verbose
  puts text
  exit 1 if exit
end

begin
  opts.each do |opt, arg|
    case opt
    when '--svn-dir';        $repos_base   = arg.dup
    when '--redmine-host';   $redmine_host = arg.dup
    when '--owner';          $svn_owner    = arg.dup
    when '--url';            $svn_url      = arg.dup
    when '--verbose';        $verbose += 1
    when '--test';           $test = true
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

projects = soap.Projects

if projects.nil?
  log('no project found, perhaps you forgot to "Enable WS for repository management"', 0, true)
end

log("retrieved #{projects.size} projects", 1)

def set_owner_and_rights(project, repos_path, &block)
  if RUBY_PLATFORM =~ /mswin/
    yield if block_given?
  else
    uid, gid = Etc.getpwnam($svn_owner).uid, Etc.getgrnam(project.identifier).gid
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
    project.is_public ? File.umask(0002) : File.umask(0007)

    if $test
      log("\tcreate repository #{repos_path}")
      log("\trepository #{repos_path} registered in Redmine with url #{$svn_url}#{project.identifier}") if $svn_url;
      next
    end

    begin
      set_owner_and_rights(project, repos_path) do
        raise "svnadmin create #{repos_path} failed" unless system("svnadmin", "create", repos_path)
      end
    rescue => e
      log("\tunable to create #{repos_path} : #{e}\n")
      next
    end

    if $svn_url
      ret = soap.RepositoryCreated project.identifier, "#{$svn_url}#{project.identifier}"
      if ret > 0
        log("\trepository #{repos_path} registered in Redmine with url #{$svn_url}#{project.identifier}");
      else
        log("\trepository #{repos_path} not registered in Redmine. Look in your log to find why.");
      end
    end

    log("\trepository #{repos_path} created");
  end

end

