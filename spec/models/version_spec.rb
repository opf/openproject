#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Version, :type => :model do

  subject(:version){ FactoryGirl.build(:version, name: "Test Version") }

  it { is_expected.to be_valid }

  it "rejects a due date that is smaller than the start date" do
    version.start_date = '2013-05-01'
    version.effective_date = '2012-01-01'

    expect(version).not_to be_valid
    expect(version.errors_on(:effective_date).size).to eq(1)
  end

  context '#to_s_for_project' do
    let(:other_project) { FactoryGirl.build(:project) }

    it 'returns only the version for the same project' do
      expect(version.to_s_for_project(version.project)).to eq("#{version.name}")
    end

    it 'returns the project name and the version name for a different project' do
      expect(version.to_s_for_project(other_project)).to eq("#{version.project.name} - #{version.name}")
    end
  end

  context 'deprecated methods' do
    it { is_expected.to respond_to :completed_pourcent }
    it { is_expected.to respond_to :closed_pourcent    }
  end

  describe :systemwide do
    it 'contains the version if it is shared with all projects' do
      version.sharing = 'system'
      version.save!

      expect(Version.systemwide.all).to match_array [version]
    end

    it 'is empty if the version is not shared' do
      version.sharing = 'none'
      version.save!

      expect(Version.systemwide.all).to be_empty
    end

    it 'is empty if the version is shared with the project hierarchy' do
      version.sharing = 'hierarchy'
      version.save!

      expect(Version.systemwide.all).to be_empty
    end
  end
end
