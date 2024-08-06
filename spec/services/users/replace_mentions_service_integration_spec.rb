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

RSpec.describe Users::ReplaceMentionsService, "integration" do
  subject(:service_call) { instance.call(from: principal, to: to_user) }

  shared_let(:other_user) { create(:user, firstname: "Frank", lastname: "Herbert") }
  shared_let(:user) { create(:user, firstname: "Isaac", lastname: "Asimov") }
  shared_let(:group) { create(:group, lastname: "Sci-Fi") }
  shared_let(:to_user) { create(:user, firstname: "Philip K.", lastname: "Dick") }

  let(:principal) { user }

  shared_examples_for "successful service call" do
    it "is successful" do
      expect(service_call)
        .to be_success
    end
  end

  shared_examples_for "text replacement" do |attribute|
    before do
      service_call
      model.reload
    end

    it "replaces #{attribute}" do
      expect(model.send(attribute))
        .to be_html_eql expected_text
    end
  end

  shared_examples_for "rewritten mention" do |factory, attribute|
    let(:additional_properties) { {} }
    let!(:model) do
      create(factory, attribute => text, **additional_properties)
    end

    context "with the replaced user in mention tags" do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            <mention class="mention"
                     data-id="#{user.id}"
                     data-type="user"
                     data-text="@#{user.name}">
                     @#{user.name}
            </mention>
          TEXT
        end
        let(:expected_text) do
          <<~TEXT.squish
            <mention class="mention"
                     data-id="#{to_user.id}"
                     data-type="user"
                     data-text="@#{to_user.name}">@#{to_user.name}</mention>
          TEXT
        end
      end
    end

    context "with a different user in mention tags" do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            <mention class="mention"
                     data-id="#{other_user.id}"
                     data-type="user"
                     data-text="@#{other_user.name}">
                     @#{other_user.name}
            </mention>
          TEXT
        end
        let(:expected_text) do
          <<~TEXT.squish
            <mention class="mention"
                     data-id="#{other_user.id}"
                     data-type="user"
                     data-text="@#{other_user.name}">@#{other_user.name}</mention>
          TEXT
        end
      end
    end

    context "with the replaced user in a user#ID notation" do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            Lorem ipsum

            user##{user.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
        let(:expected_text) do
          <<~TEXT
            Lorem ipsum

            user##{to_user.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
      end
    end

    context "with a different user in a user#ID notation" do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            Lorem ipsum

            user##{other_user.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
        let(:expected_text) do
          <<~TEXT
            Lorem ipsum

            user##{other_user.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
      end
    end

    context 'with the replaced user in a user#"LOGIN" notation' do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            Lorem ipsum

            user#"#{user.login}" Lorem ipsum

            Lorem ipsum
          TEXT
        end
        let(:expected_text) do
          <<~TEXT
            Lorem ipsum

            user##{to_user.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
      end
    end

    context 'with a different user in a user#"LOGIN" notation' do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            Lorem ipsum

            user#"#{other_user.login}" Lorem ipsum

            Lorem ipsum
          TEXT
        end
        let(:expected_text) do
          <<~TEXT
            Lorem ipsum

            user#"#{other_user.login}" Lorem ipsum

            Lorem ipsum
          TEXT
        end
      end
    end

    context 'with the replaced user in a user#"MAIL" notation' do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            Lorem ipsum

            user#"#{user.mail}" Lorem ipsum

            Lorem ipsum
          TEXT
        end
        let(:expected_text) do
          <<~TEXT
            Lorem ipsum

            user##{to_user.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
      end
    end

    context 'with a different user in a user#"MAIL" notation' do
      let(:principal) { user }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            Lorem ipsum

            user#"#{other_user.mail}" Lorem ipsum

            Lorem ipsum
          TEXT
        end
        let(:expected_text) do
          <<~TEXT
            Lorem ipsum

            user#"#{other_user.mail}" Lorem ipsum

            Lorem ipsum
          TEXT
        end
      end
    end

    context "with the replaced group in mention tags" do
      let(:principal) { group }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            <mention class="mention"
                     data-id="#{group.id}"
                     data-type="group"
                     data-text="@#{group.name}">
                     @#{group.name}
            </mention>
          TEXT
        end
        let(:expected_text) do
          <<~TEXT.squish
            <mention class="mention"
                     data-id="#{to_user.id}"
                     data-type="user"
                     data-text="@#{to_user.name}">@#{to_user.name}</mention>
          TEXT
        end
      end
    end

    context "with the replaced group in a group#ID notation" do
      let(:principal) { group }

      it_behaves_like "text replacement", attribute do
        let(:text) do
          <<~TEXT
            Lorem ipsum

            group##{group.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
        let(:expected_text) do
          <<~TEXT
            Lorem ipsum

            user##{to_user.id} Lorem ipsum

            Lorem ipsum
          TEXT
        end
      end
    end
  end

  context "when specifying a subset of classes to perform replacements on" do
    let(:instance) do
      described_class.new(Project)
    end

    it_behaves_like "successful service call"
    it_behaves_like "rewritten mention", :project, :description
    it_behaves_like "rewritten mention", :project, :status_explanation

    it "does not re-write a mention on a non specified class" do
      text = <<~TEXT
        <mention class="mention"
                 data-id="#{user.id}"
                 data-type="user"
                 data-text="@#{user.name}">
                 @#{user.name}
        </mention>
      TEXT
      model = create(:work_package, description: text)

      service_call

      model.reload
      expect(model.description).to eq(text)
    end
  end

  context "without a subset of classes to perform replacements on" do
    let(:instance) do
      described_class.new
    end

    it_behaves_like "successful service call"

    context "for work package description" do
      it_behaves_like "rewritten mention", :work_package, :description
    end

    context "for work package description with dangerous mails" do
      let(:dangerous_user) do
        build(:user,
              firstname: "Dangerous",
              lastname: "User",
              mail: "'); DELETE FROM work_packages; SELECT ('").tap do |user|
          user.save(validate: false)
        end
      end
      let(:principal) { dangerous_user }

      it "escapes the malicious input" do
        expect { service_call }
          .not_to raise_error
      end
    end

    context "for work package journal description" do
      it_behaves_like "rewritten mention", :journal_work_package_journal, :description
    end

    context "for journal notes" do
      it_behaves_like "rewritten mention", :journal, :notes do
        let(:additional_properties) { { data_id: 5, data_type: "Foobar" } }
      end
    end

    context "for comment comments" do
      it_behaves_like "rewritten mention", :comment, :comments
    end

    context "for custom_value value" do
      it_behaves_like "rewritten mention", :principal_custom_value, :value do
        let(:additional_properties) { { custom_field: create(:text_wp_custom_field) } }
      end
    end

    context "for customizable_journal value" do
      it_behaves_like "rewritten mention", :journal_customizable_journal, :value do
        let(:additional_properties) do
          {
            journal: create(:journal, data_id: 5, data_type: "Foobar"),
            custom_field: create(:text_wp_custom_field)
          }
        end
      end
    end

    context "for documents description" do
      it_behaves_like "rewritten mention", :document, :description
    end

    context "for meeting_contents text" do
      it_behaves_like "rewritten mention", :meeting_agenda, :text
    end

    context "for meeting_content_journals text" do
      it_behaves_like "rewritten mention", :journal_meeting_content_journal, :text
    end

    context "for messages content" do
      it_behaves_like "rewritten mention", :message, :content
    end

    context "for message_journals content" do
      it_behaves_like "rewritten mention", :journal_message_journal, :content do
        let(:additional_properties) { { forum_id: 1 } }
      end
    end

    context "for news description" do
      it_behaves_like "rewritten mention", :news, :description
    end

    context "for news_journals description" do
      shared_let(:author) { create(:user) }

      it_behaves_like "rewritten mention", :journal_news_journal, :description do
        let(:additional_properties) { { author_id: author.id } }
      end
    end

    context "for project description" do
      it_behaves_like "rewritten mention", :project, :description
    end

    context "for project_status explanation" do
      it_behaves_like "rewritten mention", :project, :status_explanation
    end

    context "for wiki_page text" do
      it_behaves_like "rewritten mention", :wiki_page, :text
    end

    context "for wiki_content_journals text" do
      it_behaves_like "rewritten mention", :journal_wiki_page_journal, :text
    end

    context "for a group for to" do
      subject(:service_call) { instance.call(from: user, to: create(:group)) }

      it "raises an error" do
        expect { service_call }
          .to raise_error ArgumentError
      end
    end

    context "for a placeholder user for from" do
      subject(:service_call) { instance.call(from: create(:placeholder_user), to: to_user) }

      it "raises an error" do
        expect { service_call }
          .to raise_error ArgumentError
      end
    end

    context "for a placeholder user for to" do
      subject(:service_call) { instance.call(from: user, to: create(:placeholder_user)) }

      it "raises an error" do
        expect { service_call }
          .to raise_error ArgumentError
      end
    end
  end
end
