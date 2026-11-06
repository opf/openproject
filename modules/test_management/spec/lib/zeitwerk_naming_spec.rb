# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Test management constant naming" do # rubocop:disable RSpec/DescribeClass
  let(:root) { OpenProject::TestManagement::Engine.root }

  it "eager loads every autoloaded directory of the module" do
    Dir[root.join("app/*")].reject { |dir| dir.end_with?("/views", "/assets") }.each do |dir|
      expect { Rails.autoloaders.main.eager_load_dir(dir) }.not_to raise_error
    end
  end

  it "names every migration class after its file" do
    Dir[root.join("db/migrate/*.rb")].each do |file|
      require file
      class_name = File.basename(file, ".rb").sub(/\A\d+_/, "").camelize
      expect(Object.const_defined?(class_name)).to be(true), "#{File.basename(file)} should define #{class_name}"
    end
  end
end
