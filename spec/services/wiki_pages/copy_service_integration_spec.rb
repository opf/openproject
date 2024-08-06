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

RSpec.describe WikiPages::CopyService, "integration", type: :model do
  let(:user) do
    create(:user) do |user|
      create(:member,
             project: source_project,
             principal: user,
             roles: [role])

      create(:member,
             project: sink_project,
             principal: user,
             roles: [role])
    end
  end

  let(:role) do
    create(:project_role,
           permissions:)
  end

  let(:permissions) do
    %i(view_wiki edit_wiki_pages)
  end
  let(:source_wiki) { create(:wiki) }
  let(:source_project) { source_wiki.project }

  let(:sink_wiki) { create(:wiki) }
  let(:sink_project) { sink_wiki.project }

  let(:wiki_page) { create(:wiki_page) }

  let(:instance) { described_class.new(model: wiki_page, user:) }

  let(:attributes) { {} }

  let(:copy) do
    service_result
      .result
  end
  let(:service_result) do
    instance
      .call(**attributes)
  end

  before do
    login_as(user)
  end

  describe "#call" do
    shared_examples_for "copied wiki page" do
      it "is a success" do
        expect(service_result)
          .to be_success
      end

      it "is a new, persisted wiki page" do
        expect(copy).to be_persisted
        expect(copy.id).not_to eq(wiki_page.id)
      end

      it "copies the text" do
        expect(copy.text).to eq(wiki_page.text)
      end

      it "sets the author to be the current user" do
        expect(copy.author).to eq(user)
      end

      context "with attachments" do
        let!(:attachment) do
          create(:attachment,
                 container: wiki_page)
        end

        context "when specifying to copy attachments (default)" do
          it "copies the attachment" do
            expect(copy.attachments.length)
              .to eq 1

            expect(copy.attachments.first.attributes.slice(:digest, :file, :filesize))
              .to eq attachment.attributes.slice(:digest, :file, :filesize)

            expect(copy.attachments.first.id)
              .not_to eq attachment.id
          end
        end

        context "when referencing the attachment in the wiki text" do
          let(:text) do
            <<~MARKDOWN
              # Some text here

              ![attachment#{attachment.id}](/api/v3/attachments/#{attachment.id}/content)
            MARKDOWN
          end

          before do
            wiki_page.update!(text:)
          end

          it "updates the attachment reference" do
            expect(wiki_page.text).to include "/api/v3/attachments/#{attachment.id}/content"

            expect(copy.attachments.length).to eq 1
            expect(copy.attachments.first.id).not_to eq attachment.id

            expect(copy.reload.text).not_to include "/api/v3/attachments/#{attachment.id}/content"
            expect(copy.text).to include "/api/v3/attachments/#{copy.attachments.first.id}/content"
          end
        end

        context "when specifying to not copy attachments" do
          let(:attributes) { { copy_attachments: false } }

          it "copies the attachment" do
            expect(copy.attachments.length)
              .to eq 0
          end
        end
      end
    end

    describe "to a different wiki" do
      let(:attributes) { { wiki: sink_wiki } }

      it_behaves_like "copied wiki page"
    end
  end
end
