#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

require File.expand_path('../../spec_helper', __FILE__)

describe OpenProject::GithubIntegration do
  before do
    allow(Setting).to receive(:host_name).and_return('example.net')
  end

  describe 'with sane set-up' do
    let(:user) { FactoryGirl.create(:user) }
    let(:role) { FactoryGirl.create(:role,
                                    permissions: [:view_work_packages, :add_work_package_notes]) }
    let(:statuses) { (1..5).map{ |i| FactoryGirl.create(:status)}}
    let(:priority) { FactoryGirl.create :priority, is_default: true }
    let(:status) { statuses[0] }
    let(:project) do
      FactoryGirl.create(:project).tap do |p|
        p.add_member(user, role).save
      end
    end
    let(:project_without_permission) { FactoryGirl.create(:project) }
    let(:wp1) do
      FactoryGirl.create :work_package, project: project
    end
    let(:wp2) do
      FactoryGirl.create :work_package, project: project
    end
    let(:wp3) do
      FactoryGirl.create :work_package,
                             project: project_without_permission
    end
    let(:wp4) do
      FactoryGirl.create :work_package,
                             project: project_without_permission
    end
    let(:wps) { [wp1, wp2, wp3, wp4] }

    it "should handle the pull_request creation payload" do
      params = ActionController::Parameters.new(
        payload: {
          'action' => 'opened',
          'number' => '5',
          'pull_request' => {
            'title' => 'Bugfixes',
            'body' => "Fixes http://example.net/wp/#{wp1.id} and " +
                      "https://example.net/work_packages/#{wp2.id} and " +
                      "http://example.net/subdir/wp/#{wp3.id} and " +
                      "https://example.net/subdir/work_packages/#{wp4.id}.",
            'html_url' => 'http://pull.request',
            'base' => {
              'repo' => {
                'full_name' => 'full/name',
                'html_url' => 'http://pull.request'
              }
            }
          },
          'sender' => {
            'login' => 'github_login',
            'html_url' => 'http://user.name'
          },
          'repository' => {}
        }
      )

      environment = {
        'HTTP_X_GITHUB_EVENT' => 'pull_request',
        'HTTP_X_GITHUB_DELIVERY' => 'test delivery'
      }

      journal_count = wps.map { |wp| wp.journals.count }
      OpenProject::GithubIntegration::HookHandler.new.process('github', OpenStruct.new(env: environment), params, user)

      [wp1,wp2,wp3,wp4].map { |x| x.reload }

      expect(wp1.journals.count).to equal(journal_count[0] + 1)
      expect(wp2.journals.count).to equal(journal_count[1] + 1)
      expect(wp3.journals.count).to equal(journal_count[2] + 0)
      expect(wp4.journals.count).to equal(journal_count[3] + 0)

      expect(wp1.journals.last.notes).to include('PR Opened')
    end

    it "should handle the pull_request close payload" do
      params = ActionController::Parameters.new(
        payload: {
          'action' => 'closed',
          'number' => '5',
          'pull_request' => {
            'title' => 'Bugfixes',
            'body' => "Fixes http://example.net/wp/#{wp1.id} and " +
                      "https://example.net/work_packages/#{wp2.id} and " +
                      "http://example.net/subdir/wp/#{wp3.id} and " +
                      "https://example.net/subdir/work_packages/#{wp4.id}.",
            'html_url' => 'http://pull.request',
            'base' => {
              'repo' => {
                'full_name' => 'full/name',
                'html_url' => 'http://pull.request'
              }
            }
          },
          'sender' => {
            'login' => 'github_login',
            'html_url' => 'http://user.name'
          },
          'repository' => {}
        }
      )

      environment = {
        'HTTP_X_GITHUB_EVENT' => 'pull_request',
        'HTTP_X_GITHUB_DELIVERY' => 'test delivery'
      }

      journal_count = wps.map { |wp| wp.journals.count }
      OpenProject::GithubIntegration::HookHandler.new.process('github', OpenStruct.new(env: environment), params, user)

      [wp1,wp2,wp3,wp4].map { |x| x.reload }

      expect(wp1.journals.count).to eq(journal_count[0] + 1)
      expect(wp2.journals.count).to eq(journal_count[1] + 1)
      expect(wp3.journals.count).to eq(journal_count[2] + 0)
      expect(wp4.journals.count).to eq(journal_count[3] + 0)

      expect(wp1.journals.last.notes).to include('PR Closed')
    end

    it "should handle the pull_request merged payload" do
      params = ActionController::Parameters.new(
        payload: {
          'action' => 'closed',
          'number' => '5',
          'pull_request' => {
            'title' => 'Bugfixes',
            'body' => "Fixes http://example.net/wp/#{wp1.id} and " +
                      "https://example.net/work_packages/#{wp2.id} and " +
                      "http://example.net/subdir/wp/#{wp3.id} and " +
                      "https://example.net/subdir/work_packages/#{wp4.id}.",
            'html_url' => 'http://pull.request',
            'base' => {
              'repo' => {
                'full_name' => 'full/name',
                'html_url' => 'http://pull.request'
              }
            },
            'merged' => true
          },
          'sender' => {
            'login' => 'github_login',
            'html_url' => 'http://user.name'
          },
          'repository' => {}
        }
      )

      environment = {
        'HTTP_X_GITHUB_EVENT' => 'pull_request',
        'HTTP_X_GITHUB_DELIVERY' => 'test delivery'
      }

      journal_count = wps.map { |wp| wp.journals.count }
      OpenProject::GithubIntegration::HookHandler.new.process('github', OpenStruct.new(env: environment), params, user)

      [wp1,wp2,wp3,wp4].map { |x| x.reload }

      expect(wp1.journals.count).to equal(journal_count[0] + 1)
      expect(wp2.journals.count).to equal(journal_count[1] + 1)
      expect(wp3.journals.count).to equal(journal_count[2] + 0)
      expect(wp4.journals.count).to equal(journal_count[3] + 0)

      expect(wp1.journals.last.notes).to include('PR Merged')
    end

    it "should handle the pull_request comment creation payload" do
      params = ActionController::Parameters.new(
        payload: {
          'action' => 'created',
          'issue' => {
            'title' => 'Bugfixes',
            'number' => '5',
            'pull_request' => {
              'html_url' => 'http://pull.request'
            }
          },
          'comment' => {
            'body' => "Fixes http://example.net/wp/#{wp1.id} and " +
                      "https://example.net/work_packages/#{wp2.id} and " +
                      "http://example.net/subdir/wp/#{wp3.id} and " +
                      "https://example.net/subdir/work_packages/#{wp4.id}.",
            'html_url' => 'http://comment.url',
            'user' => {
              'login' => 'github_login',
              'html_url' => 'http://user.name'
            }
          },
          'sender' => {
          },
          'repository' => {
            'full_name' => 'full/name',
            'html_url' => 'http://pull.request'
          }
        },
        'comment' => {
          'body' => "Fixes http://example.net/wp/#{wp1.id} and " +
                    "https://example.net/work_packages/#{wp2.id} and " +
                    "http://example.net/subdir/wp/#{wp3.id} and " +
                    "https://example.net/subdir/work_packages/#{wp4.id}.",
          'html_url' => 'http://comment.url',
          'user' => {
            'login' => 'github_login',
            'html_url' => 'http://user.name'
          }
        },
        'sender' => {
        },
        'repository' => {
          'full_name' => 'full/name',
          'html_url' => 'http://pull.request'
        }
      )

      environment = {
        'HTTP_X_GITHUB_EVENT' => 'issue_comment',
        'HTTP_X_GITHUB_DELIVERY' => 'test delivery'
      }

      journal_count = wps.map { |wp| wp.journals.count }
      OpenProject::GithubIntegration::HookHandler.new.process('github', OpenStruct.new(env: environment), params, user)

      [wp1,wp2,wp3,wp4].map { |x| x.reload }

      expect(wp1.journals.count).to equal(journal_count[0] + 1)
      expect(wp2.journals.count).to equal(journal_count[1] + 1)
      expect(wp3.journals.count).to equal(journal_count[2] + 0)
      expect(wp4.journals.count).to equal(journal_count[3] + 0)

      expect(wp1.journals.last.notes).to include('Referenced')
    end
  end
end
