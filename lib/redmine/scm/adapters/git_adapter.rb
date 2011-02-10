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
        GIT_BIN = Redmine::Configuration['scm_git_command'] || "git"

        def info
          begin
            Info.new(:root_url => url, :lastrev => lastrev('',nil))
          rescue
            nil
          end
        end

        def branches
          return @branches if @branches
          @branches = []
          cmd = "#{GIT_BIN} --git-dir #{target('')} branch --no-color"
          shellout(cmd) do |io|
            io.each_line do |line|
              @branches << line.match('\s*\*?\s*(.*)$')[1]
            end
          end
          @branches.sort!
        end

        def tags
          return @tags if @tags
          cmd = "#{GIT_BIN} --git-dir #{target('')} tag"
          shellout(cmd) do |io|
            @tags = io.readlines.sort!.map{|t| t.strip}
          end
        end

        def default_branch
          branches.include?('master') ? 'master' : branches.first 
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
              if e =~ /^\d+\s+(\w+)\s+([0-9a-f]{40})\s+([0-9-]+)\t(.+)$/
                type = $1
                sha = $2
                size = $3
                name = $4
                full_path = path.empty? ? name : "#{path}/#{name}"
                entries << Entry.new({:name => name,
                 :path => full_path,
                 :kind => (type == "tree") ? 'dir' : 'file',
                 :size => (type == "tree") ? nil : size,
                 :lastrev => lastrev(full_path,identifier)
                }) unless entries.detect{|entry| entry.name == name}
              end
            end
          end
          return nil if $? && $?.exitstatus != 0
          entries.sort_by_name
        end

        def lastrev(path,rev)
          return nil if path.nil?
          cmd = "#{GIT_BIN} --git-dir #{target('')} log --no-color --date=iso --pretty=fuller --no-merges -n 1 "
          cmd << " #{shell_quote rev} " if rev 
          cmd <<  "-- #{shell_quote path} " unless path.empty?
          lines = []
          shellout(cmd) { |io| lines = io.readlines }
          return nil if $? && $?.exitstatus != 0
          begin
              id = lines[0].split[1]
              author = lines[1].match('Author:\s+(.*)$')[1]
              time = Time.parse(lines[4].match('CommitDate:\s+(.*)$')[1]).localtime

              Revision.new({
                :identifier => id,
                :scmid => id,
                :author => author, 
                :time => time,
                :message => nil, 
                :paths => nil 
              })
          rescue NoMethodError => e
              logger.error("The revision '#{path}' has a wrong format")
              return nil
          end
        end

        def revisions(path, identifier_from, identifier_to, options={})
          revisions = Revisions.new

          cmd = "#{GIT_BIN} --git-dir #{target('')} log --no-color --raw --date=iso --pretty=fuller "
          cmd << " --reverse " if options[:reverse]
          cmd << " --all " if options[:all]
          cmd << " -n #{options[:limit].to_i} " if options[:limit]
          cmd << "#{shell_quote(identifier_from + '..')}" if identifier_from
          cmd << "#{shell_quote identifier_to}" if identifier_to
          cmd << " --since=#{shell_quote(options[:since].strftime("%Y-%m-%d %H:%M:%S"))}" if options[:since]
          cmd << " -- #{shell_quote path}" if path && !path.empty?

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
                  revision = Revision.new({
                    :identifier => changeset[:commit],
                    :scmid => changeset[:commit],
                    :author => changeset[:author],
                    :time => Time.parse(changeset[:date]),
                    :message => changeset[:description],
                    :paths => files
                  })
                  if block_given?
                    yield revision
                  else
                    revisions << revision
                  end
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
                elsif key == "CommitDate"
                  changeset[:date] = value
                end
              elsif (parsing_descr == 0) && line.chomp.to_s == ""
                parsing_descr = 1
                changeset[:description] = ""
              elsif (parsing_descr == 1 || parsing_descr == 2) \
              && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\t(.+)$/
                parsing_descr = 2
                fileaction = $1
                filepath = $2
                files << {:action => fileaction, :path => filepath}
              elsif (parsing_descr == 1 || parsing_descr == 2) \
              && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\d+\s+(\S+)\t(.+)$/
                parsing_descr = 2
                fileaction = $1
                filepath = $3
                files << {:action => fileaction, :path => filepath}
              elsif (parsing_descr == 1) && line.chomp.to_s == ""
                parsing_descr = 2
              elsif (parsing_descr == 1)
                changeset[:description] << line[4..-1]
              end
            end 

            if changeset[:commit]
              revision = Revision.new({
                :identifier => changeset[:commit],
                :scmid => changeset[:commit],
                :author => changeset[:author],
                :time => Time.parse(changeset[:date]),
                :message => changeset[:description],
                :paths => files
              })

              if block_given?
                yield revision
              else
                revisions << revision
              end
            end
          end

          return nil if $? && $?.exitstatus != 0
          revisions
        end

        def diff(path, identifier_from, identifier_to=nil)
          path ||= ''

          if identifier_to
            cmd = "#{GIT_BIN} --git-dir #{target('')} diff --no-color #{shell_quote identifier_to} #{shell_quote identifier_from}" 
          else
            cmd = "#{GIT_BIN} --git-dir #{target('')} show --no-color #{shell_quote identifier_from}"
          end

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
          cmd = "#{GIT_BIN} --git-dir #{target('')} blame -p #{shell_quote identifier} -- #{shell_quote path}"
          blame = Annotate.new
          content = nil
          shellout(cmd) { |io| io.binmode; content = io.read }
          return nil if $? && $?.exitstatus != 0
          # git annotates binary files
          return nil if content.is_binary_data?
          identifier = ''
          # git shows commit author on the first occurrence only
          authors_by_commit = {}
          content.split("\n").each do |line|
            if line =~ /^([0-9a-f]{39,40})\s.*/
              identifier = $1
            elsif line =~ /^author (.+)/
              authors_by_commit[identifier] = $1.strip
            elsif line =~ /^\t(.*)/
              blame.add_line($1, Revision.new(:identifier => identifier, :author => authors_by_commit[identifier]))
              identifier = ''
              author = ''
            end
          end
          blame
        end
        
        def cat(path, identifier=nil)
          if identifier.nil?
            identifier = 'HEAD'
          end
          cmd = "#{GIT_BIN} --git-dir #{target('')} show --no-color #{shell_quote(identifier + ':' + path)}"
          cat = nil
          shellout(cmd) do |io|
            io.binmode
            cat = io.read
          end
          return nil if $? && $?.exitstatus != 0
          cat
        end

        class Revision < Redmine::Scm::Adapters::Revision
          # Returns the readable identifier
          def format_identifier
            identifier[0,8]
          end
        end
      end
    end
  end
end
