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

RSpec.shared_context "ModelContract shared context" do # rubocop:disable RSpec/ContextWording
  def expect_contract_valid
    expect(contract.validate)
      .to be(true),
          "Expected contract to be valid. Got invalid contract with the following errors: #{contract.errors.details}"
  end

  def expect_contract_invalid(errors = {})
    expect(contract.validate).to be(false)

    expected_errors = errors.transform_values do |error_symbols|
      case error_symbols
      when [], nil
        []
      when Array
        an_array_matching(error_symbols)
      else
        [error_symbols]
      end
    end

    contract_errors = errors.keys.index_with do |key|
      errors[key].is_a?(Hash) ? contract.errors.details[key] : contract.errors.symbols_for(key)
    end

    expect(contract_errors).to match(expected_errors)
    if RSpec.current_example.metadata[:check_errors_i18n]
      # ensure no I18n::MissingTranslationData is raised because of missing attributes and/or errors translations
      expect { contract.errors.full_messages }.not_to raise_error
    end
  end

  shared_examples "contract is valid" do
    it "contract is valid" do
      expect_contract_valid
    end
  end

  shared_examples "contract is invalid" do |error_symbols = {}|
    example_title = "contract is invalid"
    example_title += " with #{error_symbols.inspect}" if error_symbols.any?

    it example_title do
      expect_contract_invalid error_symbols
    end
  end

  shared_examples "contract user is unauthorized" do
    include_examples "contract is invalid", base: :error_unauthorized
  end

  shared_examples "contract is valid for active admins and invalid for regular users" do
    context "when admin" do
      let(:current_user) { build_stubbed(:admin) }

      context "when active" do
        include_examples "contract is valid"
      end

      context "when not active" do
        let(:current_user) { build_stubbed(:admin, status: User.statuses[:locked]) }

        it_behaves_like "contract user is unauthorized"
      end
    end

    context "when not admin" do
      let(:current_user) { build_stubbed(:user) }

      it_behaves_like "contract user is unauthorized"
    end
  end

  shared_examples "contract reuses the model errors" do
    it "reuses the model`s errors object" do
      expect(contract.errors.object_id).to be(contract.model.errors.object_id)
    end
  end
end
