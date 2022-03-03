#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

describe Project, 'reordering of nested set', type: :model do
  shared_let(:parent_project) { create :project, name: 'Parent' }

  # Create some children in non-alphabetical order
  shared_let(:child_a) { create :project, name: 'A', parent: parent_project }
  shared_let(:child_f) { create :project, name: 'F', parent: parent_project }
  shared_let(:child_b) { create :project, name: 'B', parent: parent_project }

  subject { parent_project.children.reorder(:lft) }

  it 'has the correct sort' do
    expect(subject.reload.pluck(:name)).to eq %w[A B F]
  end

  context 'when renaming a child' do
    before do
      child_a.update! name: 'Z'
    end

    it 'updates that order' do
      expect(subject.reload.pluck(:name)).to eq %w[B F Z]
    end
  end
end
