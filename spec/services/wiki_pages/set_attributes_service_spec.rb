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

RSpec.describe WikiPages::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = double("contract_class")

    allow(contract)
      .to receive(:new)
      .with(wiki_page, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double("contract_instance", validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double("contract_errors")
  end
  let(:wiki_page_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: wiki_page,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:wiki_page) do
    build_stubbed(:wiki_page)
  end

  describe "call" do
    let(:call_attributes) do
      {
        text: "some new text",
        title: "a new title",
        slug: "a new slug",
        journal_notes: "the journal notes"
      }
    end

    before do
      allow(wiki_page)
        .to receive(:valid?)
        .and_return(wiki_page_valid)

      expect(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    it "is successful" do
      expect(subject).to be_success
    end

    context "for an existing wiki page" do
      it "sets the attributes" do
        subject

        expect(wiki_page.attributes.slice(*wiki_page.changed).symbolize_keys)
          .to eql call_attributes.slice(:title, :slug, :text)

        expect(wiki_page.journal_notes)
          .to eql call_attributes[:journal_notes]
      end

      it "does not persist the wiki_page" do
        expect(wiki_page)
          .not_to receive(:save)

        subject
      end
    end

    context "for a new wiki page" do
      let(:wiki_page) do
        WikiPage.new
      end

      it "sets the attributes with the user being the author" do
        subject

        expect(wiki_page.attributes.slice(*wiki_page.changed).symbolize_keys)
          .to eql call_attributes.slice(:title, :slug, :text).merge(author_id: user.id)

        expect(wiki_page.journal_notes)
          .to eql call_attributes[:journal_notes]
      end

      it "marks the author to be system changed" do
        subject

        expect(wiki_page.changed_by_system["author_id"])
          .to eql [nil, user.id]
      end
    end
  end
end
