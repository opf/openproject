# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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
require 'uri'

module Redmine
  module Scm
    module Adapters    
      class SubversionAdapter < AbstractAdapter
      
        # SVN executable name
        SVN_BIN = Redmine::Configuration['scm_subversion_command'] || "svn"
        
        class << self
          def client_version
            @@client_version ||= (svn_binary_version || [])
          end
          
          def svn_binary_version
            cmd = "#{SVN_BIN} --version"
            version = nil
            shellout(cmd) do |io|
              # Read svn version in first returned line
              if m = io.read.to_s.match(%r{\A(.*?)((\d+\.)+\d+)})
                version = m[2].scan(%r{\d+}).collect(&:to_i)
              end
            end
            return nil if $? && $?.exitstatus != 0
            version
          end
        end
        
        # Get info about the svn repository
        def info
          cmd = "#{SVN_BIN} info --xml #{target}"
          cmd << credentials_string
          info = nil
          shellout(cmd) do |io|
            output = io.read
            begin
              doc = ActiveSupport::XmlMini.parse(output)
              #root_url = doc.elements["info/entry/repository/root"].text          
              info = Info.new({:root_url => doc['info']['entry']['repository']['root']['__content__'],
                               :lastrev => Revision.new({
                                 :identifier => doc['info']['entry']['commit']['revision'],
                                 :time => Time.parse(doc['info']['entry']['commit']['date']['__content__']).localtime,
                                 :author => (doc['info']['entry']['commit']['author'] ? doc['info']['entry']['commit']['author']['__content__'] : "")
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
          cmd = "#{SVN_BIN} list --xml #{target(path)}@#{identifier}"
          cmd << credentials_string
          shellout(cmd) do |io|
            output = io.read
            begin
              doc = ActiveSupport::XmlMini.parse(output)
              each_xml_element(doc['lists']['list'], 'entry') do |entry|
                commit = entry['commit']
                commit_date = commit['date']
                # Skip directory if there is no commit date (usually that
                # means that we don't have read access to it)
                next if entry['kind'] == 'dir' && commit_date.nil?
                name = entry['name']['__content__']
                entries << Entry.new({:name => URI.unescape(name),
                            :path => ((path.empty? ? "" : "#{path}/") + name),
                            :kind => entry['kind'],
                            :size => ((s = entry['size']) ? s['__content__'].to_i : nil),
                            :lastrev => Revision.new({
                              :identifier => commit['revision'],
                              :time => Time.parse(commit_date['__content__'].to_s).localtime,
                              :author => ((a = commit['author']) ? a['__content__'] : nil)
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
          cmd = "#{SVN_BIN} proplist --verbose --xml #{target(path)}@#{identifier}"
          cmd << credentials_string
          properties = {}
          shellout(cmd) do |io|
            output = io.read
            begin
              doc = ActiveSupport::XmlMini.parse(output)
              each_xml_element(doc['properties']['target'], 'property') do |property|
                properties[ property['name'] ] = property['__content__'].to_s
              end
            rescue
            end
          end
          return nil if $? && $?.exitstatus != 0
          properties
        end
        
        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          path ||= ''
          identifier_from = (identifier_from && identifier_from.to_i > 0) ? identifier_from.to_i : "HEAD"
          identifier_to = (identifier_to && identifier_to.to_i > 0) ? identifier_to.to_i : 1
          revisions = Revisions.new
          cmd = "#{SVN_BIN} log --xml -r #{identifier_from}:#{identifier_to}"
          cmd << credentials_string
          cmd << " --verbose " if  options[:with_paths]
          cmd << " --limit #{options[:limit].to_i}" if options[:limit]
          cmd << ' ' + target(path)
          shellout(cmd) do |io|
            output = io.read
            begin
              doc = ActiveSupport::XmlMini.parse(output)
              each_xml_element(doc['log'], 'logentry') do |logentry|
                paths = []
                each_xml_element(logentry['paths'], 'path') do |path|
                  paths << {:action => path['action'],
                            :path => path['__content__'],
                            :from_path => path['copyfrom-path'],
                            :from_revision => path['copyfrom-rev']
                            }
                end if logentry['paths'] && logentry['paths']['path']
                paths.sort! { |x,y| x[:path] <=> y[:path] }
                
                revisions << Revision.new({:identifier => logentry['revision'],
                              :author => (logentry['author'] ? logentry['author']['__content__'] : ""),
                              :time => Time.parse(logentry['date']['__content__'].to_s).localtime,
                              :message => logentry['msg']['__content__'],
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
          cmd << " #{target(path)}@#{identifier_from}"
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
          cmd = "#{SVN_BIN} cat #{target(path)}@#{identifier}"
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
          cmd = "#{SVN_BIN} blame #{target(path)}@#{identifier}"
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
        
        # Helper that iterates over the child elements of a xml node
        # MiniXml returns a hash when a single child is found or an array of hashes for multiple children
        def each_xml_element(node, name)
          if node && node[name]
            if node[name].is_a?(Hash)
              yield node[name]
            else
              node[name].each do |element|
                yield element
              end
            end
          end
        end

        def target(path = '')
          base = path.match(/^\//) ? root_url : url
          uri = "#{base}/#{path}"
          uri = URI.escape(URI.escape(uri), '[]')
          shell_quote(uri.gsub(/[?<>\*]/, ''))
        end
      end
    end
  end
end
