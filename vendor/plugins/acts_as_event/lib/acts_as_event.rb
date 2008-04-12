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

module Redmine
  module Acts
    module Event
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_event(options = {})
          return if self.included_modules.include?(Redmine::Acts::Event::InstanceMethods)
          options[:datetime] ||= :created_on
          options[:title] ||= :title
          options[:description] ||= :description
          options[:author] ||= :author
          options[:url] ||= {:controller => 'welcome'}
          options[:type] ||= self.name.underscore.dasherize
          cattr_accessor :event_options
          self.event_options = options 
          send :include, Redmine::Acts::Event::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        %w(datetime title description author type).each do |attr|
          src = <<-END_SRC
            def event_#{attr}
              option = event_options[:#{attr}]
              if option.is_a?(Proc)
                option.call(self)
              elsif option.is_a?(Symbol)
                send(option)
              else
                option
              end
            end
          END_SRC
          class_eval src, __FILE__, __LINE__
        end
        
        def event_date
          event_datetime.to_date
        end
        
        def event_url(options = {})
          option = event_options[:url]
          (option.is_a?(Proc) ? option.call(self) : send(option)).merge(options)
        end

        module ClassMethods
        end
      end
    end
  end
end
