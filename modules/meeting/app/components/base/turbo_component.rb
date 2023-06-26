#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Base
  class TurboComponent < ViewComponent::Base
    def self.replace_via_turbo_stream(**kwargs)
      component_instance = self.new(**kwargs)
      Base::TurboStreamWrapper.new(
        action: :replace, 
        target: component_instance.wrapper_key, 
        template: component_instance.render_in(kwargs[:view_context])
      ).render_in(kwargs[:view_context])
    end

    def component_wrapper(tag: "div", id: nil, class: nil, data: nil, &block)
      content_tag(tag, id: id || wrapper_key, class:, data:, &block)
    end

    def self.wrapper_key
      self.name.underscore.gsub("/", "-").gsub("_", "-")
    end

    def wrapper_key
      if wrapper_id.nil?
        self.class.wrapper_key
      else
        "#{self.class.wrapper_key}-#{wrapper_id}"
      end
    end

    def wrapper_id
      # optionally implemented in subclass in order to make the wrapper key unique
    end
  end
end
