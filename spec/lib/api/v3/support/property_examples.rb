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

shared_examples_for 'property' do |name|
  it "has the #{name} property" do
    is_expected
      .to be_json_eql(value.to_json)
      .at_path(name.to_s)
  end
end

shared_examples_for 'formattable property' do |name|
  it "has the #{name} property" do
    is_expected
      .to be_json_eql(value.to_json)
      .at_path("#{name.to_s}/raw")
  end
end

shared_examples_for 'date property' do |name|
  it_behaves_like 'has ISO 8601 date only' do
    let(:json_path) { name.to_s }
    let(:date) { value }
  end
end

shared_examples_for 'datetime property' do |name|
  it_behaves_like 'has UTC ISO 8601 date and time' do
    let(:json_path) { name.to_s }
    let(:date) { value }
  end
end
