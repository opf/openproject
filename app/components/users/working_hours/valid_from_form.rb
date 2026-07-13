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

class Users::WorkingHours::ValidFromForm < ApplicationForm
  form do |f|
    f.html_content do
      render(Primer::Beta::Subhead.new) do |component|
        component.with_heading(tag: :div, size: :medium) do
          I18n.t("users.working_hours.form.title_future_dates")
        end
      end
    end

    f.single_date_picker name: :valid_from,
                         type: "date",
                         required: true,
                         input_width: :large,
                         datepicker_options: { inDialog: Users::WorkingHours::DialogComponent::DIALOG_ID },
                         value: model.valid_from&.iso8601,
                         caption: I18n.t("users.working_hours.form.start_date_caption"),
                         label: I18n.t("users.working_hours.form.start_date")
  end
end
