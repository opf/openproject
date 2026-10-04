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

module Storages
  module Adapters
    module Input
      RSpec.describe UploadFile do
        subject(:input) { described_class }

        let(:parent_location) { "/foo" }
        let(:file_name) { "bar.txt" }
        let(:io) { StringIO.new("this is some file content") }

        describe ".new" do
          it "discourages direct instantiation" do
            expect { input.new(parent_location:, file_name:, io:) }.to raise_error(NoMethodError, /private method 'new'/)
          end
        end

        describe ".build" do
          subject { input.build(parent_location:, file_name:, io:) }

          it { is_expected.to be_success }

          it "coerces the parent location into a ParentFolder object" do
            result = subject.value!

            expect(result.parent_location).to be_a(Peripherals::ParentFolder)
            expect(result.parent_location.path).to eq(parent_location)
          end

          context "when the parent location is not a string" do
            let(:parent_location) { 42 }

            it { is_expected.to be_failure }
          end

          context "when the file name is not a string" do
            let(:file_name) { 42 }

            it { is_expected.to be_failure }
          end

          context "when the IO is a temp file" do
            let(:io) { Tempfile.new }

            it { is_expected.to be_success }
          end

          context "when the IO is a custom implementation of an IO" do
            let(:io) { instance_double(IO).as_null_object }

            it { is_expected.to be_success }
          end

          context "when the IO is a string" do
            let(:io) { "" }

            it { is_expected.to be_failure }
          end
        end
      end
    end
  end
end
