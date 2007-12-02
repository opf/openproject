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
        
        def info
          cmd = "#{HG_BIN} -R #{target('')} root"
          root_url = nil
          shellout(cmd) do |io|
            root_url = io.gets
          end
          return nil if $? && $?.exitstatus != 0
          info = Info.new({:root_url => root_url.chomp,
                           :lastrev => revisions(nil,nil,nil,{:limit => 1}).last
                         })
          info
        rescue Errno::ENOENT => e
          return nil
        end
        
        def entries(path=nil, identifier=nil)
          path ||= ''
          entries = Entries.new
          cmd = "#{HG_BIN} -R #{target('')} --cwd #{target(path)} locate -X */*/*"
          cmd << " -r #{identifier.to_i}" if identifier
          cmd << " * */*"
          shellout(cmd) do |io|
            io.each_line do |line|
              e = line.chomp.split('\\')
              entries << Entry.new({:name => e.first,
                                    :path => (path.empty? ? e.first : "#{path}/#{e.first}"),
                                    :kind => (e.size > 1 ? 'dir' : 'file'),
                                    :lastrev => Revision.new
                                    }) unless entries.detect{|entry| entry.name == e.first}
            end
          end
          return nil if $? && $?.exitstatus != 0
          entries.sort_by_name
        rescue Errno::ENOENT => e
          raise CommandFailed
        end
  
        def entry(path=nil, identifier=nil)
          path ||= ''
          search_path = path.split('/')[0..-2].join('/')
          entry_name = path.split('/').last
          e = entries(search_path, identifier)
          e ? e.detect{|entry| entry.name == entry_name} : nil
        end
          
        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          revisions = Revisions.new
          cmd = "#{HG_BIN} -v -R #{target('')} log"
          cmd << " -r #{identifier_from.to_i}:" if identifier_from
          cmd << " --limit #{options[:limit].to_i}" if options[:limit]
          shellout(cmd) do |io|
            changeset = {}
            parsing_descr = false
            line_feeds = 0
            
            io.each_line do |line|
              if line =~ /^(\w+):\s*(.*)$/
                key = $1
                value = $2
                if parsing_descr && line_feeds > 1
                  parsing_descr = false
                  revisions << Revision.new({:identifier => changeset[:changeset].split(':').first.to_i,
                                             :scmid => changeset[:changeset].split(':').last,
                                             :author => changeset[:user],
                                             :time => Time.parse(changeset[:date]),
                                             :message => changeset[:description],
                                             :paths => changeset[:files].to_s.split.collect{|path| {:action => 'X', :path => "/#{path}"}}
                  })
                  changeset = {}
                end
                if !parsing_descr
                  changeset.store key.to_sym, value
                  if $1 == "description"
                    parsing_descr = true
                    line_feeds = 0
                    next
                  end
                end
              end
              if parsing_descr
                changeset[:description] << line
                line_feeds += 1 if line.chomp.empty?
              end
            end
            revisions << Revision.new({:identifier => changeset[:changeset].split(':').first.to_i,
                                       :scmid => changeset[:changeset].split(':').last,
                                       :author => changeset[:user],
                                       :time => Time.parse(changeset[:date]),
                                       :message => changeset[:description],
                                       :paths => changeset[:files].split.collect{|path| {:action => 'X', :path => "/#{path}"}}
            })
          end
          return nil if $? && $?.exitstatus != 0
          revisions
        rescue Errno::ENOENT => e
          raise CommandFailed
        end
        
        def diff(path, identifier_from, identifier_to=nil, type="inline")
          path ||= ''
          if identifier_to
            identifier_to = identifier_to.to_i 
          else
            identifier_to = identifier_from.to_i - 1
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
          DiffTableList.new diff, type
    
        rescue Errno::ENOENT => e
          raise CommandFailed
        end
        
        def cat(path, identifier=nil)
          cmd = "#{HG_BIN} -R #{target('')} cat #{target(path)}"
          cat = nil
          shellout(cmd) do |io|
            io.binmode
            cat = io.read
          end
          return nil if $? && $?.exitstatus != 0
          cat
        rescue Errno::ENOENT => e
          raise CommandFailed
        end
        
        def annotate(path, identifier=nil)
          path ||= ''
          cmd = "#{HG_BIN} -R #{target('')}"
          cmd << " annotate -n -u"
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
        rescue Errno::ENOENT => e
          raise CommandFailed
        end
      end
    end
  end
end
