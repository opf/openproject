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

RSpec.describe OpenProject::JournalFormatter::TypeNamedAssociation do
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:design) { create(:type, name: "Design", parent: epic) }
  shared_let(:research) { create(:type, name: "Research", parent: epic) }
  shared_let(:bug) { create(:type, name: "Bug") }

  let(:work_package) { build_stubbed(:work_package) }
  let(:journal) { build_stubbed(:work_package_journal, journable: work_package) }

  subject(:formatter) { described_class.new(journal) }

  describe "#render" do
    it "renders a change between two families" do
      expect(formatter.render(:type_id, [bug.id.to_s, epic.id.to_s]))
        .to eq(I18n.t(:text_journal_changed_plain,
                      label: "<strong>Type</strong>",
                      linebreak: nil,
                      old: "<i>Bug</i>",
                      new: "<i>Epic</i>"))
    end

    # Every member of a family answers the root's name, so these would all read
    # "Type changed from Epic to Epic".
    it "renders nothing when switching between two variants of one family" do
      expect(formatter.render(:type_id, [design.id.to_s, research.id.to_s])).to be_nil
    end

    it "renders nothing when switching from a variant to the parent it presents as" do
      expect(formatter.render(:type_id, [design.id.to_s, epic.id.to_s])).to be_nil
    end

    it "renders nothing when switching from the parent to one of its variants" do
      expect(formatter.render(:type_id, [epic.id.to_s, design.id.to_s])).to be_nil
    end

    it "renders the initial type of a work package" do
      expect(formatter.render(:type_id, [nil, epic.id.to_s]))
        .to eq(I18n.t(:text_journal_set_to, label: "<strong>Type</strong>", value: "<i>Epic</i>"))
    end

    # A deleted type leaves an id that resolves to nothing, so there is no
    # family to compare against.
    it "renders a change away from a type that no longer exists" do
      expect(formatter.render(:type_id, ["#{epic.id}0000", bug.id.to_s]))
        .to eq(I18n.t(:text_journal_set_to, label: "<strong>Type</strong>", value: "<i>Bug</i>"))
    end
  end
end
