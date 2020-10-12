#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

shared_examples_for 'ifc model contract' do
  let(:current_user) do
    FactoryBot.build_stubbed(:user) do |user|
      allow(user)
        .to receive(:allowed_to?) do |permission, permission_project|
        permissions.include?(permission) && model_project == permission_project
      end
    end
  end
  let(:other_user) do
    FactoryBot.build_stubbed(:user) do |user|
      allow(user)
        .to receive(:allowed_to?) do |permission, permission_project|
        permissions.include?(permission) && model_project == permission_project
      end
    end
  end
  let(:model_project) { FactoryBot.build_stubbed(:project) }
  let(:ifc_attachment) { FactoryBot.build_stubbed(:attachment, author: model_user) }
  let(:model_user) { current_user }
  let(:model_title) { 'some title' }

  before do
    allow(ifc_model)
      .to receive(:ifc_attachment)
      .and_return(ifc_attachment)
  end

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples 'is valid' do
    it 'is valid' do
      expect_valid(true)
    end
  end

  it_behaves_like 'is valid'

  context 'if the title is nil' do
    let(:model_title) { nil }

    it 'is invalid' do
      expect_valid(false, title: %i(blank))
    end
  end

  context 'if the title is blank' do
    let(:model_title) { '' }

    it 'is invalid' do
      expect_valid(false, title: %i(blank))
    end
  end

  context 'if the project is nil' do
    let(:model_project) { nil }

    it 'is invalid' do
      expect_valid(false, project: %i(blank))
    end
  end

  context 'if there is no ifc attachment' do
    let(:ifc_attachment) { nil }

    it 'is invalid' do
      expect_valid(false, base: %i(ifc_attachment_missing))
    end
  end

  context 'if the new ifc file is no valid ifc file' do
    let(:ifc_file) { FileHelpers.mock_uploaded_file name: "model.ifc", content_type: 'application/binary', binary: true }
    let(:ifc_attachment) do
      User.execute_as current_user do
        ifc_model.attach_files('first' => { 'file' => ifc_file, 'description' => 'ifc' })
        ifc_model.attachments.last
      end
    end

    it 'is invalid' do
      expect_valid(false, base: %i(invalid_ifc_file))
    end
  end

  context 'if the new ifc file is a valid ifc file' do
    let(:ifc_file) do
      FileHelpers.mock_uploaded_file name: "model.ifc", content_type: 'application/binary', binary: true, content: "ISO-10303-21;"
    end
    let(:ifc_attachment) do
      User.execute_as current_user do
        ifc_model.attach_files('first' => { 'file' => ifc_file, 'description' => 'ifc' })
        ifc_model.attachments.last
      end
    end

    it_behaves_like 'is valid'
  end

  context 'if user is not allowed to manage ifc models' do
    let(:permissions) { [] }

    it 'is invalid' do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end

  context 'if user of attachment and uploader are different' do
    let(:ifc_attachment) { FactoryBot.build_stubbed(:attachment, author: other_user) }

    it 'is invalid' do
      expect_valid(false, uploader_id: %i(invalid))
    end
  end
end
