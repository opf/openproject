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

RSpec.describe TypeVariant, "switching forms" do
  let(:field) { create(:integer_wp_custom_field) }
  let(:variant) { create(:type).default_variant }
  let(:target) { create(:form_configuration, attribute_groups: [["Only", ["assignee", field.attribute_name]]]) }

  before do
    variant.attribute_groups = [["Details", ["assignee", "priority", field.attribute_name]]]
    variant.save!
    variant.update!(form_configuration_excluded_elements: %w[assignee priority],
                    required_attributes: [field.attribute_name])
  end

  def switch
    variant.form_configuration = target
    variant.save!
    variant.reload
  end

  it "keeps the exclusions the new form has an element for" do
    switch

    expect(variant.form_configuration_excluded_elements).to eq(%w[assignee])
  end

  it "keeps the required attributes the new form shows" do
    switch

    expect(variant.required_attributes).to eq([field.attribute_name])
  end

  it "does not carry the groups it built for its former form into the new one" do
    variant.attribute_groups

    switch

    expect(target.reload.attribute_groups.map { [it.key, it.attributes] }).to eq([["Only", ["assignee", field.attribute_name]]])
  end
end
