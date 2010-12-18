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

module Redmine
  module Scm
    module Adapters    
      class MercurialAdapter < AbstractAdapter
        
        # Mercurial executable name
        HG_BIN = "hg"
        TEMPLATES_DIR = File.dirname(__FILE__) + "/mercurial"
        TEMPLATE_NAME = "hg-template"
        TEMPLATE_EXTENSION = "tmpl"
        
        class << self
          def client_version
            @@client_version ||= (hgversion || [])
          end
          
          def hgversion  
            # The hg version is expressed either as a
            # release number (eg 0.9.5 or 1.0) or as a revision
            # id composed of 12 hexa characters.
            theversion = hgversion_from_command_line
            if m = theversion.match(%r{\A(.*?)((\d+\.)+\d+)})
              m[2].scan(%r{\d+}).collect(&:to_i)
            end
          end
          
          def hgversion_from_command_line
            shellout("#{HG_BIN} --version") { |io| io.read }.to_s
          end
          
          def template_path
            @@template_path ||= template_path_for(client_version)
          end
          
          def template_path_for(version)
            if ((version <=> [0,9,5]) > 0) || version.empty?
              ver = "1.0"
            else
              ver = "0.9.5"
            end
            "#{TEMPLATES_DIR}/#{TEMPLATE_NAME}-#{ver}.#{TEMPLATE_EXTENSION}"
          end
        end
        
        def info
          cmd = "#{HG_BIN} -R #{target('')} root"
          root_url = nil
          shellout(cmd) do |io|
            root_url = io.read
          end
          return nil if $? && $?.exitstatus != 0
          info = Info.new({:root_url => root_url.chomp,
                            :lastrev => revisions(nil,nil,nil,{:limit => 1}).last
                          })
          info
        rescue CommandFailed
          return nil
        end
        
        def entries(path=nil, identifier=nil)
          path ||= ''
          entries = Entries.new
          cmd = "#{HG_BIN} -R #{target('')} --cwd #{target('')} locate"
          cmd << " -r " + shell_quote(identifier ? identifier.to_s : "tip")
          cmd << " " + shell_quote("path:#{path}") unless path.empty?
          shellout(cmd) do |io|
            io.each_line do |line|
              # HG uses antislashs as separator on Windows
              line = line.gsub(/\\/, "/")
              if path.empty? or e = line.gsub!(%r{^#{with_trailling_slash(path)}},'')
                e ||= line
                e = e.chomp.split(%r{[\/\\]})
                entries << Entry.new({:name => e.first,
                                       :path => (path.nil? or path.empty? ? e.first : "#{with_trailling_slash(path)}#{e.first}"),
                                       :kind => (e.size > 1 ? 'dir' : 'file'),
                                       :lastrev => Revision.new
                                     }) unless e.empty? || entries.detect{|entry| entry.name == e.first}
              end
            end
          end
          return nil if $? && $?.exitstatus != 0
          entries.sort_by_name
        end
        
        # Fetch the revisions by using a template file that 
        # makes Mercurial produce a xml output.
        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})  
          revisions = Revisions.new
          cmd = "#{HG_BIN} --debug --encoding utf8 -R #{target('')} log -C --style #{shell_quote self.class.template_path}"
          if identifier_from && identifier_to
            cmd << " -r #{identifier_from.to_i}:#{identifier_to.to_i}"
          elsif identifier_from
            cmd << " -r #{identifier_from.to_i}:"
          end
          cmd << " --limit #{options[:limit].to_i}" if options[:limit]
          cmd << " #{shell_quote path}" unless path.blank?
          shellout(cmd) do |io|
            begin
              # HG doesn't close the XML Document...
              doc = REXML::Document.new(io.read << "</log>")
              doc.elements.each("log/logentry") do |logentry|
                paths = []
                copies = logentry.get_elements('paths/path-copied')
                logentry.elements.each("paths/path") do |path|
                  # Detect if the added file is a copy
                  if path.attributes['action'] == 'A' and c = copies.find{ |e| e.text == path.text }
                    from_path = c.attributes['copyfrom-path']
                    from_rev = logentry.attributes['revision']
                  end
                  paths << {:action => path.attributes['action'],
                    :path => "/#{path.text}",
                    :from_path => from_path ? "/#{from_path}" : nil,
                    :from_revision => from_rev ? from_rev : nil
                  }
                end
                paths.sort! { |x,y| x[:path] <=> y[:path] }
                
                revisions << Revision.new({:identifier => logentry.attributes['revision'],
                                            :scmid => logentry.attributes['node'],
                                            :author => (logentry.elements['author'] ? logentry.elements['author'].text : ""),
                                            :time => Time.parse(logentry.elements['date'].text).localtime,
                                            :message => logentry.elements['msg'].text,
                                            :paths => paths
                                          })
              end
            rescue
              logger.debug($!)
            end
          end
          return nil if $? && $?.exitstatus != 0
          revisions
        end
        
        def diff(path, identifier_from, identifier_to=nil)
          path ||= ''
          if identifier_to
            identifier_to = identifier_to.to_i 
          else
            identifier_to = identifier_from.to_i - 1
          end
          if identifier_from
            identifier_from = identifier_from.to_i
          end
          cmd = "#{HG_BIN} -R #{target('')} diff -r #{identifier_to} -r #{identifier_from} --nodates"
          cmd << " -I #{target(path)}" unless path.empty?
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
          cmd = "#{HG_BIN} -R #{target('')} cat"
          cmd << " -r " + shell_quote(identifier ? identifier.to_s : "tip")
          cmd << " #{target(path)}"
          cat = nil
          shellout(cmd) do |io|
            io.binmode
            cat = io.read
          end
          return nil if $? && $?.exitstatus != 0
          cat
        end
        
        def annotate(path, identifier=nil)
          path ||= ''
          cmd = "#{HG_BIN} -R #{target('')}"
          cmd << " annotate -n -u"
          cmd << " -r " + shell_quote(identifier ? identifier.to_s : "tip")
          cmd << " -r #{identifier.to_i}" if identifier
          cmd << " #{target(path)}"
          blame = Annotate.new
          shellout(cmd) do |io|
            io.each_line do |line|
              next unless line =~ %r{^([^:]+)\s(\d+):(.*)$}
              blame.add_line($3.rstrip, Revision.new(:identifier => $2.to_i, :author => $1.strip))
            end
          end
          return nil if $? && $?.exitstatus != 0
          blame
        end
      end
    end
  end
end
