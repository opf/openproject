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
require 'find'

module Redmine
  module Scm
    module Adapters
      class FilesystemAdapter < AbstractAdapter

        class << self
          def client_available
            true
          end
        end

        def initialize(url, root_url=nil, login=nil, password=nil,
                       path_encoding=nil)
          @url = with_trailling_slash(url)
          @path_encoding = path_encoding || 'UTF-8'
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
          trgt_utf8 = target(path)
          trgt = scm_iconv(@path_encoding, 'UTF-8', trgt_utf8)
          Dir.new(trgt).each do |e1|
            e_utf8 = scm_iconv('UTF-8', @path_encoding, e1)
            next if e_utf8.blank? 
            relative_path_utf8 = format_path_ends(
                (format_path_ends(path,false,true) + e_utf8),false,false)
            t1_utf8 = target(relative_path_utf8)
            t1 = scm_iconv(@path_encoding, 'UTF-8', t1_utf8)
            relative_path = scm_iconv(@path_encoding, 'UTF-8', relative_path_utf8)
            e1 = scm_iconv(@path_encoding, 'UTF-8', e_utf8)
            if File.exist?(t1) and # paranoid test
                  %w{file directory}.include?(File.ftype(t1)) and # avoid special types
                  not File.basename(e1).match(/^\.+$/) # avoid . and ..
              p1         = File.readable?(t1) ? relative_path : ""
              utf_8_path = scm_iconv('UTF-8', @path_encoding, p1)
              entries <<
                Entry.new({ :name => scm_iconv('UTF-8', @path_encoding, File.basename(e1)),
                          # below : list unreadable files, but dont link them.
                          :path => utf_8_path,
                          :kind => (File.directory?(t1) ? 'dir' : 'file'),
                          :size => (File.directory?(t1) ? nil : [File.size(t1)].pack('l').unpack('L').first),
                          :lastrev => 
                              Revision.new({:time => (File.mtime(t1)) })
                        })
            end
          end
          entries.sort_by_name
        rescue  => err
          logger.error "scm: filesystem: error: #{err.message}"
          raise CommandFailed.new(err.message)
        end

        def cat(path, identifier=nil)
          p = scm_iconv(@path_encoding, 'UTF-8', target(path))
          File.new(p, "rb").read
        rescue  => err
          logger.error "scm: filesystem: error: #{err.message}"
          raise CommandFailed.new(err.message)
        end

        private

        # AbstractAdapter::target is implicitly made to quote paths.
        # Here we do not shell-out, so we do not want quotes.
        def target(path=nil)
          # Prevent the use of ..
          if path and !path.match(/(^|\/)\.\.(\/|$)/)
            return "#{self.url}#{without_leading_slash(path)}"
          end
          return self.url
        end
      end
    end
  end
end
