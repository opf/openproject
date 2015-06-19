#!/usr/bin/env ruby
#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'optparse'
require 'find'
require 'etc'
require 'json'
require 'net/http'
require 'uri'

Version = "1.4"
SUPPORTED_SCM = %w( Subversion Git Filesystem )

$verbose      = 0
$quiet        = false
$openproject_host = ''
$repos_base   = ''
$svn_owner    = 'root'
$svn_group    = 'root'
$public_mode  = '0775'
$private_mode = '0770'
$use_groupid  = true
$svn_url      = false
$test         = false
$force        = false
$scm          = 'Subversion'

def log(text, options={})
  level = options[:level] || 0
  puts text unless $quiet or level > $verbose
  exit 1 if options[:exit]
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
        system_or_raise "git update-server-info"
      end
    end
  end

end

OptionParser.new do |opts|
  opts.banner = "Usage: reposman.rb [OPTIONS...] -s [DIR] -r [HOST]"
  opts.separator("")
  opts.separator("Manages your repositories with OpenProject.")
  opts.separator("")
  opts.separator("Required arguments:")
  opts.on("-s", "--svn-dir DIR",           "use DIR as base directory for svn repositories") {|v| $repos_base = v}
  opts.on("-r", "--openproject-host HOST", "assume OpenProject is hosted on HOST. Examples:",
                                           " -r openproject.example.net",
                                           " -r http://openproject.example.net",
                                           " -r https://openproject.example.net") {|v| $openproject_host = v}
  opts.on('',  "--redmine-host HOST",      "DEPRECATED: please use --openproject-host instead") {|v| $openproject_host = v}
  opts.on("-k", "--key KEY",               "use KEY as the OpenProject API key") {|v| $api_key = v}
  opts.separator("")
  opts.separator("Options:")
  opts.on("-o", "--owner OWNER",           "owner of the repository. using the rails login",
                                           "allows users to browse the repository within",
                                           "OpenProject even for private projects. If you want to",
                                           "share repositories through OpenProject.pm, you need",
                                           "to use the apache owner.") {|v| $svn_owner = v; $use_groupid = false}
  opts.on("-g", "--group GROUP",           "group of the repository (default: root)") {|v| $svn_group = v; $use_groupid = false}
  opts.on(      "--public-mode MODE",      "file mode for new public repositories (default: 0775)") {|v| $public_mode = v}
  opts.on(      "--private-mode MODE",     "file mode for new private repositories (default: 0770)") {|v| $private_mode = v}
  opts.on(      "--scm SCM",               "the kind of SCM repository you want to create",
                                           "(and register) in OpenProject (default: Subversion).",
                                           "reposman is able to create Git and Subversion",
                                           "repositories.",
                                           "For all other kind, you must specify a --command",
                                           "option") {|v| v.capitalize; log("Invalid SCM: #{v}", :exit => true) unless SUPPORTED_SCM.include?(v)}
  opts.on("-u", "--url URL",               "the base url OpenProject will use to access your",
                                           "repositories. This option is used to automatically",
                                           "register the repositories in OpenProject. The project ",
                                           "identifier will be appended to this url.",
                                           "Examples:",
                                           " -u https://example.net/svn",
                                           " -u file:///var/svn/",
                                           "if this option isn't set, reposman won't register",
                                           "the repositories in OpenProject") {|v| $svn_url = v}
  opts.on("-c", "--command COMMAND",       "use this command instead of 'svnadmin create' to",
                                           "create a repository. This option can be used to",
                                           "create repositories other than subversion and git",
                                           "kind.",
                                           "This command override the default creation for git",
                                           "and subversion.") {|v| $command = v}
  opts.on("-f", "--force",                 "force repository creation even if the project",
                                           "repository is already declared in OpenProject") {$force = true}
  opts.on("-t", "--test",                  "only show what should be done") {$test = true}
  opts.on("-h", "--help",                  "show help and exit") {puts opts; exit 1}
  opts.on("-v", "--verbose",               "verbose") {$verbose += 1}
  opts.on("-V", "--version",               "print version and exit") {puts Version; exit}
  opts.on("-q", "--quiet",                 "no log") {$quiet = true}
  opts.separator("")
  opts.separator("Examples:")
  opts.separator("  reposman.rb --svn-dir=/var/svn --openproject-host=openproject.example.net --scm Subversion")
  opts.separator("  reposman.rb -s /var/git -r openproject.example.net -u http://svn.example.net --scm Git")
  opts.separator("")
  opts.separator("You might find more information on the OpenProject's help site:\nhttps://www.openproject.org/help")
