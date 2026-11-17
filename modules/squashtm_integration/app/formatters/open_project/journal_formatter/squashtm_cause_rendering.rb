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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::JournalFormatter::SquashTMCauseRendering
  def render(key, values, options = { html: true })
    return super unless Journal::SQUASHTM_CAUSE_TYPES.include?(values.last["type"])

    @cause = values.last
    @html = options[:html]

    "#{caused_change} #{squashtm_requirement_description}"
  end

  private

  # Users who cannot see the SquashTM test results only get the id of the requirement, not its name or reference.
  # Ideally, we wouldn't show the journal entry at all, but there seems to be no easy way to do that.
  def squashtm_requirement_description
    unless squashtm_details_visible?
      return I18n.t("journals.cause_descriptions.squashtm_requirement_id_only", id: cause["squashtm_requirement_id"])
    end

    reference = cause["squashtm_requirement_reference"]

    I18n.t("journals.cause_descriptions.squashtm_requirement#{'_with_reference' if reference.present?}",
           name: squashtm_escape(cause["squashtm_requirement_name"]),
           reference: squashtm_escape(reference))
  end

  def squashtm_details_visible?
    User.current.allowed_in_project?(:view_squashtm, @journal.journable.project)
  end

  def squashtm_escape(value)
    html? ? h(value) : value
  end
end
