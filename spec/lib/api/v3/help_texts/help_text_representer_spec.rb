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

describe ::API::V3::HelpTexts::HelpTextRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:user) { FactoryBot.build_stubbed :admin }

  let(:help_text) do
    FactoryBot.build_stubbed :work_package_help_text,
                             attribute_name: 'status',
                             help_text: 'This is a help text for **status** attribute.'
  end

  let(:representer) { described_class.new help_text, current_user: user }

  let(:result) do
    {
      "_type" => "HelpText",
      "_links" => {
        "self" => {
          "href" => "/api/v3/help_texts/#{help_text.id}"
        },
        "editText" => {
          "href" => edit_attribute_help_text_path(help_text.id),
          "type" => "text/html"
        }
      },
      "id" => help_text.id,
      "scope" => "WorkPackage",
      "attribute" => "status",
      "attributeCaption" => "Status",
      "helpText" => {
        "format" => 'markdown',
        "raw" => 'This is a help text for **status** attribute.',
        "html" => '<p>This is a help text for <strong>status</strong> attribute.</p>'
      }
    }
  end

  it 'serializes the relation correctly' do
    data = JSON.parse representer.to_json
    expect(data).to eq result
  end
end
