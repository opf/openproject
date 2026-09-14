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

RSpec.describe WorkPackages::SetAttributesService do
  shared_let(:user) { create(:user) }
  shared_let(:other_user) { create(:user) }

  subject(:service_result) do
    described_class
      .new(user:, model: work_package, contract_class: EmptyContract)
      .call(params)
  end

  context "when the work package is new" do
    let(:work_package) { WorkPackage.new }

    context "and the description references an own uncontainered attachment" do
      shared_let(:attachment) { create(:attachment, author: user, container: nil) }

      let(:params) do
        { description: %(<img class="op-uc-image" src="/api/v3/attachments/#{attachment.id}/content">) }
      end

      it "claims the attachment" do
        expect(service_result.result.attachments_replacements).to contain_exactly(attachment)
      end
    end

    context "and attachment_ids is explicitly empty alongside a description reference" do
      shared_let(:attachment) { create(:attachment, author: user, container: nil) }

      let(:params) do
        {
          attachment_ids: [],
          description: "![](/api/v3/attachments/#{attachment.id}/content)"
        }
      end

      it "claims the attachment referenced in the description" do
        expect(service_result.result.attachments_replacements).to contain_exactly(attachment)
      end
    end

    context "and attachment_ids already names another attachment alongside a description reference" do
      shared_let(:explicit_attachment) { create(:attachment, author: user, container: nil) }
      shared_let(:described_attachment) { create(:attachment, author: user, container: nil) }

      let(:params) do
        {
          attachment_ids: [explicit_attachment.id],
          description: "![](/api/v3/attachments/#{described_attachment.id}/content)"
        }
      end

      it "unions the explicit and description-referenced attachments" do
        expect(service_result.result.attachments_replacements)
          .to contain_exactly(explicit_attachment, described_attachment)
      end
    end

    context "and the params carry no description key" do
      let(:params) { { subject: "no description here" } }

      it "leaves attachments_replacements untouched" do
        expect(service_result.result.attachments_replacements).to be_nil
      end
    end

    context "and the description references nothing" do
      let(:params) { { description: "Lorem ipsum dolor sit amet" } }

      it "leaves attachments_replacements untouched" do
        expect(service_result.result.attachments_replacements).to be_nil
      end
    end

    context "and the description references another user's uncontainered attachment" do
      shared_let(:other_users_attachment) { create(:attachment, author: other_user, container: nil) }

      let(:params) do
        { description: "![](/api/v3/attachments/#{other_users_attachment.id}/content)" }
      end

      it "does not claim it" do
        expect(service_result.result.attachments_replacements).to be_nil
      end
    end
  end

  context "when the work package is persisted" do
    shared_let(:work_package) { create(:work_package, author: user) }
    shared_let(:attachment) { create(:attachment, author: user, container: nil) }

    let(:params) do
      { description: "![](/api/v3/attachments/#{attachment.id}/content)" }
    end

    it "does not claim attachments referenced in the description" do
      expect(service_result.result.attachments_replacements).to be_nil
    end
  end
end
