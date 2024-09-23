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

FactoryBot.define do
  factory :bcf_viewpoint, class: "::Bim::Bcf::Viewpoint" do
    new_uuid = SecureRandom.uuid
    uuid { new_uuid }
    viewpoint_name { "full_viewpoint.bcfv" }
    json_viewpoint do
      file = OpenProject::Bim::Engine.root.join("spec/fixtures/viewpoints/#{viewpoint_name}.json")
      if file.readable?
        JSON.parse(file.read)
      else
        warn "Viewpoint name #{viewpoint_name} doesn't map to a viewpoint fixture"
      end
    end

    transient do
      snapshot { nil }
    end

    after(:create) do |viewpoint, evaluator|
      unless evaluator.snapshot == false
        create(:bcf_viewpoint_attachment, container: viewpoint)
      end
    end
  end
end
