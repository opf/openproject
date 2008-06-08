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
      class GitAdapter < AbstractAdapter
        
        # Git executable name
        GIT_BIN = "git"

        # Get the revision of a particuliar file
        def get_rev (rev,path)
        
          if rev != 'latest' && !rev.nil?
            cmd="#{GIT_BIN} --git-dir #{target('')} show #{shell_quote rev} -- #{shell_quote path}" 
          else
            branch = shellout("#{GIT_BIN} --git-dir #{target('')} branch") { |io| io.grep(/\*/)[0].strip.match(/\* (.*)/)[1] }
            cmd="#{GIT_BIN} --git-dir #{target('')} log -1 #{branch} -- #{shell_quote path}" 
          end
          rev=[]
          i=0
          shellout(cmd) do |io|
            files=[]
            changeset = {}
            parsing_descr = 0  #0: not parsing desc or files, 1: parsing desc, 2: parsing files

            io.each_line do |line|
              if line =~ /^commit ([0-9a-f]{40})$/
                key = "commit"
                value = $1
                if (parsing_descr == 1 || parsing_descr == 2)
                  parsing_descr = 0
                  rev = Revision.new({:identifier => changeset[:commit],
                                      :scmid => changeset[:commit],
                                      :author => changeset[:author],
                                      :time => Time.parse(changeset[:date]),
                                      :message => changeset[:description],
                                      :paths => files
                                     })
                  changeset = {}
                  files = []
                end
                changeset[:commit] = $1
              elsif (parsing_descr == 0) && line =~ /^(\w+):\s*(.*)$/
                key = $1
                value = $2
                if key == "Author"
                  changeset[:author] = value
                elsif key == "Date"
                  changeset[:date] = value
                end
              elsif (parsing_descr == 0) && line.chomp.to_s == ""
                parsing_descr = 1
                changeset[:description] = ""
              elsif (parsing_descr == 1 || parsing_descr == 2) && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\s+(.+)$/
                parsing_descr = 2
                fileaction = $1
                filepath = $2
                files << {:action => fileaction, :path => filepath}
              elsif (parsing_descr == 1) && line.chomp.to_s == ""
                parsing_descr = 2
              elsif (parsing_descr == 1)
                changeset[:description] << line
              end
            end	
            rev = Revision.new({:identifier => changeset[:commit],
                                :scmid => changeset[:commit],
                                :author => changeset[:author],
                                :time => (changeset[:date] ? Time.parse(changeset[:date]) : nil),
                                :message => changeset[:description],
                                :paths => files
                               })

          end

          get_rev('latest',path) if rev == []

          return nil if $? && $?.exitstatus != 0
          return rev
        end


        def info
          revs = revisions(url,nil,nil,{:limit => 1})
          if revs && revs.any?
            Info.new(:root_url => url, :lastrev => revs.first)
          else
            nil
          end
        rescue Errno::ENOENT => e
          return nil
        end
        
        def entries(path=nil, identifier=nil)
          path ||= ''
          entries = Entries.new
          cmd = "#{GIT_BIN} --git-dir #{target('')} ls-tree -l "
          cmd << shell_quote("HEAD:" + path) if identifier.nil?
          cmd << shell_quote(identifier + ":" + path) if identifier
          shellout(cmd)  do |io|
            io.each_line do |line|
              e = line.chomp.to_s
              if e =~ /^\d+\s+(\w+)\s+([0-9a-f]{40})\s+([0-9-]+)\s+(.+)$/
                type = $1
                sha = $2
                size = $3
                name = $4
                entries << Entry.new({:name => name,
                                       :path => (path.empty? ? name : "#{path}/#{name}"),
                                       :kind => ((type == "tree") ? 'dir' : 'file'),
                                       :size => ((type == "tree") ? nil : size),
                                       :lastrev => get_rev(identifier,(path.empty? ? name : "#{path}/#{name}")) 
                                                                  
                                     }) unless entries.detect{|entry| entry.name == name}
              end
            end
          end
          return nil if $? && $?.exitstatus != 0
          entries.sort_by_name
        end
        
        def revisions(path, identifier_from, identifier_to, options={})
          revisions = Revisions.new
          cmd = "#{GIT_BIN} --git-dir #{target('')} log --raw "
          cmd << " -n #{options[:limit].to_i} " if (!options.nil?) && options[:limit]
          cmd << " #{shell_quote(identifier_from + '..')} " if identifier_from
          cmd << " #{shell_quote identifier_to} " if identifier_to
          #cmd << " HEAD " if !identifier_to
          shellout(cmd) do |io|
            files=[]
            changeset = {}
            parsing_descr = 0  #0: not parsing desc or files, 1: parsing desc, 2: parsing files
            revno = 1

            io.each_line do |line|
              if line =~ /^commit ([0-9a-f]{40})$/
                key = "commit"
                value = $1
                if (parsing_descr == 1 || parsing_descr == 2)
                  parsing_descr = 0
                  revisions << Revision.new({:identifier => changeset[:commit],
                                             :scmid => changeset[:commit],
                                             :author => changeset[:author],
                                             :time => Time.parse(changeset[:date]),
                                             :message => changeset[:description],
                                             :paths => files
                                            })
                  changeset = {}
                  files = []
                  revno = revno + 1
                end
                changeset[:commit] = $1
              elsif (parsing_descr == 0) && line =~ /^(\w+):\s*(.*)$/
                key = $1
                value = $2
                if key == "Author"
                  changeset[:author] = value
                elsif key == "Date"
                  changeset[:date] = value
                end
              elsif (parsing_descr == 0) && line.chomp.to_s == ""
                parsing_descr = 1
                changeset[:description] = ""
              elsif (parsing_descr == 1 || parsing_descr == 2) && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\s+(.+)$/
                parsing_descr = 2
                fileaction = $1
                filepath = $2
                files << {:action => fileaction, :path => filepath}
              elsif (parsing_descr == 1) && line.chomp.to_s == ""
                parsing_descr = 2
              elsif (parsing_descr == 1)
                changeset[:description] << line[4..-1]
              end
            end	

            revisions << Revision.new({:identifier => changeset[:commit],
                                       :scmid => changeset[:commit],
                                       :author => changeset[:author],
                                       :time => Time.parse(changeset[:date]),
                                       :message => changeset[:description],
                                       :paths => files
                                      }) if changeset[:commit]

          end

          return nil if $? && $?.exitstatus != 0
          revisions
        end
        
        def diff(path, identifier_from, identifier_to=nil)
          path ||= ''
          if !identifier_to
            identifier_to = nil
          end
          
          cmd = "#{GIT_BIN} --git-dir #{target('')} show #{shell_quote identifier_from}" if identifier_to.nil?
          cmd = "#{GIT_BIN} --git-dir #{target('')} diff #{shell_quote identifier_to} #{shell_quote identifier_from}" if !identifier_to.nil?
          cmd << " -- #{shell_quote path}" unless path.empty?
          diff = []
          shellout(cmd) do |io|
            io.each_line do |line|
              diff << line
            end
          end
          return nil if $? && $?.exitstatus != 0
          diff
        end
        
        def annotate(path, identifier=nil)
          identifier = 'HEAD' if identifier.blank?
          cmd = "#{GIT_BIN} --git-dir #{target('')} blame -l #{shell_quote identifier} -- #{shell_quote path}"
          blame = Annotate.new
          content = nil
          shellout(cmd) { |io| io.binmode; content = io.read }
          return nil if $? && $?.exitstatus != 0
          # git annotates binary files
          return nil if content.is_binary_data?
          content.split("\n").each do |line|
            next unless line =~ /([0-9a-f]{39,40})\s\((\w*)[^\)]*\)(.*)/
            blame.add_line($3.rstrip, Revision.new(:identifier => $1, :author => $2.strip))
          end
          blame
        end
        
        def cat(path, identifier=nil)
          if identifier.nil?
            identifier = 'HEAD'
          end
          cmd = "#{GIT_BIN} --git-dir #{target('')} show #{shell_quote(identifier + ':' + path)}"
          cat = nil
          shellout(cmd) do |io|
            io.binmode
            cat = io.read
          end
          return nil if $? && $?.exitstatus != 0
          cat
        end
      end
    end
  end

end

