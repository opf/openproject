# --copyright
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

require "spec_helper"

RSpec.describe Redmine::Plugin do
  let!(:registered_plugins) { described_class.instance_variable_get(:@registered_plugins) }

  before do
    described_class.clear
  end

  after do
    described_class.instance_variable_set(:@registered_plugins, registered_plugins)
  end

  describe ".register" do
    context "for a plugin with properties" do
      before do
        described_class.register :foo do
          name "Foo plugin"
          url "https://example.net/plugins/foo"
          author "John Smith"
          author_url "https://example.net/jsmith"
          description "This is a test plugin"
          version "0.0.1"
          settings default: { "sample_setting" => "value", "foo" => "bar" },
                   partial: "foo/settings"
        end
      end

      subject { described_class.find(:foo) }

      it "has the provided id" do
        expect(subject.id)
          .to eq :foo
      end

      it "has the provided url" do
        expect(subject.url)
          .to eq "https://example.net/plugins/foo"
      end

      it "has the provided author" do
        expect(subject.author)
          .to eq "John Smith"
      end

      it "has the provided author url" do
        expect(subject.author_url)
          .to eq "https://example.net/jsmith"
      end

      it "has the provided description" do
        expect(subject.description)
          .to eq "This is a test plugin"
      end

      it "has the provided version" do
        expect(subject.version)
          .to eq "0.0.1"
      end

      it "adds a setting" do
        expect(Setting["plugin_foo"])
          .to eq("sample_setting" => "value", "foo" => "bar")
      end
    end
  end

  describe ".register with #requires_openproject" do
    it "allows registering with a version requirement lower than the op version" do
      expect do
        described_class.register(:foo) do
          requires_openproject(">= #{OpenProject::VERSION.to_semver.gsub(/\A\d+/) { |num| num.to_i - 1 }}")
        end
      end.not_to raise_error
    end

    it "allows registering with a version requirement to be the op version as a minumum" do
      expect do
        described_class.register(:foo) { requires_openproject(">= #{OpenProject::VERSION.to_semver}") }
      end.not_to raise_error
    end

    it "allows registering with a version requirement equal to the op version" do
      expect do
        described_class.register(:foo) { requires_openproject(OpenProject::VERSION.to_semver) }
      end.not_to raise_error
    end

    it "allows registering with a version requirement equal to the minor op version" do
      expect do
        described_class.register(:foo) { requires_openproject("~> #{OpenProject::VERSION.to_semver.gsub(/\d+\z/, '0')}") }
      end.not_to raise_error
    end

    it "allows registering with a version requirement between two versions" do
      expect do
        described_class.register(:foo) do
          requires_openproject("> #{OpenProject::VERSION.to_semver.gsub(/\A\d+/) { |num| num.to_i - 1 }}",
                               "<= #{OpenProject::VERSION.to_semver.gsub(/\d+\z/) { |num| num.to_i + 1 }}")
        end
      end.not_to raise_error
    end

    it "raises when registering with a minimum version requirement not met" do
      expect do
        described_class.register(:foo) do
          requires_openproject(">= #{OpenProject::VERSION.to_semver.next}")
        end
      end.to raise_error Redmine::PluginRequirementError
    end

    it "raises when registering with a maximum version requirement not met" do
      expect do
        described_class.register(:foo) do
          requires_openproject("< #{OpenProject::VERSION.to_semver}")
        end
      end.to raise_error Redmine::PluginRequirementError
    end

    it "raises registering with a minimum and maximum version requirement which are both not met" do
      expect do
        described_class.register(:foo) do
          requires_openproject("< #{OpenProject::VERSION.to_semver}",
                               ">= #{OpenProject::VERSION.to_semver.next}")
        end
      end.to raise_error Redmine::PluginRequirementError
    end
  end

  describe ".register with #requires_redmine_plugin" do
    before do
      described_class.register :other do
        name "Other"
        version "0.5.0"
      end
    end

    it "allows registering with a version requirement lower than the plugin version" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:other, "0.4.0")
        end
      end.not_to raise_error
    end

    it "allows registering with a version requirement equal to the plugin version" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:other, "0.5.0")
        end
      end.not_to raise_error
    end

    it "raises an error when registering with a version requirement higher than the plugin version" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:other, "0.5.1")
        end
      end.to raise_error Redmine::PluginRequirementError
    end

    it "allows registering with a version requirement that is exactly the plugin version" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:other, version: "0.5.0")
        end
      end.not_to raise_error
    end

    it "allows registering with a version requirement that is exactly the plugin version from a list of allowed" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:other, version: %w[0.5.0 99.9.9])
        end
      end.not_to raise_error
    end

    it "raises an error when registering with a version requirement that is not exactly the specified one" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:other, version: "0.4.0")
        end
      end.to raise_error Redmine::PluginRequirementError
    end

    it "raises an error when registering with a version requirement that is not one of the exactly specified ones" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:other, version: %w[0.4.0 0.5.1 0.9.9])
        end
      end.to raise_error Redmine::PluginRequirementError
    end

    it "raises for a missing plugin with an exact version specification" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:missing, version_or_higher: "0.4.0")
        end
      end.to raise_error Redmine::PluginNotFound
    end

    it "raises for a missing plugin with a minimum version specification" do
      expect do
        described_class.register(:foo) do
          requires_redmine_plugin(:missing, version_or_higher: %w[0.4.0 0.5.1 0.9.9])
        end
      end.to raise_error Redmine::PluginNotFound
    end
  end
end
