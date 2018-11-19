#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

#explicitly require what will be patched to be loaded from the ReportingEngine
require_dependency 'widget/settings'
class Widget::Settings < Widget::Base
  @@settings_to_render.insert -2, :cost_types

  def render_cost_types_settings
    render_widget Widget::Settings::Fieldset, @subject, { type: "units" } do
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
