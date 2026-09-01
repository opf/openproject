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
require Rails.root.join("modules/documents/db/migrate/20251031071403_cleanup_other_document_type.rb")

RSpec.describe CleanupOtherDocumentType, type: :model do
  before do
    I18n.backend.store_translations(:de, {
                                      seeds: {
                                        common: {
                                          document_categories: {
                                            item_2: { # rubocop:disable Naming/VariableNumber
                                              name: "Andere"
                                            }
                                          }
                                        }
                                      }
                                    })
  end

  after do
    I18n.backend.reload! # Clean up mock translations
  end

  describe "up migration" do
    context "when 'Other' document type has no associated documents" do
      let!(:other_type) { create(:document_type, name: "Other") }
      let!(:kept_type) { create(:document_type, name: "Report") }

      it "deletes the orphaned 'Other' type" do
        expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
          .to change(DocumentType, :count).by(-1)

        expect(DocumentType.find_by(name: "Other")).to be_nil
        expect(DocumentType.find_by(name: "Report")).to be_present
      end
    end

    context "when 'Other' document type has associated documents" do
      let!(:other_type) { create(:document_type, name: "Other") }
      let!(:document) { create(:document, type: other_type) }

      it "does not delete the 'Other' type" do
        expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
          .not_to change(DocumentType, :count)

        expect(DocumentType.find_by(name: "Other")).to be_present
      end
    end

    context "when no 'Other' document type exists" do
      let!(:report_type) { create(:document_type, name: "Report") }

      it "does not affect other types" do
        expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
          .not_to change(DocumentType, :count)

        expect(DocumentType.find_by(name: "Report")).to be_present
      end
    end

    context "with default language set to German", with_settings: { default_language: "de" } do
      context "when localized 'Andere' type has no associated documents" do
        let!(:andere_type) { create(:document_type, name: "Andere") }
        let!(:kept_type) { create(:document_type, name: "Bericht") }

        it "deletes the orphaned 'Andere' type" do
          expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
            .to change(DocumentType, :count).by(-1)

          expect(DocumentType.find_by(name: "Andere")).to be_nil
          expect(DocumentType.find_by(name: "Bericht")).to be_present
        end
      end

      context "when localized 'Andere' type has associated documents" do
        let!(:andere_type) { create(:document_type, name: "Andere") }
        let!(:document) { create(:document, type: andere_type) }

        it "does not delete the 'Andere' type" do
          expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
            .not_to change(DocumentType, :count)

          expect(DocumentType.find_by(name: "Andere")).to be_present
        end
      end

      context "when both English and German 'Other' types exist without documents" do
        let!(:other_type) { create(:document_type, name: "Other") }
        let!(:andere_type) { create(:document_type, name: "Andere") }

        it "deletes both orphaned types" do
          expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
            .to change(DocumentType, :count).by(-2)

          expect(DocumentType.find_by(name: "Other")).to be_nil
          expect(DocumentType.find_by(name: "Andere")).to be_nil
        end
      end
    end

    context "with multiple document types including orphaned 'Other'" do
      let!(:other_type) { create(:document_type, name: "Other") }
      let!(:note_type) { create(:document_type, name: "Note") }
      let!(:report_type) { create(:document_type, name: "Report") }
      let!(:document) { create(:document, type: note_type) }

      it "only deletes orphaned 'Other' type" do
        expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
          .to change(DocumentType, :count).by(-1)

        expect(DocumentType.find_by(name: "Other")).to be_nil
        expect(DocumentType.find_by(name: "Note")).to be_present
        expect(DocumentType.find_by(name: "Report")).to be_present
      end
    end
  end
end
