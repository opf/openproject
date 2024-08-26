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

RSpec.describe HookHelper do
  describe "#call_hook" do
    context "when called within a controller" do
      let(:test_hook_controller_class) do
        # Also tests that the application controller has the model included
        Class.new(ApplicationController)
      end
      let(:instance) do
        test_hook_controller_class.new.tap do |inst|
          inst.instance_variable_set(:@project, project)
          allow(inst)
            .to receive(:request)
                  .and_return(request)
        end
      end
      let(:project) do
        instance_double(Project)
      end
      let(:request) do
        instance_double(ActionDispatch::Request)
      end

      it "adds to the context" do
        allow(OpenProject::Hook)
          .to receive(:call_hook)

        instance.call_hook(:some_hook_identifier, {})

        expect(OpenProject::Hook)
          .to have_received(:call_hook)
                .with(:some_hook_identifier, { project:,
                                               controller: instance,
                                               request:,
                                               hook_caller: instance })
      end
    end

    context "when called within a view" do
      let(:test_hook_view_class) do
        # Also tests that the application controller has the model included
        Class.new(ActionView::Base) do
          include HookHelper
        end
      end
      let(:instance) do
        test_hook_view_class
          .new(ActionView::LookupContext.new(Rails.root.join("app/views")), {}, nil)
          .tap do |inst|
          inst.instance_variable_set(:@project, project)
          allow(inst)
            .to receive(:request)
            .and_return(request)
          allow(inst)
            .to receive(:controller)
            .and_return(controller_instance)
        end
      end
      let(:project) do
        instance_double(Project)
      end
      let(:request) do
        instance_double(ActionDispatch::Request)
      end
      let(:controller_instance) do
        instance_double(ApplicationController)
      end

      it "adds to the context" do
        # mimics having two different classes registered for the hook
        allow(OpenProject::Hook)
          .to receive(:call_hook)
          .and_return(%w[response1 response2])

        expect(instance.call_hook(:some_hook_identifier, {}))
          .to eql "response1 response2"

        expect(OpenProject::Hook)
          .to have_received(:call_hook)
                .with(:some_hook_identifier, { project:,
                                               controller: controller_instance,
                                               request:,
                                               hook_caller: instance })
      end
    end
  end
end
