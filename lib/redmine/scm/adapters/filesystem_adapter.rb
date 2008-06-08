# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# FileSystem adapter
# File written by Paul Rivier, at Demotera.
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
require 'find'

module Redmine
  module Scm
    module Adapters    
      class FilesystemAdapter < AbstractAdapter
        

        def initialize(url, root_url=nil, login=nil, password=nil)
          @url = with_trailling_slash(url)
        end

        def format_path_ends(path, leading=true, trailling=true)
          path = leading ? with_leading_slash(path) : 
            without_leading_slash(path)
          trailling ? with_trailling_slash(path) : 
            without_trailling_slash(path) 
        end

        def info
          info = Info.new({:root_url => target(),
                            :lastrev => nil
                          })
          info
        rescue CommandFailed
          return nil
        end
        
        def entries(path="", identifier=nil)
          entries = Entries.new
          Dir.new(target(path)).each do |e|
            relative_path = format_path_ends((format_path_ends(path,
                                                               false,
                                                               true) + e),
                                             false,false)
            target = target(relative_path)
            entries << 
              Entry.new({ :name => File.basename(e),
                          # below : list unreadable files, but dont link them.
                          :path => File.readable?(target) ? relative_path : "",
                          :kind => (File.directory?(target) ? 'dir' : 'file'),
                          :size => (File.directory?(target) ? nil : [File.size(target)].pack('l').unpack('L').first),
                          :lastrev => 
                          Revision.new({:time => (File.mtime(target)).localtime,
                                       })
                        }) if File.exist?(target) and # paranoid test
              %w{file directory}.include?(File.ftype(target)) and # avoid special types
              not File.basename(e).match(/^\.+$/) # avoid . and ..             
          end
          entries.sort_by_name
        end
        
        def cat(path, identifier=nil)
          File.new(target(path)).read
        end

        private
        
        # AbstractAdapter::target is implicitly made to quote paths.
        # Here we do not shell-out, so we do not want quotes.
        def target(path=nil)
          #Prevent the use of ..
          if path and !path.match(/(^|\/)\.\.(\/|$)/)
            return "#{self.url}#{without_leading_slash(path)}"
          end
          return self.url
        end
        
      end
    end
  end
end
