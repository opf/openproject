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
  factory :ifc_model, class: "::Bim::IfcModels::IfcModel" do
    sequence(:title) { |n| "Unconverted IFC model #{n}" }
    project factory: :project
    uploader factory: :user
    is_default { true }
    transient do
      ifc_attachment do
        Rack::Test::UploadedFile.new(
          Rails.root.join("modules/bim/spec/fixtures/files/minimal.ifc").to_s,
          "application/binary"
        )
      end

      callback(:after_create) do |model, evaluator|
        User.system.run_given do
          model.ifc_attachment = evaluator.ifc_attachment
        end
      end
    end

    factory :ifc_model_minimal_converted do
      sequence(:title) { |n| "Converted IFC model #{n}" }
      project factory: :project
      uploader factory: :user
      is_default { true }
      transient do
        xkt_attachment do
          Rack::Test::UploadedFile.new(
            Rails.root.join("modules/bim/spec/fixtures/files/minimal.xkt").to_s,
            "application/binary"
          )
        end
      end

      callback(:after_create) do |model, evaluator|
        User.system.run_given do
          model.xkt_attachment = evaluator.xkt_attachment
        end
      end
    end
  end

  factory :ifc_model_without_ifc_attachment, class: "::Bim::IfcModels::IfcModel" do
    sequence(:title) { |n| "Model without ifc_attachment #{n}" }
    project factory: :project
    uploader factory: :user
    is_default { true }
  end
end
