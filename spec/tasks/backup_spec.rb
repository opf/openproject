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

RSpec.describe Rake::Task, "backup:database" do
  let(:database_config) do
    { "adapter" => "postgresql",
      "database" => "openproject-database",
      "username" => "test_user",
      "password" => "test_password" }
  end

  let(:hash_config) do
    ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary", database_config)
  end

  before do
    allow(ActiveRecord::Base).to receive(:connection_db_config).and_return(hash_config)
    allow(FileUtils).to receive(:mkdir_p).and_return(nil)
    allow(Kernel).to receive(:system)
  end

  describe "backup:database:create" do
    include_context "rake"

    it "calls the pg_dump binary" do
      subject.invoke
      expect(Kernel).to have_received(:system) do |*args|
        expect(args[1]).to eql("pg_dump")
      end
    end

    it "passes environment variables to the binary" do
      subject.invoke
      expect(Kernel).to have_received(:system) do |*args|
        expect(args[0]).to include("PGUSER" => "test_user", "PGPASSWORD" => "test_password")
      end
    end

    it "uses the first task parameter as the target filename" do
      custom_file_path = "./foo/bar/test_file.sql"
      subject.invoke custom_file_path
      expect(Kernel).to have_received(:system) do |*args|
        result_file = args.find { |s| s.to_s.starts_with? "--file=" }
        expect(result_file).to include(custom_file_path)
      end
    end
  end

  describe "backup:database:restore" do
    include_context "rake"

    let(:backup_file) do
      Tempfile.new("test_backup")
    end

    after do
      backup_file.unlink
    end

    it "calls the pg_restore binary" do
      subject.invoke backup_file.path
      expect(Kernel).to have_received(:system) do |*args|
        expect(args[1]).to start_with("pg_restore")
      end
    end

    it "passes environment variables to the binary" do
      subject.invoke backup_file.path
      expect(Kernel).to have_received(:system) do |*args|
        expect(args[0]).to include("PGUSER" => "test_user", "PGPASSWORD" => "test_password")
      end
    end

    it "uses the first task parameter as the target filename" do
      subject.invoke backup_file.path
      expect(Kernel).to have_received(:system) do |*args|
        expect(args.last).to eql(backup_file.path)
      end
    end

    it "specifies database name" do
      subject.invoke backup_file.path
      expect(Kernel).to have_received(:system) do |*args|
        expect(args).to include "--dbname=openproject-database"
      end
    end

    it "throws an error when called without a parameter" do
      expect { subject.invoke }.to raise_error(RuntimeError, "You must provide the path to the database dump")
    end
  end
end
