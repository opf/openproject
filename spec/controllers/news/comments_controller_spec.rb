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

describe News::CommentsController, type: :controller do
  render_views

  let(:user) { FactoryBot.create(:admin)   }
  let(:news) { FactoryBot.create(:news)    }

  before do
    allow(User).to receive(:current).and_return user
  end

  describe '#create' do
    it 'assigns a comment to the news item and redirects to the news page' do
      post :create, params: { news_id: news.id, comment: { comments: 'This is a test comment' } }

      expect(response).to redirect_to news_path(news)

      latest_comment = news.comments.reorder(Arel.sql('created_on DESC')).first
      expect(latest_comment).not_to be_nil
      expect(latest_comment.comments).to eq 'This is a test comment'
      expect(latest_comment.author).to eq user
    end

    it "doesn't create a comment when it is invalid" do
      expect {
        post :create, params: { news_id: news.id, comment: { comments: '' } }
        expect(response).to redirect_to news_path(news)
      }.not_to change { Comment.count }
    end
  end

  describe '#destroy' do
    it 'deletes the comment and redirects to the news page' do
      comment = FactoryBot.create :comment, commented: news

      expect {
        delete :destroy, params: { id: comment.id }
      }.to change { Comment.count }.by -1

      expect(response).to redirect_to news_path(news)
      expect { comment.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
