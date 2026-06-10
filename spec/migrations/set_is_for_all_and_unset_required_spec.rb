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

require "spec_helper"
require Rails.root.join("db/migrate/20251211160744_set_is_for_all_and_unset_required")

RSpec.describe SetIsForAllAndUnsetRequired, type: :model, with_ee: %i[calculated_values] do
  # Project custom fields to be migrated
  shared_let(:required_project_cf) { create(:project_custom_field, :integer, is_required: true, is_for_all: false) }
  shared_let(:optional_project_cf) { create(:project_custom_field, :integer, is_required: false, is_for_all: false) }
  shared_let(:required_boolean_project_cf) { create(:project_custom_field, :boolean, is_required: true, is_for_all: false) }

  # Regular custom fields, to be ignored by the migration
  shared_let(:required_cf) { create(:custom_field, :integer, is_required: true, is_for_all: false) }
  shared_let(:optional_cf) { create(:custom_field, :integer, is_required: false, is_for_all: false) }

  shared_let(:required_boolean_wp_cf) { create(:wp_custom_field, :boolean, is_required: true, is_for_all: false) }
  shared_let(:required_int_wp_cf) { create(:wp_custom_field, :integer, is_required: true, is_for_all: false) }
  shared_let(:required_boolean_te_cf) { create(:time_entry_custom_field, :boolean, is_required: true, is_for_all: false) }
  shared_let(:required_int_te_cf) { create(:time_entry_custom_field, :integer, is_required: true, is_for_all: false) }
  shared_let(:required_boolean_user_cf) { create(:user_custom_field, :boolean, is_required: true, is_for_all: false) }
  shared_let(:required_int_user_cf) { create(:user_custom_field, :integer, is_required: true, is_for_all: false) }
  shared_let(:required_boolean_group_cf) { create(:group_custom_field, :boolean, is_required: true, is_for_all: false) }
  shared_let(:required_int_group_cf) { create(:group_custom_field, :integer, is_required: true, is_for_all: false) }

  # Cannot be done as a shared_let as with_ee and with_flag haven't taken hold when shared_let is run
  let!(:required_calculated_project_cf) { create(:project_custom_field, :calculated_value, is_required: true) }

  it "updates required project custom fields as well as boolean and calculated values" do # rubocop:disable RSpec/MultipleExpectations
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(required_project_cf.reload.is_for_all).to be_truthy
    expect(optional_project_cf.reload.is_for_all).to be_falsey
    expect(required_boolean_project_cf.reload.is_for_all).to be_truthy
    expect(required_calculated_project_cf.reload.is_for_all).to be_truthy

    # ignores non project required custom fields

    expect(required_cf.reload.is_for_all).to be_falsey
    expect(optional_cf.reload.is_for_all).to be_falsey

    # Keeps the existing required values except for boolean and calculated values
    # which are set to false
    expect(required_project_cf.is_required).to be_truthy
    expect(optional_project_cf.is_required).to be_falsey
    expect(required_boolean_project_cf.is_required).to be_falsey
    expect(required_calculated_project_cf.is_required).to be_falsey

    # This happens for all boolean fields
    expect(required_boolean_wp_cf.reload.is_required).to be_falsey
    expect(required_int_wp_cf.reload.is_required).to be_truthy
    expect(required_boolean_te_cf.reload.is_required).to be_falsey
    expect(required_int_te_cf.reload.is_required).to be_truthy
    expect(required_boolean_user_cf.reload.is_required).to be_falsey
    expect(required_int_user_cf.reload.is_required).to be_truthy
    expect(required_boolean_group_cf.reload.is_required).to be_falsey
    expect(required_int_group_cf.reload.is_required).to be_truthy
  end
end
