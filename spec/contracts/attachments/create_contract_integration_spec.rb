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

RSpec.describe Attachments::CreateContract, "integration" do
  include_context "ModelContract shared context"

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

  context "with anonymous user that can view the project" do
    current_user do
      create(:anonymous_role, permissions: %i[view_project])
      User.anonymous
    end

    describe "uncontainered" do
      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    describe "invalid container" do
      let(:container) { build_stubbed(:work_package) }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    describe "valid container" do
      # create a project so that the anonymous permission has something to attach to
      let!(:project) { create(:project, public: true) }

      let(:container) { build_stubbed(:project_export) }

      it_behaves_like "contract is valid"
    end
  end
end
