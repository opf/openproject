#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.shared_examples_for "has basic schema properties" do
  it "exists" do
    expect(subject).to have_json_path(path)
  end

  it "has a type" do
    expect(subject).to be_json_eql(type.to_json).at_path("#{path}/type")
  end

  it "has a name" do
    expect(subject).to be_json_eql(name.to_json).at_path("#{path}/name")
  end

  it "indicates if it is required" do
    expect(subject).to be_json_eql(required.to_json).at_path("#{path}/required")
  end

  it "indicates if it is writable" do
    expect(subject).to be_json_eql(writable.to_json).at_path("#{path}/writable")
  end

  it "indicates if it has default" do
    expected_has_default = if defined?(has_default)
                             has_default
                           else
                             false
                           end

    expect(subject)
      .to be_json_eql(expected_has_default.to_json)
      .at_path("#{path}/hasDefault")
  end

  it "indicates if it has a location" do
    if defined?(location)
      expect(subject)
        .to be_json_eql(location.to_json)
              .at_path("#{path}/location")
    else
      expect(subject).not_to have_json_path("#{path}/location")
    end
  end

  it "indicates if it has a description" do
    if defined?(description)
      expect(subject)
        .to be_json_eql(description.to_json)
              .at_path("#{path}/description/raw")
    else
      expect(subject).not_to have_json_path("#{path}/description")
    end
  end
end

RSpec.shared_examples_for "indicates length requirements" do
  it "indicates its minimum length" do
    if defined?(min_length)
      expect(subject)
        .to be_json_eql(min_length.to_json)
        .at_path("#{path}/minLength")
    else
      expect(subject)
        .not_to have_json_path("#{path}/minLength")
    end
  end

  it "indicates its maximum length" do
    if defined?(max_length)
      expect(subject)
        .to be_json_eql(max_length.to_json)
        .at_path("#{path}/maxLength")
    else
      expect(subject)
        .not_to have_json_path("#{path}/maxLength")
    end
  end
end

RSpec.shared_examples_for "links to allowed values directly" do
  it "has the expected number of links" do
    expect(subject).to have_json_size(hrefs.size).at_path("#{path}/_links/allowedValues")
  end

  it "contains links to the allowed values" do
    index = 0
    hrefs.each do |href|
      href_path = "#{path}/_links/allowedValues/#{index}/href"
      expect(subject).to be_json_eql(href.to_json).at_path(href_path)
      index += 1
    end
  end
end

RSpec.shared_examples_for "links to and embeds allowed values directly" do
  it_behaves_like "links to allowed values directly"

  it "has the expected number of embedded values" do
    expect(subject).to have_json_size(hrefs.size).at_path("#{path}/_embedded/allowedValues")
  end

  it "embeds the allowed values" do
    index = 0
    hrefs.each do |href|
      href_path = "#{path}/_embedded/allowedValues/#{index}/_links/self/href"
      expect(subject).to be_json_eql(href.to_json).at_path(href_path)
      index += 1
    end
  end
end

RSpec.shared_examples_for "links to allowed values via collection link" do
  it "contains the link to the allowed values" do
    expect(subject).to be_json_eql(href.to_json).at_path("#{path}/_links/allowedValues/href")
  end
end

RSpec.shared_examples_for "does not link to allowed values" do
  it "contains no link to the allowed values" do
    expect(subject).not_to have_json_path("#{path}/_links/allowedValues")
  end

  it "does not embed allowed values" do
    expect(subject).not_to have_json_path("#{path}/_embedded/allowedValues")
  end
end
