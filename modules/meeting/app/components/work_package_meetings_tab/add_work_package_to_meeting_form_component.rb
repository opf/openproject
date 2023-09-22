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

module WorkPackageMeetingsTab
  class AddWorkPackageToMeetingFormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(work_package:, meeting_agenda_item: nil, base_errors: nil)
      super

      @work_package = work_package
      @meeting_agenda_item = meeting_agenda_item || MeetingAgendaItem.new(work_package: @work_package)
      @base_errors = base_errors
    end

    def call
      component_wrapper do
        primer_form_with(
          model: @meeting_agenda_item,
          method: :post,
          url: work_package_meeting_agenda_items_path(@work_package)
        ) do |f|
          component_collection do |collection|
            collection.with_component(Primer::Alpha::Dialog::Body.new(test_selector: 'op-add-work-package-to-meeting-dialog-body')) do
              form_content_partial(f)
            end
            collection.with_component(Primer::Alpha::Dialog::Footer.new) do
              form_actions_partial
            end
          end
        end
      end
    end

    private

    def form_content_partial(form)
      flex_layout(my: 3) do |flex|
        flex.with_row do
          base_error_partial
        end
        flex.with_row do
          # TODO: Autocomplete based on Rails rendered options needed here
          render(MeetingAgendaItem::MeetingForm.new(form))
        end
        flex.with_row(mt: 3) do
          # TODO: RTE toolbar not properly rendered
          render(MeetingAgendaItem::Notes.new(form))
        end
      end
    end

    def base_error_partial
      if @base_errors&.any?
        render(Primer::Beta::Flash.new(mb: 3, icon: :stop, scheme: :danger)) { @base_errors.join("\n") }
      end
    end

    def form_actions_partial
      component_collection do |collection|
        collection.with_component(Primer::ButtonComponent.new(data: { 'close-dialog-id': "add-work-package-to-meeting-dialog" })) do
          t("button_cancel")
        end
        collection.with_component(Primer::ButtonComponent.new(scheme: :primary, type: :submit)) do
          t("button_save")
        end
      end
    end
  end
end
