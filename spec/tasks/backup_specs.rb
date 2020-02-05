#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'postgresql' do
  let(:database_config) do
    { 'adapter' => 'postgresql',
      'database' => 'openproject-database',
      'username' => 'testuser',
      'password' => 'testpassword' }
  end

  before do
    expect(ActiveRecord::Base).to receive(:configurations).at_least(:once).and_return('test' => database_config)
    allow(FileUtils).to receive(:mkdir_p).and_return(nil)
  end

  describe 'backup:database:create' do
    include_context 'rake'

    it 'calls the pg_dump binary' do
      expect(Kernel).to receive(:system) do |*args|
        expect(args[1]).to eql('pg_dump')
      end
      subject.invoke
    end

    it 'writes the pg password file' do
      expect(Kernel).to receive(:system) do |*args|
        pass_file = args.first['PGPASSFILE']
        expect(File.readable?(pass_file)).to be true

        file_contents = File.read pass_file
        expect(file_contents).to include('testpassword')
      end
      subject.invoke
    end

    it 'uses the first task parameter as the target filename' do
      custom_file_path = './foo/bar/testfile.sql'
      expect(Kernel).to receive(:system) do |*args|
        result_file = args.find { |s| s.to_s.starts_with? '--file=' }
        expect(result_file).to include(custom_file_path)
      end
      subject.invoke custom_file_path
    end
  end

  describe 'backup:database:restore' do
    include_context 'rake'

    let(:backup_file) do
      Tempfile.new('test_backup')
    end

    after do
      backup_file.unlink
    end

    it 'calls the pg_restore binary' do
      expect(Kernel).to receive(:system) do |*args|
        expect(args[1]).to start_with('pg_restore')
      end
      subject.invoke backup_file.path
    end

    it 'writes the pg password file' do
      expect(Kernel).to receive(:system) do |*args|
        pass_file = args.first['PGPASSFILE']
        expect(File.readable?(pass_file)).to be true

        file_contents = File.read pass_file
        expect(file_contents).to include('testpassword')
      end
      subject.invoke backup_file.path
    end

    it 'uses the first task parameter as the target filename' do
      expect(Kernel).to receive(:system) do |*args|
        expect(args.last).to eql(backup_file.path)
      end
      subject.invoke backup_file.path
    end

    it 'throws an error when called without a parameter' do
      expect { subject.invoke }.to raise_error
    end
  end
end
