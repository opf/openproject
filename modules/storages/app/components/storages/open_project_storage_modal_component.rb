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

class Storages::OpenProjectStorageModalComponent < ViewComponent::Base
  attr_reader :controller, :project_storage_open_url, :redirect_url, :state

  def initialize(project_storage_open_url:, redirect_url:, state:, **options)
    super()
    @controller = "storages--open-project-storage-modal"
    @project_storage_open_url = project_storage_open_url
    @redirect_url = redirect_url
    @state = state
  end

  def self.dialog_id
    "open-project-storage-modal-component"
  end

  def self.dialog_body_id
    "open-project-storage-modal-body-component"
  end

  def data
    @data ||= {
      controller:,
      "#{controller}-project-storage-open-url-value": project_storage_open_url,
      "#{controller}-redirect-url-value": redirect_url,
      "#{controller}-subtitle-timeout-text-value": subtitle_timeout_text
    }
  end

  def subtitle_timeout_text
    href = OpenProject::Static::Links.url_for(:storage_docs, :health_status)
    I18n.t(
      "storages.open_project_storage_modal.timeout.subtitle",
      storages_health_link: render(Primer::Beta::Link.new(href:, target: "_blank", underline: true)) do
        I18n.t("storages.open_project_storage_modal.timeout.link_text")
      end
    )
  end
end
