# frozen_string_literal: true

# -- copyright
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
# ++

RSpec.shared_context "on api v3 paths" do
  let(:helper) { Class.new.tap { |c| c.extend(API::V3::Utilities::PathHelper) }.api_v3_paths }

  shared_examples_for "path" do |url|
    it "provides the path" do
      expect(subject).to match(url)
    end

    it "prepends the sub uri if configured" do
      allow(OpenProject::Configuration).to receive(:rails_relative_url_root)
                                             .and_return("/open_project")

      expect(subject).to match("/open_project#{url}")
    end
  end

  before do
    RequestStore.store[:cached_root_path] = nil
  end

  after do
    RequestStore.clear!
  end

  shared_examples_for "api v3 path" do |url|
    it_behaves_like "path", "/api/v3#{url}"
  end

  shared_examples_for "index" do |name|
    plural_name = name.to_s.pluralize # rubocop:disable RSpec/LeakyLocalVariable

    describe "##{plural_name}" do
      subject { helper.send(plural_name) }

      it_behaves_like "api v3 path", "/#{plural_name}"
    end
  end

  shared_examples_for "show" do |name|
    describe "##{name}" do
      subject { helper.send(:"#{name}", 42) }

      it_behaves_like "api v3 path", "/#{name.to_s.pluralize}/42"
    end
  end

  shared_examples_for "create form" do |name|
    describe "#create_#{name}_form" do
      subject { helper.send(:"create_#{name}_form") }

      it_behaves_like "api v3 path", "/#{name.to_s.pluralize}/form"
    end
  end

  shared_examples_for "update form" do |name|
    describe "##{name}_form" do
      subject { helper.send(:"#{name}_form", 42) }

      it_behaves_like "api v3 path", "/#{name.to_s.pluralize}/42/form"
    end
  end

  shared_examples_for "schema" do |name|
    describe "##{name}_schema" do
      subject { helper.send(:"#{name}_schema") }

      it_behaves_like "api v3 path", "/#{name.to_s.pluralize}/schema"
    end
  end

  shared_examples_for "resource" do |name, except: []|
    it_behaves_like("index", name) unless except.include?(:index)
    it_behaves_like("show", name) unless except.include?(:show)
    it_behaves_like("update form", name) unless except.include?(:update_form)
    it_behaves_like("create form", name) unless except.include?(:create_form)
    it_behaves_like("schema", name) unless except.include?(:schema)
  end
end
