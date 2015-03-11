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

shared_examples_for 'has basic schema properties' do
  it 'exists' do
    is_expected.to have_json_path(path)
  end

  it 'has a type' do
    is_expected.to be_json_eql(type.to_json).at_path("#{path}/type")
  end

  it 'has a name' do
    is_expected.to be_json_eql(name.to_json).at_path("#{path}/name")
  end

  it 'indicates if it is required' do
    is_expected.to be_json_eql(required.to_json).at_path("#{path}/required")
  end

  it 'indicates if it is writable' do
    is_expected.to be_json_eql(writable.to_json).at_path("#{path}/writable")
  end
end

shared_examples_for 'links to allowed values directly' do
  it 'has the expected number of links' do
    is_expected.to have_json_size(hrefs.size).at_path("#{path}/_links/allowedValues")
  end

  it 'contains links to the allowed values' do
    index = 0
    hrefs.each do |href|
      href_path = "#{path}/_links/allowedValues/#{index}/href"
      is_expected.to be_json_eql(href.to_json).at_path(href_path)
      index += 1
    end
  end
end

shared_examples_for 'links to and embeds allowed values directly' do
  it_behaves_like 'links to allowed values directly'

  it 'has the expected number of embedded values' do
    is_expected.to have_json_size(hrefs.size).at_path("#{path}/_embedded/allowedValues")
  end

  it 'embeds the allowed values' do
    index = 0
    hrefs.each do |href|
      href_path = "#{path}/_embedded/allowedValues/#{index}/_links/self/href"
      is_expected.to be_json_eql(href.to_json).at_path(href_path)
      index += 1
    end
  end
end

shared_examples_for 'links to allowed values via collection link' do
  it 'contains the link to the allowed values' do
    is_expected.to be_json_eql(href.to_json).at_path("#{path}/_links/allowedValues/href")
  end
end

shared_examples_for 'does not link to allowed values' do
  it 'contains no link to the allowed values' do
    is_expected.not_to have_json_path("#{path}/_links/allowedValues")
  end

  it 'does not embed allowed values' do
    is_expected.not_to have_json_path("#{path}/_embedded/allowedValues")
  end
end
