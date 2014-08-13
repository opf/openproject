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

describe AttachmentsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role,
                                  permissions: [:edit_work_packages,
                                                :view_work_packages,
                                                :delete_wiki_pages_attachments]) }
  let!(:member) { FactoryGirl.create(:member,
                                     project: project,
                                     principal: user,
                                     roles: [role]) }

  before { allow(User).to receive(:current).and_return user }

  describe :destroy do
    let(:attachment) { FactoryGirl.create(:attachment,
                                          container: container) }

    shared_examples_for :deleted do
      subject { Attachment.find_by_id(attachment.id) }

      it { is_expected.to be_nil }
    end

    shared_examples_for :redirected do
      subject { response }

      it { is_expected.to be_redirect }

      it { is_expected.to redirect_to(redirect_path) }
    end

    context :work_package do
      let(:container) { FactoryGirl.create(:work_package,
                                           author: user,
                                           project: project) }
      let(:redirect_path) { work_package_path(container) }

      before { delete :destroy, id: attachment.id }

      it_behaves_like :deleted

      it_behaves_like :redirected
    end

    context :wiki do
      let(:container) { FactoryGirl.create(:wiki_page,
                                           wiki: project.wiki) }
      let(:redirect_path) { project_wiki_path(project, project.wiki) }

      before do
        project.reload # get wiki

        delete :destroy, id: attachment.id
      end

      it_behaves_like :deleted

      it_behaves_like :redirected
    end
  end
end
