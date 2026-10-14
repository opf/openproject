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

RSpec.describe Settings::EntityKinds do
  let(:view_context) { ApplicationController.new.tap { it.request = ActionDispatch::TestRequest.create }.view_context }

  describe Settings::EntityKinds::Kind do
    subject(:kind) do
      described_class.new(:statuses, menu_item: :statuses, scope: -> { Status.order(:position) },
                                     url: ->(status) { edit_status_path(status) })
    end

    shared_let(:open_status) { create(:status, name: "Open") }
    shared_let(:in_progress) { create(:status, name: "In progress") }

    it "finds entities whose name contains any of the words" do
      expect(kind.matching(%w[progr xyz])).to contain_exactly(in_progress)
    end

    it "finds nothing without words" do
      expect(kind.matching([])).to be_empty
    end

    it "combines static and lazily built attributes" do
      kind.attribute(:name, label: "Name")
      kind.attributes_from { [Settings::EntityKinds::Attribute.new(:color, label: "Color")] }

      expect(kind.attributes.map(&:key)).to eq %i[name color]
    end
  end

  describe Settings::EntityKinds::Attribute do
    let(:status) { build_stubbed(:status) }
    let(:default_url) { ->(status) { edit_status_path(status) } }

    it "links to the entity's page highlighting its field" do
      attribute = described_class.new(:color, label: "Color", field: "status[color_id]")

      expect(attribute.url(status, view_context, default_url))
        .to eq "#{Rails.application.routes.url_helpers.edit_status_path(status)}?highlight=status%5Bcolor_id%5D"
    end

    it "links to its own page without a field" do
      attribute = described_class.new(:list, label: "List", url: ->(_) { statuses_path })

      expect(attribute.url(status, view_context, default_url)).to eq "/statuses"
    end

    it "applies to the entities passing its condition", :aggregate_failures do
      attribute = described_class.new(:closed, label: "Closed", if: ->(status) { status.is_closed })

      expect(attribute.applies_to?(build_stubbed(:status, is_closed: true))).to be true
      expect(attribute.applies_to?(build_stubbed(:status, is_closed: false))).to be false
    end
  end
end
