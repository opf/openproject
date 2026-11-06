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
require Rails.root.join("db/migrate/20261104100000_activate_labels_in_form_configurations")

RSpec.describe ActivateLabelsInFormConfigurations, type: :model do
  let(:form) { create(:form_configuration) }
  let!(:details) { create(:form_configuration_group, :default, form_configuration: form) }
  let!(:extra) { create(:form_configuration_group, form_configuration: form, default_key: "extra", label: nil) }

  def migrate
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
  end

  def place(key, group, position)
    create(:form_configuration_attribute, form_configuration: form, attribute_key: key, group:, position:)
  end

  def labels_of(form)
    FormConfigurationAttribute.find_by(form_configuration: form, attribute_key: "labels")
  end

  before do
    place("priority", details, 1)
    place("date", details, 2)
  end

  it "adds labels to the end of the details group when the form has no labels record", :aggregate_failures do
    migrate

    expect(labels_of(form).group).to eq(details)
    expect(details.members.reload.map(&:key)).to eq(%w[priority date labels])
  end

  it "activates an inactive labels record at the end of the details group", :aggregate_failures do
    inactive = create(:form_configuration_attribute, form_configuration: form, attribute_key: "labels")

    migrate

    expect(labels_of(form)).to eq(inactive)
    expect(details.members.reload.map(&:key)).to eq(%w[priority date labels])
  end

  it "keeps labels where it is when it is already active", :aggregate_failures do
    place("labels", extra, 1)

    migrate

    expect(labels_of(form).group).to eq(extra)
    expect(details.members.reload.map(&:key)).to eq(%w[priority date])
  end

  it "leaves labels inactive on a form without a details group" do
    form_without_details = create(:form_configuration)
    create(:form_configuration_attribute, form_configuration: form_without_details, attribute_key: "labels")

    migrate

    expect(labels_of(form_without_details)).not_to be_active
  end

  it "touches the forms so cached work package schemas are refreshed" do
    form.update_column(:updated_at, 1.day.ago)

    expect { migrate }.to(change { form.reload.updated_at })
  end
end
