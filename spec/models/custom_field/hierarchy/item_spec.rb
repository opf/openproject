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

RSpec.describe CustomField::Hierarchy::Item, :model do
  let(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: nil) }
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }

  let(:root) { service.generate_root(custom_field).value! }

  context "when custom field is deleted" do
    let!(:luke) { service.insert_item(parent: root, label: "luke").value! }
    let!(:mara) { service.insert_item(parent: luke, label: "mara").value! }
    let!(:leia) { service.insert_item(parent: root, label: "leia").value! }
    let!(:kylo) { service.insert_item(parent: leia, label: "kylo").value! }

    before { custom_field.reload }

    it "removes the entire hierarchy tree" do
      expect { custom_field.destroy }.to change(described_class, :count).to(0)
    end
  end
end
