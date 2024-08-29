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

require "contracts/shared/model_contract_shared_context"

RSpec.describe Storages::LastProjectFolders::BaseContract do
  include_context "ModelContract shared context"

  let(:last_project_folder) { build(:last_project_folder) }
  let(:contract) { described_class.new(last_project_folder, build_stubbed(:admin)) }

  context "if no project storage is given" do
    before do
      last_project_folder.project_storage = nil
    end

    it_behaves_like "contract is invalid"
  end

  context "if the project folder mode is `inactive`" do
    before do
      last_project_folder.mode = "inactive"
    end

    it_behaves_like "contract is invalid"
  end

  context "if the project folder mode is `manual`" do
    before do
      last_project_folder.mode = "manual"
    end

    it_behaves_like "contract is valid"
  end

  context "if the project folder mode is `automatic`" do
    before do
      last_project_folder.mode = "automatic"
    end

    it_behaves_like "contract is valid"
  end

  include_examples "contract reuses the model errors"
end
