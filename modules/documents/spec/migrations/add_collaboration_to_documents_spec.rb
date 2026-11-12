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
require_module_spec_helper
require Rails.root.join("modules/documents/db/migrate/20250820131839_add_collaboration_to_documents.rb")

RSpec.describe AddCollaborationToDocuments, type: :model do
  describe "up migration" do
    context "with documents of various types" do
      let!(:classic_type) { create(:document_type, name: "Classic") }
      let!(:other_type) { create(:document_type, name: "Other") }
      let!(:report_type) { create(:document_type, name: "Report") }
      let!(:experimental_type) { create(:document_type, name: "Experimental") }

      let!(:doc1) { create(:document, type: classic_type) }
      let!(:doc2) { create(:document, type: other_type) }
      let!(:doc3) { create(:document, type: report_type) }
      let!(:doc4) { create(:document, type: experimental_type) }

      before do
        if Document.column_names.include?("kind")
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.remove_column :documents, :kind
          end
        end
      end

      after do
        # Ensure cache is cleared after migration spec to prevent contaminating subsequent tests
        ActiveRecord::Base.connection.clear_cache!
      end

      it "sets existing documents to 'classic' kind" do
        ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) }

        expect(doc1.reload.kind).to eq("classic")
        expect(doc2.reload.kind).to eq("classic")
        expect(doc3.reload.kind).to eq("classic")
        expect(doc4.reload.kind).to eq("classic")
      end
    end
  end
end
