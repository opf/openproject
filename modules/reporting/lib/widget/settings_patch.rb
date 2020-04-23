#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# explicitly require what will be patched to be loaded from the ReportingEngine
require_dependency 'widget/settings'

module Widget::SettingsPatch
  extend ActiveSupport::Concern

  included do
    prepend InstanceMethods
  end

  module InstanceMethods
    def settings_to_render
      super.insert(-2, :cost_types)
    end

    def render_cost_types_settings
      render_widget Widget::Settings::Fieldset, @subject, type: "units" do
        render_widget Widget::CostTypes,
                      @cost_types,
                      selected_type_id: @selected_type_id
      end
    end

    def render_with_options(options, &block)
      @cost_types = options.delete(:cost_types)
      @selected_type_id = options.delete(:selected_type_id)

      super(options, &block)
    end
  end
end

Widget::Settings.send(:include, Widget::SettingsPatch)
