# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

require 'rexml/document'

module SvnRepos

  class CommandFailed < StandardError #:nodoc:
  end

  class Base
        
    def initialize(url, root_url=nil, login=nil, password=nil)
      @url = url
      @login = login if login && !login.empty?
      @password = (password || "") if @login    
      @root_url = root_url.blank? ? retrieve_root_url : root_url
    end
    
    def root_url
      @root_url
    end
    
    def url
      @url
    end

    # finds the root url of the svn repository
    def retrieve_root_url
      cmd = "svn info --xml #{target('')}"
      cmd << " --username #{@login} --password #{@password}" if @login
      root_url = nil
      shellout(cmd) do |io|
        begin
          doc = REXML::Document.new(io)
          root_url = doc.elements["info/entry/repository/root"].text
        rescue
        end
      end
      return nil if $? && $?.exitstatus != 0
      root_url
    rescue Errno::ENOENT => e
      return nil
    end
    
    # Returns the entry identified by path and revision identifier
    # or nil if entry doesn't exist in the repository
    def entry(path=nil, identifier=nil)
      e = entries(path, identifier)
      e ? e.first : nil
    end
    
    # Returns an Entries collection
    # or nil if the given path doesn't exist in the repository
    def entries(path=nil, identifier=nil)
      path ||= ''
      identifier = 'HEAD' unless identifier and identifier > 0
      entries = Entries.new
      cmd = "svn list --xml #{target(path)}@#{identifier}"
      cmd << " --username #{@login} --password #{@password}" if @login
      shellout(cmd) do |io|
        begin
          doc = REXML::Document.new(io)
          doc.elements.each("lists/list/entry") do |entry|
            entries << Entry.new({:name => entry.elements['name'].text,
                        :path => ((path.empty? ? "" : "#{path}/") + entry.elements['name'].text),
                        :kind => entry.attributes['kind'],
                        :size => (entry.elements['size'] and entry.elements['size'].text).to_i,
                        :lastrev => Revision.new({
                          :identifier => entry.elements['commit'].attributes['revision'],
                          :time => Time.parse(entry.elements['commit'].elements['date'].text),
                          :author => (entry.elements['commit'].elements['author'] ? entry.elements['commit'].elements['author'].text : "anonymous")
                          })
                        })
          end
        rescue
        end
      end
      return nil if $? && $?.exitstatus != 0
      entries.sort_by_name
    rescue Errno::ENOENT => e
      raise CommandFailed
    end

    def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
      path ||= ''
      identifier_from = 'HEAD' unless identifier_from and identifier_from.to_i > 0
      identifier_to = 1 unless identifier_to and identifier_to.to_i > 0
      revisions = Revisions.new
      cmd = "svn log --xml -r #{identifier_from}:#{identifier_to}"
      cmd << " --username #{@login} --password #{@password}" if @login
      cmd << " --verbose " if  options[:with_paths]
      cmd << target(path)
      shellout(cmd) do |io|
        begin
          doc = REXML::Document.new(io)
          doc.elements.each("log/logentry") do |logentry|
            paths = []
            logentry.elements.each("paths/path") do |path|
              paths << {:action => path.attributes['action'],
                        :path => path.text
                        }
            end
            paths.sort! { |x,y| x[:path] <=> y[:path] }
            
            revisions << Revision.new({:identifier => logentry.attributes['revision'],
                          :author => (logentry.elements['author'] ? logentry.elements['author'].text : "anonymous"),
                          :time => Time.parse(logentry.elements['date'].text),
                          :message => logentry.elements['msg'].text,
                          :paths => paths
                        })
          end
        rescue
        end
      end
      return nil if $? && $?.exitstatus != 0
      revisions
    rescue Errno::ENOENT => e
      raise CommandFailed    
    end
    
    def diff(path, identifier_from, identifier_to=nil)
      path ||= ''
      if identifier_to and identifier_to.to_i > 0
        identifier_to = identifier_to.to_i 
      else
        identifier_to = identifier_from.to_i - 1
      end
      cmd = "svn diff -r "
      cmd << "#{identifier_to}:"
      cmd << "#{identifier_from}"
      cmd << "#{target(path)}@#{identifier_from}"
      cmd << " --username #{@login} --password #{@password}" if @login
      diff = []
      shellout(cmd) do |io|
        io.each_line do |line|
          diff << line
        end
      end
      return nil if $? && $?.exitstatus != 0
      diff
    rescue Errno::ENOENT => e
      raise CommandFailed    
    end
    
    def cat(path, identifier=nil)
      identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : "HEAD"
      cmd = "svn cat #{target(path)}@#{identifier}"
      cmd << " --username #{@login} --password #{@password}" if @login
      cat = nil
      shellout(cmd) do |io|
        cat = io.read
      end
      return nil if $? && $?.exitstatus != 0
      cat
    rescue Errno::ENOENT => e
      raise CommandFailed    
    end
  
  private
    def target(path)
      path ||= ""
      base = path.match(/^\//) ? root_url : url    
      " \"" << "#{base}/#{path}".gsub(/["'?<>\*]/, '') << "\""
    end
    
    def logger
      RAILS_DEFAULT_LOGGER
    end
    
    def shellout(cmd, &block)
      logger.debug "Shelling out: #{cmd}" if logger && logger.debug?
      IO.popen(cmd, "r+") do |io|
        io.close_write
        block.call(io) if block_given?
      end
    end
  end
  
  class Entries < Array
    def sort_by_name
      sort {|x,y| 
        if x.kind == y.kind
          x.name <=> y.name
        else
          x.kind <=> y.kind
        end
      }   
    end
    
    def revisions
      revisions ||= Revisions.new(collect{|entry| entry.lastrev})
    end
  end
  
  class Entry
    attr_accessor :name, :path, :kind, :size, :lastrev
    def initialize(attributes={})
      self.name = attributes[:name] if attributes[:name]
      self.path = attributes[:path] if attributes[:path]
      self.kind = attributes[:kind] if attributes[:kind]
      self.size = attributes[:size].to_i if attributes[:size]
      self.lastrev = attributes[:lastrev]
    end
    
    def is_file?
      'file' == self.kind
    end
    
    def is_dir?
      'dir' == self.kind
    end
  end
  
  class Revisions < Array
    def latest
      sort {|x,y| x.time <=> y.time}.last    
    end 
  end
  
  class Revision
    attr_accessor :identifier, :author, :time, :message, :paths
    def initialize(attributes={})
      self.identifier = attributes[:identifier]
      self.author = attributes[:author]
      self.time = attributes[:time]
      self.message = attributes[:message] || ""
      self.paths = attributes[:paths]
    end
  end
end