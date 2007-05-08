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

require 'rexml/document'
require 'cgi'

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

    # get info about the svn repository
    def info
      cmd = "svn info --xml #{target('')}"
      cmd << " --username #{@login} --password #{@password}" if @login
      info = nil
      shellout(cmd) do |io|
        begin
          doc = REXML::Document.new(io)
          #root_url = doc.elements["info/entry/repository/root"].text          
          info = Info.new({:root_url => doc.elements["info/entry/repository/root"].text,
                           :lastrev => Revision.new({
                             :identifier => doc.elements["info/entry/commit"].attributes['revision'],
                             :time => Time.parse(doc.elements["info/entry/commit/date"].text),
                             :author => (doc.elements["info/entry/commit/author"] ? doc.elements["info/entry/commit/author"].text : "")
                           })
                         })
        rescue
        end
      end
      return nil if $? && $?.exitstatus != 0
      info
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
                          :author => (entry.elements['commit'].elements['author'] ? entry.elements['commit'].elements['author'].text : "")
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
                        :path => path.text,
                        :from_path => path.attributes['copyfrom-path'],
                        :from_revision => path.attributes['copyfrom-rev']
                        }
            end
            paths.sort! { |x,y| x[:path] <=> y[:path] }
            
            revisions << Revision.new({:identifier => logentry.attributes['revision'],
                          :author => (logentry.elements['author'] ? logentry.elements['author'].text : ""),
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
    
    def diff(path, identifier_from, identifier_to=nil, type="inline")
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
      DiffTableList.new diff, type

    rescue Errno::ENOENT => e
      raise CommandFailed    
    end
    
    def cat(path, identifier=nil)
      identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : "HEAD"
      cmd = "svn cat #{target(path)}@#{identifier}"
      cmd << " --username #{@login} --password #{@password}" if @login
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
  
  private    
    def retrieve_root_url
      info = self.info
      info ? info.root_url : nil
    end
    
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
  
  class Info
    attr_accessor :root_url, :lastrev
    def initialize(attributes={})
      self.root_url = attributes[:root_url] if attributes[:root_url]
      self.lastrev = attributes[:lastrev]
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
    
    def is_text?
      Redmine::MimeType.is_type?('text', name)
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

  # A line of Diff
  class Diff

    attr_accessor :nb_line_left
    attr_accessor :line_left
    attr_accessor :nb_line_right
    attr_accessor :line_right
    attr_accessor :type_diff_right
    attr_accessor :type_diff_left
    
    def initialize ()
      self.nb_line_left = ''
      self.nb_line_right = ''
      self.line_left = ''
      self.line_right = ''
      self.type_diff_right = ''
      self.type_diff_left = ''
    end

    def inspect
      puts '### Start Line Diff ###'
      puts self.nb_line_left
      puts self.line_left
      puts self.nb_line_right
      puts self.line_right
    end
  end

  class DiffTableList < Array

    def initialize (diff, type="inline")
        diff_table = DiffTable.new type
        diff.each do |line|
            if line =~ /^Index: (.*)$/
                self << diff_table if diff_table.length > 1
                diff_table = DiffTable.new type
            end
            a = diff_table.add_line line
        end
        self << diff_table
    end
  end

  # Class for create a Diff
  class DiffTable < Hash

    attr_reader :file_name, :line_num_l, :line_num_r    

    # Initialize with a Diff file and the type of Diff View
    # The type view must be inline or sbs (side_by_side)
    def initialize (type="inline")
      @parsing = false
      @nb_line = 1
      @start = false
      @before = 'same'
      @second = true
      @type = type
    end

    # Function for add a line of this Diff
    def add_line(line)
      unless @parsing
        if line =~ /^Index: (.*)$/
          @file_name = $1
          return false
        elsif line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
          @line_num_l = $2.to_i
          @line_num_r = $5.to_i
          @parsing = true
        end
      else
        if line =~ /^_+$/
          self.delete(self.keys.sort.last)
          @parsing = false
          return false
        elsif line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
          @line_num_l = $2.to_i
          @line_num_r = $5.to_i
        else
          @nb_line += 1 if parse_line(line, @type)          
        end
      end
      return true
    end

    def inspect
      puts '### DIFF TABLE ###'
      puts "file : #{file_name}"
      self.each do |d|
        d.inspect
      end
    end

  private

    # Test if is a Side By Side type
    def sbs?(type, func)
      if @start and type == "sbs"
        if @before == func and @second
          tmp_nb_line = @nb_line
          self[tmp_nb_line] = Diff.new
        else
            @second = false
            tmp_nb_line = @start
            @start += 1
            @nb_line -= 1
        end
      else
        tmp_nb_line = @nb_line
        @start = @nb_line
        self[tmp_nb_line] = Diff.new
        @second = true
      end
      unless self[tmp_nb_line]
        @nb_line += 1
        self[tmp_nb_line] = Diff.new
      else
        self[tmp_nb_line]
      end
    end

    # Escape the HTML for the diff
    def escapeHTML(line)
        CGI.escapeHTML(line).gsub(/\s/, '&nbsp;')
    end

    def parse_line (line, type="inline")
      if line[0, 1] == "+"
        diff = sbs? type, 'add'
        @before = 'add'
        diff.line_left = escapeHTML line[1..-1]
        diff.nb_line_left = @line_num_l
        diff.type_diff_left = 'diff_in'
        @line_num_l += 1
        true
      elsif line[0, 1] == "-"
        diff = sbs? type, 'remove'
        @before = 'remove'
        diff.line_right = escapeHTML line[1..-1]
        diff.nb_line_right = @line_num_r
        diff.type_diff_right = 'diff_out'
        @line_num_r += 1
        true
      elsif line[0, 1] =~ /\s/
        @before = 'same'
        @start = false
        diff = Diff.new
        diff.line_right = escapeHTML line[1..-1]
        diff.nb_line_right = @line_num_r
        diff.line_left = escapeHTML line[1..-1]
        diff.nb_line_left = @line_num_l
        self[@nb_line] = diff
        @line_num_l += 1
        @line_num_r += 1
        true
      else
        false
      end      
    end
  end
end