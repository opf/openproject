#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See COPYRIGHT and LICENSE files for more details.
#++

# This now only seems to be used when rendering atom responses.
# Search as well as activities do not rely on it.
# Thus, whenever an atom link is removed for a resource, acts_as_event within that model can also be removed.

module Redmine
  module Acts
    module Event
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_event(options = {})
          return if included_modules.include?(Redmine::Acts::Event::InstanceMethods)

          default_options = { datetime: :created_at,
                              title: :title,
                              description: :description,
                              author: :author,
                              url: { controller: "/welcome" },
                              name: Proc.new { ::I18n.t(name.underscore, scope: "events") },
                              type: name.underscore.dasherize }

          cattr_accessor :event_options
          self.event_options = default_options.merge(options)
          send :include, Redmine::Acts::Event::InstanceMethods
        end
      end

      module InstanceMethods
        %w(datetime title description author name type).each do |attr|
          src = <<-END_SRC
            def event_#{attr}
              option = event_options[:#{attr}]
              if option.is_a?(Proc)
                option.call(self)
              elsif option.is_a?(Symbol)
                if respond_to?(:journal) and journal.respond_to?(option)
                  journal.send(option)
                else
                  send(option)
                end
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
          if option.is_a?(Proc)
            option.call(self).merge(options)
          elsif option.is_a?(Hash)
            option.merge(options)
          elsif option.is_a?(Symbol)
            send(option).merge(options)
          else
            option
          end
        end
      end
    end
  end
end
