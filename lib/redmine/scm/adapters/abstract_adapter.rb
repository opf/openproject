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

require 'cgi'

module Redmine
  module Scm
    module Adapters    
      class CommandFailed < StandardError #:nodoc:
      end
      
      class AbstractAdapter #:nodoc:
        def initialize(url, root_url=nil, login=nil, password=nil)
          @url = url
          @login = login if login && !login.empty?
          @password = (password || "") if @login
          @root_url = root_url.blank? ? retrieve_root_url : root_url
        end
        
        def adapter_name
          'Abstract'
        end
        
        def supports_cat?
          true
        end

        def supports_annotate?
          respond_to?('annotate')
        end
        
        def root_url
          @root_url
        end
      
        def url
          @url
        end
      
        # get info about the svn repository
        def info
          return nil
        end
        
        # Returns the entry identified by path and revision identifier
        # or nil if entry doesn't exist in the repository
        def entry(path=nil, identifier=nil)
          parts = path.to_s.split(%r{[\/\\]}).select {|n| !n.blank?}
          search_path = parts[0..-2].join('/')
          search_name = parts[-1]
          if search_path.blank? && search_name.blank?
            # Root entry
            Entry.new(:path => '', :kind => 'dir')
          else
            # Search for the entry in the parent directory
            es = entries(search_path, identifier)
            es ? es.detect {|e| e.name == search_name} : nil
          end
        end
        
        # Returns an Entries collection
        # or nil if the given path doesn't exist in the repository
        def entries(path=nil, identifier=nil)
          return nil
        end
    
        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          return nil
        end
        
        def diff(path, identifier_from, identifier_to=nil, type="inline")
          return nil
        end
        
        def cat(path, identifier=nil)
          return nil
        end
        
        def with_leading_slash(path)
          path ||= ''
          (path[0,1]!="/") ? "/#{path}" : path
        end

        def with_trailling_slash(path)
          path ||= ''
          (path[-1,1] == "/") ? path : "#{path}/"
        end
        
        def without_leading_slash(path)
          path ||= ''
          path.gsub(%r{^/+}, '')
        end

        def without_trailling_slash(path)
          path ||= ''
          (path[-1,1] == "/") ? path[0..-2] : path
         end
        
        def shell_quote(str)
          if RUBY_PLATFORM =~ /mswin/
            '"' + str.gsub(/"/, '\\"') + '"'
          else
            "'" + str.gsub(/'/, "'\"'\"'") + "'"
          end
        end

      private
        def retrieve_root_url
          info = self.info
          info ? info.root_url : nil
        end
        
        def target(path)
          path ||= ''
          base = path.match(/^\//) ? root_url : url
          shell_quote("#{base}/#{path}".gsub(/[?<>\*]/, ''))
        end
            
        def logger
          RAILS_DEFAULT_LOGGER
        end
        
        def shellout(cmd, &block)
          logger.debug "Shelling out: #{cmd}" if logger && logger.debug?
          begin
            IO.popen(cmd, "r+") do |io|
              io.close_write
              block.call(io) if block_given?
            end
          rescue Errno::ENOENT => e
            msg = strip_credential(e.message)
            # The command failed, log it and re-raise
            logger.error("SCM command failed: #{strip_credential(cmd)}\n  with: #{msg}")
            raise CommandFailed.new(msg)
          end
        end  
        
        # Hides username/password in a given command
        def self.hide_credential(cmd)
          q = (RUBY_PLATFORM =~ /mswin/ ? '"' : "'")
          cmd.to_s.gsub(/(\-\-(password|username))\s+(#{q}[^#{q}]+#{q}|[^#{q}]\S+)/, '\\1 xxxx')
        end
        
        def strip_credential(cmd)
          self.class.hide_credential(cmd)
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
          revisions ||= Revisions.new(collect{|entry| entry.lastrev}.compact)
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
          sort {|x,y|
            unless x.time.nil? or y.time.nil?
              x.time <=> y.time
            else
              0
            end
          }.last
        end 
      end
      
      class Revision
        attr_accessor :identifier, :scmid, :name, :author, :time, :message, :paths, :revision, :branch
        def initialize(attributes={})
          self.identifier = attributes[:identifier]
          self.scmid = attributes[:scmid]
          self.name = attributes[:name] || self.identifier
          self.author = attributes[:author]
          self.time = attributes[:time]
          self.message = attributes[:message] || ""
          self.paths = attributes[:paths]
          self.revision = attributes[:revision]
          self.branch = attributes[:branch]
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
                if line =~ /^(---|\+\+\+) (.*)$/
                    self << diff_table if diff_table.length > 1
                    diff_table = DiffTable.new type
                end
                a = diff_table.add_line line
            end
            self << diff_table unless diff_table.empty?
            self
        end
      end
    
      # Class for create a Diff
      class DiffTable < Hash  
        attr_reader :file_name, :line_num_l, :line_num_r    
    
        # Initialize with a Diff file and the type of Diff View
        # The type view must be inline or sbs (side_by_side)
        def initialize(type="inline")
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
            if line =~ /^(---|\+\+\+) (.*)$/
              @file_name = $2
              return false
            elsif line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
              @line_num_l = $5.to_i
              @line_num_r = $2.to_i
              @parsing = true
            end
          else
            if line =~ /^[^\+\-\s@\\]/
              @parsing = false
              return false
            elsif line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
              @line_num_l = $5.to_i
              @line_num_r = $2.to_i
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
            CGI.escapeHTML(line)
        end
    
        def parse_line(line, type="inline")
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
          elsif line[0, 1] = "\\"
            true
          else
            false
          end
        end
      end
    
      class Annotate
        attr_reader :lines, :revisions
        
        def initialize
          @lines = []
          @revisions = []
        end
        
        def add_line(line, revision)
          @lines << line
          @revisions << revision
        end
        
        def content
          content = lines.join("\n")
        end
        
        def empty?
          lines.empty?
        end
      end
    end
  end
end
