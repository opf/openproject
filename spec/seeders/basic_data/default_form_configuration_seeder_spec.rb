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

RSpec.describe BasicData::DefaultFormConfigurationSeeder do
  include_context "with basic seed data"

  subject(:seeder) { described_class.new(basic_seed_data) }

  it "seeds a default form with the default groups of the code" do
    seeder.seed!

    form = FormConfiguration.default_form
    expect(form.name).to eq(I18n.t("form_configurations.default.name"))
    expect(form.form_groups.map { it.default_key.to_sym }).to eq(form.default_attribute_groups.map(&:first))
  end

  it "takes the next free name when a form already has the default name" do
    create(:form_configuration, name: I18n.t("form_configurations.default.name"))

    seeder.seed!

    expect(FormConfiguration.default_form.name).to eq("#{I18n.t('form_configurations.default.name')} (2)")
  end

  it "seeds nothing when a default form exists" do
    default = create(:form_configuration, is_default: true)

    expect { seeder.seed! }.not_to change(FormConfiguration, :count)
    expect(FormConfiguration.default_form).to eq(default)
  end
end
