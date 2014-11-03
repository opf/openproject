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

describe Authorization::Condition::AnonymousInProject do

  include Spec::Authorization::Condition::AllowsConcatenation


  let(:scope) { double('scope', :has_table? => true) }
  let(:klass) { Authorization::Condition::AnonymousInProject }
  let(:instance) { klass.new(scope) }
  let(:principals_table) { Principal.arel_table }
  let(:roles_table) { Role.arel_table }
  let(:non_nil_options) { { project: double('project', is_public?: true) } }
  let(:non_nil_arel) do
    anonymous_user = principals_table[:id].eq(User.anonymous.id)
    anonymous_role = roles_table[:id].eq(Role.anonymous.id)

    anonymous = anonymous_role.and(anonymous_user)

    principals_table.grouping(anonymous)
  end

  it_should_behave_like "allows concatenation"
  it_should_behave_like "requires models", Role, Principal

  describe :to_arel do
    it 'returns an arel to find anonymous (non member) if no project is provided' do
      expect(instance.to_arel.to_sql).to eq(non_nil_arel.to_sql)
    end
  end
end
