#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require 'spec_helper'

describe Projects::Exports::CSV, 'integration', type: :model do
  before do
    login_as current_user
  end

  let(:project) { FactoryBot.create(:project) }

  let(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i(view_projects))
  end
  let(:query) { Queries::Projects::ProjectQuery.new }
  let(:instance) do
    described_class.new(query)
  end

  it 'performs a successful export' do
    data = ''

    instance.export! do |result|
      data = result.content
    end
    data = CSV.parse(data)

    expect(data.size).to eq(2)
    expect(data.last).to eq [project.id.to_s, project.identifier, project.name, '', 'false']
  end

  context 'with no project visible' do
    let(:current_user) { User.anonymous }

    it 'does not include the project' do
      data = ''

      instance.export! do |result|
        data = result.content
      end
      expect(data).not_to include project.identifier

      data = CSV.parse(data)
      expect(data.size).to eq(1)
    end
  end
end
