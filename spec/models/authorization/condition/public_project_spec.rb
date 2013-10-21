#-- encoding: UTF-8
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

require_relative 'shared/allows_concatenation'

describe Authorization::Condition::PublicProject do

  include Spec::Authorization::Condition::AllowsConcatenation

  let(:scope) { double('scope', :has_table? => true) }
  let(:klass) { Authorization::Condition::PublicProject }
  let(:instance) { klass.new(scope) }
  let(:members_table) { Member.arel_table }
  let(:roles_table) { Role.arel_table }
  let(:projects_table) { Project.arel_table }
  let(:non_nil_options) { { } }
  let(:non_nil_arel) do
    projects_table[:is_public].eq(true)
  end

  it_should_behave_like "allows concatenation"
  it_should_behave_like "requires models", Role, Project

  describe :to_arel do
    it 'returns an arel to find non member in public project if user is not the anonymous user' do
      condition = arel_condition(anonymous: false)

      expect(instance.to_arel(user: double('user', anonymous?: false)).to_sql).to eq(condition.to_sql)
    end

    it 'returns an arel to find anonymous in public project if user is anonymous user' do
      condition = arel_condition(anonymous: true)

      expect(instance.to_arel(user: double('user', anonymous?: true)).to_sql).to eq(condition.to_sql)
    end

    it 'returns an arel to public_projects if user nil' do
      condition = non_nil_arel

      expect(instance.to_arel(user: nil).to_sql).to eq(condition.to_sql)
    end
  end

  def arel_condition(anonymous: true)
    id = anonymous ?
           Role.anonymous.id :
           Role.non_member.id

    anonymous_role = roles_table[:id].eq(id)
    public_project = projects_table[:is_public].eq(true)

    condition = anonymous_role.and(public_project)

    projects_table.grouping(condition)
  end
end