end.parse!

if $test
  log("running in test mode")
end

# Make sure command is overridden if SCM vendor is not handled internally (for the moment Subversion and Git)
if $command.nil?
  begin
    scm_module = SCM.const_get($scm)
  rescue
    log("Please use --command option to specify how to create a #{$scm} repository.", :exit => true)
  end
end

$svn_url += "/" if $svn_url and not $svn_url.match(/\/$/)

if ($openproject_host.empty? or $repos_base.empty?)
  puts "Required argument missing. Type 'reposman.rb --help' for usage."
  exit 1
end

unless File.directory?($repos_base)
  log("directory '#{$repos_base}' doesn't exists", :exit => true)
end

log("querying OpenProject for projects...", :level => 1);

$openproject_host.gsub!(/^/, "http://") unless $openproject_host.match("^https?://")
$openproject_host.gsub!(/\/$/, '')

api_uri = URI.parse("#{$openproject_host}/sys")
http = Net::HTTP.new(api_uri.host, api_uri.port)
http.use_ssl = (api_uri.scheme == 'https')
http_headers = {'User-Agent' => "OpenProject-Repository-Manager/#{Version}"}

begin
  # Get all active projects that have the Repository module enabled
  response = http.get("#{api_uri.path}/projects.json?key=#{$api_key}", http_headers)
  projects = JSON.parse(response.body)
rescue => e
  log("Unable to connect to #{$openproject_host}: #{e}", :exit => true)
end

if projects.nil?
  log('no project found, perhaps you forgot to "Enable WS for repository management"', :exit => true)
end

log("retrieved #{projects.size} projects", :level => 1)

def set_owner_and_rights(project, repos_path, &block)
  if mswin?
    yield if block_given?
  else
    uid, gid = Etc.getpwnam($svn_owner).uid, ($use_groupid ? Etc.getgrnam(project['identifier']).gid : Etc.getgrnam($svn_group).gid)
    right = project['is_public'] ? $public_mode : $private_mode
    right = right.to_i(8) & 007777
    yield if block_given?
    Find.find(repos_path) do |f|
      File.chmod right, f
      File.chown uid, gid, f
    end
  end
end

def other_read_right?(file)
  !(File.stat(file).mode & 0007).zero?
end

def owner_name(file)
  mswin? ?
    $svn_owner :
    Etc.getpwuid( File.stat(file).uid ).name
end

def mswin?
  (RUBY_PLATFORM =~ /(:?mswin|mingw)/) || (RUBY_PLATFORM == 'java' && (ENV['OS'] || ENV['os']) =~ /windows/i)
end

projects.each do |project|
  log("treating project #{project['name']}", :level => 1)

  if project['identifier'].empty?
    log("\tno identifier for project #{project['name']}")
    next
  elsif not project['identifier'].match(/^[a-z0-9\-_]+$/)
    log("\tinvalid identifier for project #{project['name']} : #{project['identifier']}");
    next;
  end

  repos_path = File.join($repos_base, project['identifier']).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)

  if File.directory?(repos_path)

    # we must verify that repository has the good owner and the good
    # rights before leaving
    other_read = other_read_right?(repos_path)
    owner      = owner_name(repos_path)
    next if project['is_public'] == other_read and owner == $svn_owner

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
    # if repository is already declared in openproject, we don't create
    # unless user use -f with reposman
    if $force == false and project.has_key?('repository')
      log("\trepository for project #{project['identifier']} already exists in OpenProject", :level => 1)
      next
    end

    project['is_public'] ? File.umask(0002) : File.umask(0007)

    if $test
      log("\tcreate repository #{repos_path}")
      log("\trepository #{repos_path} registered in OpenProject with url #{$svn_url}#{project['identifier']}") if $svn_url;
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
      begin
        http.post("#{api_uri.path}/projects/#{project['identifier']}/repository.json?" +
                  "vendor=#{$scm}&repository[url]=#{$svn_url}#{project['identifier']}&key=#{$api_key}",
                  "",  # empty data
                  http_headers)
        log("\trepository #{repos_path} registered in OpenProject with url #{$svn_url}#{project['identifier']}");
      rescue => e
        log("\trepository #{repos_path} not registered in OpenProject: #{e.message}");
      end
    end

    log("\trepository #{repos_path} created");
  end

end
