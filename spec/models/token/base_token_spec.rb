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

describe ::Token::Base, type: :model do
  let(:user) { FactoryBot.build(:user) }

  subject { described_class.new user: user }

  it 'should create' do
    subject.save!
    assert_equal 64, subject.value.length
  end

  it 'should create_should_remove_existing_tokens' do
    subject.save!
    t2 = Token::AutoLogin.create user: user
    expect(subject.value).not_to eq(t2.value)
    expect(Token::AutoLogin.exists?(subject.id)).to eq false
    expect(Token::AutoLogin.exists?(t2.id)).to eq true
  end
end
