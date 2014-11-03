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

describe Authorization::Condition::QueriedUserIsAdmin do

  include Spec::Authorization::Condition::AllowsConcatenation


  let(:scope) { double('scope') }
  let(:klass) { Authorization::Condition::QueriedUserIsAdmin }
  let(:instance) { klass.new(scope) }
  let(:nil_options) { {} }
  let(:non_nil_options) { { user: double('user', admin?: true), admin_pass: true } }
  let(:non_nil_arel) do
    Arel::Nodes::Equality.new(1, 1)
  end

  it_should_behave_like "allows concatenation"

  describe :to_arel do
    it 'returns "and neutral" arel if admin user is provided and admin pass allowed' do
      options = { user: double('user', admin?: true), admin_pass: true }

      expect(instance.to_arel(options).to_sql).to eq(Arel::Nodes::Equality.new(1, 1).to_sql)
    end

    it 'returns nil if admin user is provided and admin pass forbidden' do
      options = { user: double('user', admin?: true), admin_pass: false }

      expect(instance.to_arel(options)).to be_nil
    end

    it 'returns "or neutral" arel if non admin user is provided and admin pass allowed' do
      options = { user: double('user', admin?: false), admin_pass: true }

      expect(instance.to_arel(options)).to be_nil
    end

    it 'returns "or neutral" arel if no user is provided and admin pass allowed' do
      options = { user: nil, admin_pass: true }

      expect(instance.to_arel(options)).to be_nil
    end
  end
end
