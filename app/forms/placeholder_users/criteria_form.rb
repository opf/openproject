# frozen_string_literal: true

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

module PlaceholderUsers
  class CriteriaForm < ApplicationForm
    form do |f|
      f.html_content do
        # The filter builder emits its fields into the surrounding form, so it
        # needs that form's Primer builder rather than this form object.
        render(Filters::FilterFormComponent.new(
                 builder: @builder,
                 query: model.candidate_query,
                 wrap_with_controller: true,
                 hidden_input_name: "filters",
                 output_format: :json,
                 **live_update_arguments
               ))
      end

      next unless submit?

      f.submit(
        name: :submit,
        label: I18n.t(:button_save),
        scheme: :primary
      )
    end

    def initialize(submit: true, live_update_path: nil)
      super()
      @submit = submit
      @live_update_path = live_update_path
    end

    private

    def submit? = @submit

    def live_update_arguments
      return {} if @live_update_path.blank?

      {
        data: {
          filter__filters_form_turbo_stream_request_value: true,
          filter__filters_form_url_path_name_value: @live_update_path
        }
      }
    end
  end
end
