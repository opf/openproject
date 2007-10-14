#!/usr/bin/ruby

# == Synopsis
#
# reposman: manages your svn repositories with redMine
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
#    assume redMine is hosted on HOST.
#    you can use :
#    * -r redmine.mydomain.foo        (will add http://)
#    * -r http://redmine.mydomain.foo
#    * -r https://mydomain.foo/redmine
#
# == Options
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
                      ['--verbose',      '-v', GetoptLong::NO_ARGUMENT],
                      ['--version',      '-V', GetoptLong::NO_ARGUMENT],
                      ['--help'   ,      '-h', GetoptLong::NO_ARGUMENT],
                      ['--quiet'  ,      '-q', GetoptLong::NO_ARGUMENT]
                      )

$verbose      = 0
$quiet        = false
$redmine_host = ''
$repos_base   = ''

def log(text,level=0, exit=false)
  return if $quiet or level > $verbose
  puts text
  exit 1 if exit
end

begin
  opts.each do |opt, arg|
    case opt
    when '--svn-dir';        $repos_base = arg.dup
    when '--redmine-host';   $redmine_host = arg.dup
    when '--verbose';        $verbose += 1
    when '--version';        puts Version; exit
    when '--help';           RDoc::usage
    when '--quiet';          $quiet = true
    end
  end
rescue
  exit 1
end

if ($redmine_host.empty? or $repos_base.empty?)
  RDoc::usage
end

unless File.directory?($repos_base)
  log("directory '#{$repos_base}' doesn't exists", 0, true)
end

log("querying redMine for projects...", 1);

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

projects.each do |p|
  log("treating project #{p.name}", 1)

  if p.identifier.empty?
    log("\tno identifier for project #{p.name}")
    next
  elsif not p.identifier.match(/^[a-z0-9\-]+$/)
    log("\tinvalid identifier for project #{p.name} : #{p.identifier}");
    next;
  end

  repos_path = $repos_base + "/" + p.identifier

  if File.directory?(repos_path)

    other_read = (File.stat(repos_path).mode & 0007).zero? ? false : true
    next if p.is_public == other_read

    right = p.is_public ? 0775 : 0770

    begin
      Find.find(repos_path) { |f| File.chmod right, f }
    rescue Errno::EPERM => e
      log("\tunable to change mode on #{repos_path} : #{e}\n")
      next
    end

    log("\tmode change on #{repos_path}");

  else
    p.is_public ? File.umask(0002) : File.umask(0007)

    begin
      uid, gid = Etc.getpwnam("root").uid, Etc.getgrnam(p.identifier).gid
      raise "svnadmin create #{repos_path} failed" unless system("svnadmin", "create", repos_path)
      Find.find(repos_path) { |f| File.chown uid, gid, f }
    rescue => e
      log("\tunable to create #{repos_path} : #{e}\n")
      next
    end

    log("\trepository #{repos_path} created");
  end

end

