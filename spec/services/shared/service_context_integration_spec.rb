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

RSpec.describe Shared::ServiceContext, "integration", type: :model do
  let(:user) { build_stubbed(:user) }

  let(:instance) do
    Class.new do
      include Shared::ServiceContext

      attr_accessor :user

      def initialize(user)
        self.user = user
      end

      def test_method_failure(model)
        in_context model do
          Setting.connection.execute <<~SQL
            INSERT INTO settings (name, value)
            VALUES ('test_setting', 'abc')
          SQL

          ServiceResult.failure
        end
      end

      def test_method_success(model)
        in_context model do
          Setting.connection.execute <<~SQL
            INSERT INTO settings (name, value)
            VALUES ('test_setting', 'abc')
          SQL

          ServiceResult.success
        end
      end
    end.new(user)
  end

  describe "#in_context" do
    context "with a model" do
      let(:model) { User.new } # model implementation is irrelevant

      context "with a failure result" do
        it "reverts all database changes" do
          expect { instance.test_method_failure(model) }
            .not_to change { Setting.count }
        end
      end

      context "with a success result" do
        it "keeps database changes" do
          expect { instance.test_method_success(model) }
            .to change { Setting.count }
        end
      end
    end

    context "without a model" do
      let(:model) { nil }

      context "with a failure result" do
        it "reverts all database changes" do
          expect { instance.test_method_failure(model) }
            .not_to change { Setting.count }
        end
      end

      context "with a success result" do
        it "keeps database changes" do
          expect { instance.test_method_success(model) }
            .to change { Setting.count }
        end
      end
    end
  end
end
