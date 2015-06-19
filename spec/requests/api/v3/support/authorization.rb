#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

shared_examples_for 'handling anonymous user' do |type, path|
  context 'anonymous user' do
    let(:get_path) { path % [id] }

    context 'when access for anonymous user is allowed' do
      before { get get_path }

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct type' do
        expect(subject.body).to include_json(type.to_json).at_path('_type')
        expect(subject.body).to be_json_eql(id.to_json).at_path('id')
      end
    end

    context 'when access for anonymous user is not allowed' do
      before do
        allow(Setting).to receive(:login_required?).and_return(true)
        get get_path
      end

      it_behaves_like 'unauthenticated access'
    end
  end
end
