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

require "spec_helper"

RSpec.describe FormConfigurations::CreateService, type: :service do
  shared_let(:admin) { create(:admin) }

  let(:field) { create(:integer_wp_custom_field) }
  let(:query) { create(:query, user: admin) }
  let(:source) do
    create(:form_configuration, custom_fields: [field]).tap do |form|
      form.attribute_groups = [["People", ["assignee", field.attribute_name]], ["Related", [query]]]
      form.save!
    end
  end

  def create_form(**params) = described_class.new(user: admin).call(name: "New form", **params)

  before { login_as(admin) }

  it "starts a form from scratch on the defaults" do
    form = create_form.result.reload

    expect(form.form_groups).to be_empty
    expect(form.attribute_groups.map(&:key)).to include(:people, :details)
  end

  it "copies the groups and active custom fields of another form", :aggregate_failures do
    form = create_form(copy_from_id: source.id).result.reload

    expect(form.attribute_groups.map(&:key)).to eq(%w[People Related])
    expect(form.custom_field_ids).to contain_exactly(field.id)
  end

  it "gives the copy embedded queries of its own" do
    form = create_form(copy_from_id: source.id).result.reload
    copied = form.attribute_groups.find { it.is_a?(Type::QueryGroup) }.query

    expect(copied.id).not_to eq(query.id)
  end

  it "refuses someone who is not an administrator" do
    result = described_class.new(user: create(:user)).call(name: "New form")

    expect(result).to be_failure
  end
end
