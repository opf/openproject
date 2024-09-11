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

RSpec.shared_examples_for "filter dependency" do
  it_behaves_like "has basic schema properties" do
    let(:name) { "Values" }
    let(:required) { true }
    let(:writable) { true }
    let(:has_default) { false }
    let(:location) { "_links" }
  end

  it_behaves_like "does not link to allowed values"

  context "when embedding" do
    let(:form_embedded) { true }

    it_behaves_like "does not link to allowed values"
  end
end

RSpec.shared_examples_for "filter dependency with allowed link" do
  it_behaves_like "has basic schema properties" do
    let(:name) { "Values" }
    let(:required) { true }
    let(:writable) { true }
    let(:has_default) { false }
    let(:location) { "_links" }
  end

  it_behaves_like "does not link to allowed values"

  context "when embedding" do
    let(:form_embedded) { true }

    it_behaves_like "links to allowed values via collection link"
  end
end

RSpec.shared_examples_for "filter dependency with allowed value link collection" do
  it_behaves_like "has basic schema properties" do
    let(:name) { "Values" }
    let(:required) { true }
    let(:writable) { true }
    let(:has_default) { false }
    let(:location) { "_links" }
  end

  it_behaves_like "does not link to allowed values"

  context "when embedding" do
    let(:form_embedded) { true }

    it_behaves_like "links to allowed values directly"
  end
end

RSpec.shared_examples_for "filter dependency empty" do
  it "is an empty object" do
    expect(subject)
      .to be_json_eql({}.to_json)
  end
end

RSpec.shared_examples_for "relation filter dependency" do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project) }
  let(:query) { build_stubbed(:query, project:) }
  let(:form_embedded) { false }

  let(:instance) do
    described_class.new(filter,
                        operator,
                        form_embedded:)
  end

  subject(:generated) { instance.to_json }

  context "generation" do
    context "properties" do
      describe "values" do
        context "within project" do
          let(:path) { "values" }
          let(:type) { "[]WorkPackage" }
          let(:href) { api_v3_paths.work_packages_by_project(project.id) }

          context "for operator 'Queries::Operators::Equals'" do
            let(:operator) { Queries::Operators::Equals }

            it_behaves_like "filter dependency with allowed link"
          end

          context "for operator 'Queries::Operators::NotEquals'" do
            let(:operator) { Queries::Operators::NotEquals }

            it_behaves_like "filter dependency with allowed link"
          end
        end

        context "outside of a project" do
          let(:project) { nil }
          let(:path) { "values" }
          let(:type) { "[]WorkPackage" }
          let(:href) { api_v3_paths.work_packages }

          context "for operator 'Queries::Operators::Equals'" do
            let(:operator) { Queries::Operators::Equals }

            it_behaves_like "filter dependency with allowed link"
          end

          context "for operator 'Queries::Operators::NotEquals'" do
            let(:operator) { Queries::Operators::NotEquals }

            it_behaves_like "filter dependency with allowed link"
          end
        end
      end
    end

    describe "caching" do
      let(:operator) { Queries::Operators::Equals }
      let(:other_project) { build_stubbed(:project) }

      before do
        # fill the cache
        instance.to_json
      end

      it "is cached" do
        expect(instance)
          .not_to receive(:to_hash)

        instance.to_json
      end

      it "busts the cache on a different operator" do
        instance.send(:operator=, Queries::Operators::NotEquals)

        expect(instance)
          .to receive(:to_hash)

        instance.to_json
      end

      it "busts the cache on a different project" do
        query.project = other_project

        expect(instance)
          .to receive(:to_hash)

        instance.to_json
      end

      it "busts the cache on changes to the locale" do
        expect(instance)
          .to receive(:to_hash)

        I18n.with_locale(:de) do
          instance.to_json
        end
      end

      it "busts the cache on different form_embedded" do
        embedded_instance = described_class.new(filter,
                                                operator,
                                                form_embedded: !form_embedded)
        expect(embedded_instance)
          .to receive(:to_hash)

        embedded_instance.to_json
      end
    end
  end
end
