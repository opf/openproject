#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'redmine/scm/adapters/abstract_adapter'

module Redmine
  module Scm
    module Adapters
      class BazaarAdapter < AbstractAdapter

        # Bazaar executable name
        BZR_BIN = Redmine::Configuration['scm_bazaar_command'] || "bzr"

        class << self
          def client_command
            @@bin    ||= BZR_BIN
          end

          def sq_bin
            @@sq_bin ||= shell_quote(BZR_BIN)
          end

          def client_version
            @@client_version ||= (scm_command_version || [])
          end

          def client_available
            !client_version.empty?
          end

          def scm_command_version
            scm_version = scm_version_from_command_line.dup
            if scm_version.respond_to?(:force_encoding)
              scm_version.force_encoding('ASCII-8BIT')
            end
            if m = scm_version.match(%r{\A(.*?)((\d+\.)+\d+)})
              m[2].scan(%r{\d+}).collect(&:to_i)
            end
          end

          def scm_version_from_command_line
            shellout("#{sq_bin} --version") { |io| io.read }.to_s
          end
        end

        # Get info about the repository
        def info
          cmd = "#{self.class.sq_bin} revno #{target('')}"
          info = nil
          shellout(cmd) do |io|
            if io.read =~ %r{^(\d+)\r?$}
              info = Info.new({:root_url => url,
                               :lastrev => Revision.new({
                                 :identifier => $1
                               })
                             })
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
          entries = Entries.new
          cmd = "#{self.class.sq_bin} ls -v --show-ids"
          identifier = -1 unless identifier && identifier.to_i > 0 
          cmd << " -r#{identifier.to_i}" 
          cmd << " #{target(path)}"
          shellout(cmd) do |io|
            prefix = "#{url}/#{path}".gsub('\\', '/')
            logger.debug "PREFIX: #{prefix}"
            re = %r{^V\s+(#{Regexp.escape(prefix)})?(\/?)([^\/]+)(\/?)\s+(\S+)\r?$}
            io.each_line do |line|
              next unless line =~ re
              entries << Entry.new({:name => $3.strip,
                                    :path => ((path.empty? ? "" : "#{path}/") + $3.strip),
                                    :kind => ($4.blank? ? 'file' : 'dir'),
                                    :size => nil,
                                    :lastrev => Revision.new(:revision => $5.strip)
                                  })
            end
          end
          return nil if $? && $?.exitstatus != 0
          logger.debug("Found #{entries.size} entries in the repository for #{target(path)}") if logger && logger.debug?
          entries.sort_by_name
        end

        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          path ||= ''
          identifier_from = (identifier_from and identifier_from.to_i > 0) ? identifier_from.to_i : 'last:1'
          identifier_to = (identifier_to and identifier_to.to_i > 0) ? identifier_to.to_i : 1
          revisions = Revisions.new
          cmd = "#{self.class.sq_bin} log -v --show-ids -r#{identifier_to}..#{identifier_from} #{target(path)}"
          shellout(cmd) do |io|
            revision = nil
            parsing = nil
            io.each_line do |line|
              if line =~ /^----/
                revisions << revision if revision
                revision = Revision.new(:paths => [], :message => '')
                parsing = nil
              else
                next unless revision
                
                if line =~ /^revno: (\d+)($|\s\[merge\]$)/
                  revision.identifier = $1.to_i
                elsif line =~ /^committer: (.+)$/
                  revision.author = $1.strip
                elsif line =~ /^revision-id:(.+)$/
                  revision.scmid = $1.strip
                elsif line =~ /^timestamp: (.+)$/
                  revision.time = Time.parse($1).localtime
                elsif line =~ /^    -----/
                  # partial revisions
                  parsing = nil unless parsing == 'message'
                elsif line =~ /^(message|added|modified|removed|renamed):/
                  parsing = $1
                elsif line =~ /^  (.*)$/
                  if parsing == 'message'
                    revision.message << "#{$1}\n"
                  else
                    if $1 =~ /^(.*)\s+(\S+)$/
                      path = $1.strip
                      revid = $2
                      case parsing
                      when 'added'
                        revision.paths << {:action => 'A', :path => "/#{path}", :revision => revid}
                      when 'modified'
                        revision.paths << {:action => 'M', :path => "/#{path}", :revision => revid}
                      when 'removed'
                        revision.paths << {:action => 'D', :path => "/#{path}", :revision => revid}
                      when 'renamed'
                        new_path = path.split('=>').last
                        revision.paths << {:action => 'M', :path => "/#{new_path.strip}", :revision => revid} if new_path
                      end
                    end
                  end
                else
                  parsing = nil
                end
              end
            end
            revisions << revision if revision
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
          cmd = "#{self.class.sq_bin} diff -r#{identifier_to}..#{identifier_from} #{target(path)}"
          diff = []
          shellout(cmd) do |io|
            io.each_line do |line|
              diff << line
            end
          end
          #return nil if $? && $?.exitstatus != 0
          diff
        end

        def cat(path, identifier=nil)
          cmd = "#{self.class.sq_bin} cat"
          cmd << " -r#{identifier.to_i}" if identifier && identifier.to_i > 0
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
          cmd = "#{self.class.sq_bin} annotate --all"
          cmd << " -r#{identifier.to_i}" if identifier && identifier.to_i > 0
          cmd << " #{target(path)}"
          blame = Annotate.new
          shellout(cmd) do |io|
            author = nil
            identifier = nil
            io.each_line do |line|
              next unless line =~ %r{^(\d+) ([^|]+)\| (.*)$}
              blame.add_line($3.rstrip, Revision.new(:identifier => $1.to_i, :author => $2.strip))
            end
          end
          return nil if $? && $?.exitstatus != 0
          blame
        end
      end
    end
  end
end
