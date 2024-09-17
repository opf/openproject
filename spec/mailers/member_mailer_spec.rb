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

RSpec.describe MemberMailer do
  include OpenProject::ObjectLinking
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers

  let(:current_user) { build_stubbed(:user) }
  let(:member) do
    build_stubbed(:member,
                  principal:,
                  project:,
                  roles:)
  end
  let(:principal) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:roles) { [build_stubbed(:project_role), build_stubbed(:project_role)] }
  let(:message) { nil }

  around do |example|
    Timecop.freeze(Time.current) do
      example.run
    end
  end

  shared_examples_for "has a subject" do |key|
    it "has a subject" do
      if project
        expect(subject.subject)
          .to eql I18n.t(key, project: project.name)
      else
        expect(subject.subject)
          .to eql I18n.t(key)
      end
    end
  end

  shared_examples_for "fails for a group" do
    let(:principal) { build_stubbed(:group) }

    it "raises an argument error" do
      # Calling .to in order to have the mail rendered
      expect { subject.to }
        .to raise_error ArgumentError
    end
  end

  shared_examples_for "sends a mail to the member's principal" do
    let(:principal) { build_stubbed(:group) }

    it "raises an argument error" do
      # Calling .to in order to have the mail rendered
      expect { subject.to }
        .to raise_error ArgumentError
    end
  end

  shared_examples_for "sets the expected message_id header" do
    it "sets the expected message_id header" do
      expect(subject["Message-ID"].value)
        .to eql "<op.member-#{member.id}.#{Time.current.strftime('%Y%m%d%H%M%S')}.#{current_user.id}@example.net>"
    end
  end

  shared_examples_for "sets the expected openproject header" do
    it "sets the expected openproject header" do
      expect(subject["X-OpenProject-Project"].value)
        .to eql project.identifier
    end
  end

  shared_examples_for "has the expected body" do
    let(:body) { subject.body.parts.detect { |part| part["Content-Type"].value == "text/html" }.body.to_s }
    let(:i18n_params) do
      {
        project: project ? link_to_project(project, only_path: false) : nil,
        user: link_to_user(current_user, only_path: false)
      }.compact
    end

    it "highlights the roles received" do
      expected = <<~MSG
        <ul>
          <li> #{roles.first.name} </li>
          <li> #{roles.last.name} </li>
        </ul>
      MSG

      expect(body)
        .to be_html_eql(expected)
        .at_path("body/table/tr/td/ul")
    end

    context "when current user and principal have different locales" do
      let(:principal) { build_stubbed(:user, language: "fr") }
      let(:current_user) { build_stubbed(:user, language: "de") }

      it "is in the locale of the recipient" do
        OpenProject::LocaleHelper.with_locale_for(principal) do
          i18n_params
        end
        expect(body).to include(I18n.t(:"#{expected_header}.without_message", locale: :fr, **i18n_params))
      end
    end

    context "with a custom message" do
      let(:message) { "Some **styled** message" }

      it "has the expected header" do
        expect(body)
          .to include(I18n.t(:"#{expected_header}.with_message", **i18n_params))
      end

      it "includes the custom message" do
        expect(body)
          .to include("Some <strong>styled</strong> message")
      end
    end

    context "without a custom message" do
      it "has the expected header" do
        expect(body)
          .to include(I18n.t(:"#{expected_header}.without_message", **i18n_params))
      end
    end
  end

  describe "#added_project" do
    subject { described_class.added_project(current_user, member, message) }

    it_behaves_like "sends a mail to the member's principal"
    it_behaves_like "has a subject", :"mail_member_added_project.subject"
    it_behaves_like "sets the expected message_id header"
    it_behaves_like "sets the expected openproject header"
    it_behaves_like "has the expected body" do
      let(:expected_header) do
        "mail_member_added_project.body.added_by"
      end
    end
    it_behaves_like "fails for a group"
  end

  describe "#updated_project" do
    subject { described_class.updated_project(current_user, member, message) }

    it_behaves_like "sends a mail to the member's principal"
    it_behaves_like "has a subject", :"mail_member_updated_project.subject"
    it_behaves_like "sets the expected message_id header"
    it_behaves_like "sets the expected openproject header"
    it_behaves_like "has the expected body" do
      let(:expected_header) do
        "mail_member_updated_project.body.updated_by"
      end
    end
    it_behaves_like "fails for a group"
  end

  describe "#updated_global" do
    let(:project) { nil }

    subject { described_class.updated_global(current_user, member, message) }

    it_behaves_like "sends a mail to the member's principal"
    it_behaves_like "has a subject", :"mail_member_updated_global.subject"
    it_behaves_like "sets the expected message_id header"
    it_behaves_like "has the expected body" do
      let(:expected_header) do
        "mail_member_updated_global.body.updated_by"
      end
    end
    it_behaves_like "fails for a group"
  end
end
