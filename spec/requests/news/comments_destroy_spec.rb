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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "News comments destroy redirect",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[news]) }
  shared_let(:news) { create(:news, project:) }
  shared_let(:comment) { create(:comment, commented: news) }

  context "when an admin deletes a news comment" do
    current_user { create(:admin) }

    let(:request) { delete "/projects/#{project.identifier}/news/#{news.id}/comments/#{comment.id}" }

    subject do
      request
      response
    end

    it "responds with 303 See Other and redirects to the news page" do
      expect(subject).to have_http_status(:see_other)
      expect(response).to redirect_to(project_news_path(project, news))

      expect { Comment.find(comment.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { News.find(news.id) }.not_to raise_error
    end
  end
end
