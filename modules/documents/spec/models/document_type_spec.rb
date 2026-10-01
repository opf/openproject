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
require_module_spec_helper

RSpec.describe DocumentType do
  describe "Associations" do
    it do
      expect(subject).to have_many(:documents)
        .dependent(:nullify)
        .with_foreign_key(:type_id)
    end

    context "for documents" do
      let(:document_type) { create(:document_type) }

      it "maintains documents counter cache" do
        expect { create(:document, type: document_type) }
          .to change { document_type.reload.documents_count }.by(1)
      end
    end
  end

  describe "Normalizations" do
    it { is_expected.to normalize(:name).from("  reImburseMEnt RequeSt  ").to("reImburseMEnt RequeSt") }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe "Database constraints" do
    it { is_expected.to have_db_index(:name).unique(true) }
  end

  describe ".default" do
    it "returns the default document type when one is marked as default" do
      default_type = create(:document_type, is_default: true)
      create(:document_type, is_default: false)

      expect(described_class.default).to eq default_type
    end

    it "returns the first document type when none is marked as default" do
      first_type = create(:document_type, is_default: false)
      create(:document_type, is_default: false)

      expect(described_class.default).to eq first_type
    end
  end

  describe "#destroy(reassign_to)" do
    let!(:document_type) { create(:document_type) }
    let!(:other_type) { create(:document_type) }
    let!(:document) { create(:document, type: document_type) }

    it "reassigns documents to the given document type before destroying" do
      expect do
        document_type.destroy(other_type)
      end.to change { document.reload.type }.from(document_type).to(other_type)
        .and(change { other_type.reload.documents_count }.by(1))
        .and(change(described_class, :count).by(-1))
    end
  end

  describe "#prevent_deletion_of_last_type" do
    let!(:only_type) { create(:document_type) }

    it "prevents destroying the last remaining document type" do
      expect(only_type.destroy).to be_falsey
      expect(only_type.errors[:base]).to include("Cannot delete the last document type")
      expect(described_class.count).to eq 1
    end
  end
end
