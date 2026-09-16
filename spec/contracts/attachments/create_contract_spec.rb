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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Attachments::CreateContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:model) do
    build(:attachment,
          container:,
          content_type:,
          file:,
          filename:,
          author: current_user)
  end
  let(:contract) { described_class.new model, user, options: contract_options }
  let(:contract_options) { {} }

  let(:user) { current_user }
  let(:container) { nil }
  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/image.png"),
      "image/png",
      true
    )
  end
  let(:content_type) { "image/png" }
  let(:filename) { "image.png" }

  let(:can_attach_global) { true }

  before do
    allow(Redmine::Acts::Attachable.attachables)
      .to receive(:none?).and_return(!can_attach_global)
  end

  context "with user who has no permissions" do
    let(:can_attach_global) { false }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with a user that is not the author" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", author: :invalid
  end

  context "with user who has permissions to add" do
    it_behaves_like "contract is valid"
  end

  context "with a container" do
    let(:container) { build_stubbed(:work_package) }

    before do
      allow(container)
        .to receive(:attachments_addable?)
              .with(user)
              .and_return(can_attach)
    end

    context "with user who has no permissions" do
      let(:can_attach) { false }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "with user who has permissions to add" do
      let(:can_attach) { true }

      it_behaves_like "contract is valid"
    end
  end

  context "with an empty allowlist",
          with_settings: { attachment_whitelist: %w[] } do
    it_behaves_like "contract is valid"
  end

  context "with a matching mime allowlist",
          with_settings: { attachment_whitelist: %w[image/png] } do
    it_behaves_like "contract is valid"
  end

  context "with a matching extension allowlist",
          with_settings: { attachment_whitelist: %w[*.png] } do
    it_behaves_like "contract is valid"
  end

  context "with a non-matching allowlist",
          with_settings: { attachment_whitelist: %w[*.jpg image/jpeg] } do
    it_behaves_like "contract is invalid", content_type: :not_allowlisted

    context "when disabling the whitelist check" do
      let(:contract_options) do
        { allowlist: [] }
      end

      it_behaves_like "contract is valid"
    end

    context "when overriding the whitelist" do
      let(:contract_options) do
        { allowlist: %w[*.png] }
      end

      it_behaves_like "contract is valid"
    end
  end

  context "with filesize exceeding maximum",
          with_settings: { attachment_max_size: 0 } do
    it_behaves_like "contract is invalid", file: :file_too_large
  end

  context "with filesize within maximum",
          with_settings: { attachment_max_size: 1024 } do
    it_behaves_like "contract is valid"
  end

  include_examples "contract reuses the model errors"
end
