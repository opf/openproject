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

require "spec_helper"

RSpec.describe "Entity attributes found by the settings search",
               :settings_reset,
               type: :rails_request,
               with_ee: %i[readonly_work_packages work_package_subject_generation] do
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  let(:view_context) { ApplicationController.new.tap { it.request = ActionDispatch::TestRequest.create }.view_context }

  def field_selector(field)
    name, value = field.split("=", 2)
    value ? "[name='#{name}'][value='#{value}']" : "[name='#{name}']"
  end

  def expect_fields_rendered(kind, entity)
    attributes = kind.attributes.select { it.field && it.applies_to?(entity) }
    expect(attributes).not_to be_empty

    attributes.group_by { it.url(entity, view_context, kind.url).split("?").first }.each do |url, url_attributes|
      get url
      expect(response).to have_http_status(:ok), "for #{url}"

      url_attributes.each do |attribute|
        expect(response.parsed_body.css(field_selector(attribute.field))).to be_present,
                                                                             "#{attribute.field} on #{url}"
      end
    end
  end

  {
    types: -> { [create(:type)] },
    statuses: -> { [create(:status)] },
    priorities: -> { [create(:issue_priority)] },
    roles: -> { [create(:project_role), create(:global_role)] },
    work_package_custom_fields: -> { %w[string int text bool list].map { create(:work_package_custom_field, field_format: it) } },
    version_custom_fields: -> { [create(:version_custom_field, field_format: "string")] },
    user_custom_fields: -> { [create(:user_custom_field, field_format: "string")] },
    group_custom_fields: -> { [create(:group_custom_field, field_format: "string")] },
    project_custom_fields: -> { [create(:project_custom_field, field_format: "string")] },
    time_entry_custom_fields: -> { [create(:time_entry_custom_field, field_format: "string")] }
  }.each do |key, entities|
    it "links the attributes of #{key} to their fields", :aggregate_failures do
      kind = Settings::EntityKinds.fetch(key)

      instance_exec(&entities).each { expect_fields_rendered(kind, it) }
    end
  end
end
