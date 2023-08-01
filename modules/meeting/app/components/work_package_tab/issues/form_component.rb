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

module WorkPackageTab
  class Issues::FormComponent < Base::Component
    include OpTurbo::Streamable

    def initialize(issue:)
      super

      @issue = issue
    end

    def call
      component_wrapper do
        primer_form_with(
          model: @issue,
          url: submit_path
        ) do |form|
          flex_layout do |flex|
            flex.with_row do
              render(Issue::Type.new(form))
            end
            flex.with_row(mt: 2) do
              render(Issue::Description.new(form))
            end
            flex.with_row(flex_layout: true, justify_content: :flex_end, mt: 2) do |flex|
              flex.with_column(mr: 2) do
                back_link_partial
              end
              flex.with_column do
                render(Issue::Submit.new(form))
              end
            end
          end
        end
      end
    end

    private

    def submit_path
      if @issue.persisted?
        work_package_issue_path(@issue.work_package, @issue)
      else
        work_package_issues_path(@issue.work_package)
      end
    end

    def back_link_partial
      link_to(open_work_package_issues_path(@issue.work_package)) do
        render(Primer::Beta::Button.new(
                 scheme: :secondary,
                 block: false,
                 mb: 3
               )) do |_component|
          "Cancel"
        end
      end
    end
  end
end
