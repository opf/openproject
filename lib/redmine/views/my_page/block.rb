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

module Redmine
  module Views
    module MyPage
      module Block
        def self.additional_blocks
          @@additional_blocks ||= Dir.glob("#{RAILS_ROOT}/vendor/plugins/*/app/views/my/blocks/_*.{rhtml,erb}").inject({}) do |h,file|
            name = File.basename(file).split('.').first.gsub(/^_/, '')
            h[name] = name.to_sym
            h
          end
        end
      end
    end
  end
end
