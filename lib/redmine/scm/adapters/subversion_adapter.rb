# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require 'redmine/scm/adapters/abstract_adapter'
require 'rexml/document'
require 'uri'

module Redmine
  module Scm
    module Adapters    
      class SubversionAdapter < AbstractAdapter
      
        # SVN executable name
        SVN_BIN = "svn"
        
        class << self
          def client_version
            @@client_version ||= (svn_binary_version || [])
          end
          
          def svn_binary_version
            cmd = "#{SVN_BIN} --version"
            version = nil
            shellout(cmd) do |io|
              # Read svn version in first returned line
              if m = io.gets.to_s.match(%r{((\d+\.)+\d+)})
                version = m[0].scan(%r{\d+}).collect(&:to_i)
              end
            end
            return nil if $? && $?.exitstatus != 0
            version
          end
        end
        
        # Get info about the svn repository
        def info
          cmd = "#{SVN_BIN} info --xml #{target('')}"
          cmd << credentials_string
          info = nil
          shellout(cmd) do |io|
            begin
              doc = REXML::Document.new(io)
              #root_url = doc.elements["info/entry/repository/root"].text          
              info = Info.new({:root_url => doc.elements["info/entry/repository/root"].text,
                               :lastrev => Revision.new({
                                 :identifier => doc.elements["info/entry/commit"].attributes['revision'],
                                 :time => Time.parse(doc.elements["info/entry/commit/date"].text).localtime,
                                 :author => (doc.elements["info/entry/commit/author"] ? doc.elements["info/entry/commit/author"].text : "")
                               })
                             })
            rescue
            end
          end
          return nil if $? && $?.exitstatus != 0
          info
        rescue CommandFailed
          return nil
        end
        
        # Returns an Entries collection
        # or nil if the given path doesn't exist in the repository
        def entries(path=nil, identifier=nil)
          path ||= ''
          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : "HEAD"
          entries = Entries.new
          cmd = "#{SVN_BIN} list --xml #{target(URI.escape(path))}@#{identifier}"
          cmd << credentials_string
          shellout(cmd) do |io|
            output = io.read
            begin
              doc = REXML::Document.new(output)
              doc.elements.each("lists/list/entry") do |entry|
                commit = entry.elements['commit']
                commit_date = commit.elements['date']
                # Skip directory if there is no commit date (usually that
                # means that we don't have read access to it)
                next if entry.attributes['kind'] == 'dir' && commit_date.nil?
                name = entry.elements['name'].text
                entries << Entry.new({:name => URI.unescape(name),
                            :path => ((path.empty? ? "" : "#{path}/") + name),
                            :kind => entry.attributes['kind'],
                            :size => ((s = entry.elements['size']) ? s.text.to_i : nil),
                            :lastrev => Revision.new({
                              :identifier => commit.attributes['revision'],
                              :time => Time.parse(commit_date.text).localtime,
                              :author => ((a = commit.elements['author']) ? a.text : nil)
                              })
                            })
              end
            rescue Exception => e
              logger.error("Error parsing svn output: #{e.message}")
              logger.error("Output was:\n #{output}")
            end
          end
          return nil if $? && $?.exitstatus != 0
          logger.debug("Found #{entries.size} entries in the repository for #{target(path)}") if logger && logger.debug?
          entries.sort_by_name
        end
        
        def properties(path, identifier=nil)
          # proplist xml output supported in svn 1.5.0 and higher
          return nil unless self.class.client_version_above?([1, 5, 0])
          
          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : "HEAD"
          cmd = "#{SVN_BIN} proplist --verbose --xml #{target(URI.escape(path))}@#{identifier}"
          cmd << credentials_string
          properties = {}
          shellout(cmd) do |io|
            output = io.read
            begin
              doc = REXML::Document.new(output)
              doc.elements.each("properties/target/property") do |property|
                properties[ property.attributes['name'] ] = property.text
              end
            rescue
            end
          end
          return nil if $? && $?.exitstatus != 0
          properties
        end
        
        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          path ||= ''
          identifier_from = (identifier_from and identifier_from.to_i > 0) ? identifier_from.to_i : "HEAD"
          identifier_to = (identifier_to and identifier_to.to_i > 0) ? identifier_to.to_i : 1
          revisions = Revisions.new
          cmd = "#{SVN_BIN} log --xml -r #{identifier_from}:#{identifier_to}"
          cmd << credentials_string
          cmd << " --verbose " if  options[:with_paths]
          cmd << " --limit #{options[:limit].to_i}" if options[:limit]
          cmd << ' ' + target(URI.escape(path))
          shellout(cmd) do |io|
            begin
              doc = REXML::Document.new(io)
              doc.elements.each("log/logentry") do |logentry|
                paths = []
                logentry.elements.each("paths/path") do |path|
                  paths << {:action => path.attributes['action'],
                            :path => path.text,
                            :from_path => path.attributes['copyfrom-path'],
                            :from_revision => path.attributes['copyfrom-rev']
                            }
                end
                paths.sort! { |x,y| x[:path] <=> y[:path] }
                
                revisions << Revision.new({:identifier => logentry.attributes['revision'],
                              :author => (logentry.elements['author'] ? logentry.elements['author'].text : ""),
                              :time => Time.parse(logentry.elements['date'].text).localtime,
                              :message => logentry.elements['msg'].text,
                              :paths => paths
                            })
              end
            rescue
            end
          end
          return nil if $? && $?.exitstatus != 0
          revisions
        end
        
        def diff(path, identifier_from, identifier_to=nil, type="inline")
          path ||= ''
          identifier_from = (identifier_from and identifier_from.to_i > 0) ? identifier_from.to_i : ''
          identifier_to = (identifier_to and identifier_to.to_i > 0) ? identifier_to.to_i : (identifier_from.to_i - 1)
          
          cmd = "#{SVN_BIN} diff -r "
          cmd << "#{identifier_to}:"
          cmd << "#{identifier_from}"
          cmd << " #{target(URI.escape(path))}@#{identifier_from}"
          cmd << credentials_string
          diff = []
          shellout(cmd) do |io|
            io.each_line do |line|
              diff << line
            end
          end
          return nil if $? && $?.exitstatus != 0
          diff
        end
        
        def cat(path, identifier=nil)
          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : "HEAD"
          cmd = "#{SVN_BIN} cat #{target(URI.escape(path))}@#{identifier}"
          cmd << credentials_string
          cat = nil
          shellout(cmd) do |io|
            io.binmode
            cat = io.read
          end
          return nil if $? && $?.exitstatus != 0
          cat
        end
        
        def annotate(path, identifier=nil)
          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : "HEAD"
          cmd = "#{SVN_BIN} blame #{target(URI.escape(path))}@#{identifier}"
          cmd << credentials_string
          blame = Annotate.new
          shellout(cmd) do |io|
            io.each_line do |line|
              next unless line =~ %r{^\s*(\d+)\s*(\S+)\s(.*)$}
              blame.add_line($3.rstrip, Revision.new(:identifier => $1.to_i, :author => $2.strip))
            end
          end
          return nil if $? && $?.exitstatus != 0
          blame
        end
        
        private
        
        def credentials_string
          str = ''
          str << " --username #{shell_quote(@login)}" unless @login.blank?
          str << " --password #{shell_quote(@password)}" unless @login.blank? || @password.blank?
          str << " --no-auth-cache --non-interactive"
          str
        end
      end
    end
  end
end
