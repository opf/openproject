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
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting,
               "mentions" do
  include_context "expected markdown modules"

  describe ".format_text" do
    shared_let(:project) { create(:valid_project) }
    let(:identifier) { project.identifier }
    let(:options) { { project: } }

    shared_let(:role) do
      create(:project_role,
             permissions: %i(view_work_packages edit_work_packages
                             browse_repository view_changesets view_wiki_pages))
    end

    shared_let(:project_member) do
      create(:user,
             member_with_roles: { project => role })
    end

    before do
      login_as(project_member)
    end

    context "User links" do
      let(:role) do
        create(:project_role,
               permissions: %i[view_work_packages edit_work_packages
                               browse_repository view_changesets view_wiki_pages])
      end

      let(:linked_project_member) do
        create(:user,
               member_with_roles: { project => role })
      end

      context "User link via mention" do
        context "existing user" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                <mention class="mention"
                         data-id="#{linked_project_member.id}"
                         data-type="user"
                         data-text="@#{linked_project_member.name}">
                   @#{linked_project_member.name}
                </mention>
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  #{link_to(linked_project_member.name,
                            { controller: :users, action: :show, id: linked_project_member.id },
                            title: "User #{linked_project_member.name}",
                            class: 'user-mention op-uc-link',
                            target: '_top')}
                </p>
              EXPECTED
            end
          end
        end

        context "inexistent user" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                <mention class="mention"
                         data-id="#{linked_project_member.id + 5}"
                         data-type="user"
                         data-text="@Some non existing user">
                   @Some none existing user
                </mention>
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  @Some none existing user
                </p>
              EXPECTED
            end
          end
        end
      end

      context "User link via ID" do
        context "when linked user visible for reader" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                user##{linked_project_member.id}
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  #{link_to(linked_project_member.name,
                            { controller: :users, action: :show, id: linked_project_member.id },
                            title: "User #{linked_project_member.name}",
                            class: 'user-mention op-uc-link',
                            target: '_top')}
                </p>
              EXPECTED
            end
          end
        end

        context "when linked user not visible for reader" do
          let(:role) { create(:non_member) }

          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                user##{linked_project_member.id}
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  #{link_to(linked_project_member.name,
                            { controller: :users, action: :show, id: linked_project_member.id },
                            title: "User #{linked_project_member.name}",
                            class: 'user-mention op-uc-link',
                            target: '_top')}
                </p>
              EXPECTED
            end
          end
        end
      end

      context "User link via login name" do
        context "when linked user visible for reader" do
          context "with a common login name" do
            it_behaves_like "format_text produces" do
              let(:raw) do
                <<~RAW
                  user:"#{linked_project_member.login}"
                RAW
              end

              let(:expected) do
                <<~EXPECTED
                  <p class="op-uc-p">
                    #{link_to(linked_project_member.name,
                              { controller: :users, action: :show, id: linked_project_member.id },
                              title: "User #{linked_project_member.name}",
                              class: 'user-mention op-uc-link',
                              target: '_top')}
                  </p>
                EXPECTED
              end
            end
          end

          context "with an email address as login name" do
            let(:linked_project_member) do
              create(:user,
                     member_with_roles: { project => role },
                     login: "foo@bar.com")
            end

            it_behaves_like "format_text produces" do
              let(:raw) do
                <<~RAW
                  user:"#{linked_project_member.login}"
                RAW
              end

              let(:expected) do
                <<~EXPECTED
                  <p class="op-uc-p">
                    #{link_to(linked_project_member.name,
                              { controller: :users, action: :show, id: linked_project_member.id },
                              title: "User #{linked_project_member.name}",
                              class: 'user-mention op-uc-link',
                              target: '_top')}
                  </p>
                EXPECTED
              end
            end
          end
        end

        context "when linked user not visible for reader" do
          let(:role) { create(:non_member) }

          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                user:"#{linked_project_member.login}"
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  #{link_to(linked_project_member.name,
                            { controller: :users, action: :show, id: linked_project_member.id },
                            title: "User #{linked_project_member.name}",
                            class: 'user-mention op-uc-link',
                            target: '_top')}
                </p>
              EXPECTED
            end
          end
        end
      end

      context "User link via mail" do
        context "for user references not existing" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                Link to user:"foo@bar.com"
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  Link to user:"<a class="op-uc-link" rel="noopener noreferrer" target="_top" href="mailto:foo@bar.com">foo@bar.com</a>"
                </p>
              EXPECTED
            end
          end
        end

        context "when visible user exists" do
          let(:project) { create(:project) }
          let(:role) { create(:project_role, permissions: %i(view_work_packages)) }
          let(:current_user) do
            create(:user,
                   member_with_roles: { project => role })
          end
          let(:user) do
            create(:user,
                   login: "foo@bar.com",
                   firstname: "Foo",
                   lastname: "Barrit",
                   member_with_roles: { project => role })
          end

          before do
            user
            login_as current_user
          end

          context "with only_path true (default)" do
            it_behaves_like "format_text produces" do
              let(:raw) do
                <<~RAW
                  Link to user:"foo@bar.com"
                RAW
              end

              let(:expected) do
                <<~EXPECTED
                  <p class="op-uc-p">
                    Link to <a class="user-mention op-uc-link" target="_top" href="/users/#{user.id}" title="User Foo Barrit">Foo Barrit</a>
                  </p>
                EXPECTED
              end
            end
          end

          context "with only_path false (default)", with_settings: { host_name: "openproject.org" } do
            let(:options) { { only_path: false } }

            it_behaves_like "format_text produces" do
              let(:raw) do
                <<~RAW
                  Link to user:"foo@bar.com"
                RAW
              end

              let(:expected) do
                <<~EXPECTED
                  <p class="op-uc-p">
                    Link to <a class="user-mention op-uc-link" target="_top" href="http://openproject.org/users/#{user.id}" title="User Foo Barrit">Foo Barrit</a>
                  </p>
                EXPECTED
              end
            end
          end
        end
      end
    end

    context "Group reference" do
      let(:role) do
        create(:project_role,
               permissions: [])
      end

      let(:linked_project_member_group) do
        create(:group, member_with_roles: { project => role })
      end

      context "via hash syntax" do
        context "group exists" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                Link to group##{linked_project_member_group.id}
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  Link to
                  <a class="user-mention op-uc-link"
                     target="_top"
                     href="/groups/#{linked_project_member_group.id}"
                     title="Group #{linked_project_member_group.name}">
                    #{linked_project_member_group.name}
                  </a>
                </p>
              EXPECTED
            end
          end
        end

        context "group does not exist" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                Link to group#000000
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  Link to group#000000
                </p>
              EXPECTED
            end
          end
        end
      end

      context "via mention" do
        context "existing group" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                <mention class="mention"
                         data-id="#{linked_project_member_group.id}"
                         data-type="group"
                         data-text="@#{linked_project_member_group.name}">@#{linked_project_member_group.name}</mention>
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  <a class="user-mention op-uc-link"
                     target="_top"
                     href="/groups/#{linked_project_member_group.id}"
                     title="Group #{linked_project_member_group.name}">
                    #{linked_project_member_group.name}
                  </a>
                </p>
              EXPECTED
            end
          end
        end

        context "inexistent group" do
          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                <mention class="mention"
                         data-id="0"
                         data-type="group"
                         data-text="@Some none existing group">
                  @Some none existing group
                </mention>
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  @Some none existing group
                </p>
              EXPECTED
            end
          end
        end
      end
    end
  end
end
