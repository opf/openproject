#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Utilities::PathHelper do
  let(:helper) { Class.new.tap { |c| c.extend(::API::V3::Utilities::PathHelper) }.api_v3_paths }

  shared_examples_for 'api v3 path' do
    it { is_expected.to match(/^\/api\/v3/) }
  end

  describe '#root' do
    subject { helper.root }

    it_behaves_like 'api v3 path'
  end

  describe '#activity' do
    subject { helper.activity 1 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/activities\/1/) }
  end

  describe '#attachment' do
    subject { helper.attachment 1 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/attachments\/1/) }
  end

  describe '#available_assignees' do
    subject { helper.available_assignees 42 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/projects\/42\/available_assignees/) }
  end

  describe '#available_responsibles' do
    subject { helper.available_responsibles 42 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/projects\/42\/available_responsibles/) }
  end

  describe '#available_watchers' do
    subject { helper.available_watchers 42 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/work_packages\/42\/available_watchers/) }
  end

  describe '#categories' do
    subject { helper.categories 42 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/projects\/42\/categories/) }
  end

  describe '#preview_textile' do
    subject { helper.preview_textile '/api/v3/work_packages/42' }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/render\/textile/) }

    it { is_expected.to match(/\?\/api\/v3\/work_packages\/42$/) }
  end

  describe '#priorities' do
    subject { helper.priorities }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/priorities/) }
  end

  describe 'projects paths' do
    describe '#projects' do
      subject { helper.projects }

      it_behaves_like 'api v3 path'

      it { is_expected.to match(/^\/api\/v3\/projects/) }
    end

    describe '#project' do
      subject { helper.project 1 }

      it_behaves_like 'api v3 path'

      it { is_expected.to match(/^\/api\/v3\/projects\/1/) }
    end
  end

  describe '#query' do
    subject { helper.query 1 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/queries\/1/) }
  end

  describe 'relations paths' do
    describe '#relation' do
      subject { helper.relation 1 }

      it_behaves_like 'api v3 path'

      it { is_expected.to match(/^\/api\/v3\/relations/) }
    end

    describe '#relation' do
      subject { helper.relation 1 }

      it_behaves_like 'api v3 path'

      it { is_expected.to match(/^\/api\/v3\/relations\/1/) }
    end
  end

  describe 'statuses paths' do
    describe '#statuses' do
      subject { helper.statuses }

      it_behaves_like 'api v3 path'

      it { is_expected.to match(/^\/api\/v3\/statuses/) }
    end

    describe '#status' do
      subject { helper.status 1 }

      it_behaves_like 'api v3 path'

      it { is_expected.to match(/^\/api\/v3\/statuses\/1/) }
    end
  end

  describe '#user' do
    subject { helper.user 1 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/users\/1/) }
  end

  describe '#versions' do
    subject { helper.versions 42 }

    it_behaves_like 'api v3 path'

    it { is_expected.to match(/^\/api\/v3\/projects\/42\/versions/) }
  end

  describe 'work packages paths' do
    shared_examples_for 'api v3 work packages path' do
      it { is_expected.to match(/^\/api\/v3\/work_packages/) }
    end

    describe '#work_packages' do
      subject { helper.work_packages }

      it_behaves_like 'api v3 work packages path'
    end

    describe '#work_package' do
      subject { helper.work_package 1 }

      it_behaves_like 'api v3 work packages path'

      it { is_expected.to match(/^\/api\/v3\/work_packages\/1/) }
    end

    describe '#work_package_activities' do
      subject { helper.work_package_activities 42 }

      it_behaves_like 'api v3 work packages path'

      it { is_expected.to match(/^\/api\/v3\/work_packages\/42\/activities/) }
    end

    describe '#work_package_relations' do
      subject { helper.work_package_relations 42 }

      it_behaves_like 'api v3 work packages path'

      it { is_expected.to match(/^\/api\/v3\/work_packages\/42\/relations/) }
    end

    describe '#work_package_relation' do
      subject { helper.work_package_relation 1, 42 }

      it_behaves_like 'api v3 work packages path'

      it { is_expected.to match(/^\/api\/v3\/work_packages\/42\/relations\/1/) }
    end

    describe '#work_package_form' do
      subject { helper.work_package_form 1 }

      it_behaves_like 'api v3 work packages path'

      it { is_expected.to match(/^\/api\/v3\/work_packages\/1\/form/) }
    end

    describe '#work_package_watchers' do
      subject { helper.work_package_watchers 1 }

      it_behaves_like 'api v3 work packages path'

      it { is_expected.to match(/^\/api\/v3\/work_packages\/1\/watchers/) }
    end

    describe '#watcher' do
      subject { helper.watcher 1, 42 }

      it_behaves_like 'api v3 work packages path'

      it { is_expected.to match(/^\/api\/v3\/work_packages\/42\/watchers\/1/) }
    end
  end
end
