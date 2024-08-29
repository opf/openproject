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

require Rails.root + "spec/support/file_helpers"

FactoryBot.define do
  factory :attachment do
    container factory: :work_package
    author factory: :user
    description { nil }

    transient do
      filename { nil }
    end

    content_type { "application/binary" }
    sequence(:file) do |n|
      FileHelpers.mock_uploaded_file name: filename || "file-#{n}.test",
                                     content_type:,
                                     binary: true
    end

    callback(:after_build, :after_stub) do |attachment, evaluator|
      attachment.filename = evaluator.filename if evaluator.filename
    end

    factory :wiki_attachment do
      container factory: :wiki_page
    end

    factory :attached_picture do
      content_type { "image/jpeg" }
    end

    factory :pending_direct_upload do
      status { "prepared" }
      created_at { DateTime.now - 2.weeks }
    end
  end
end
