#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Principals::ReplaceReferencesService, '#call', type: :model do
  subject(:service_call) { instance.call(from: principal, to: to_principal) }

  shared_let(:other_user) { FactoryBot.create(:user) }
  shared_let(:user) { FactoryBot.create(:user) }
  shared_let(:to_principal) { FactoryBot.create :user }

  let(:instance) do
    described_class.new
  end

  context 'with a user' do
    let(:principal) { user }

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    context 'with a Journal' do
      let!(:journal) do
        FactoryBot.create(:work_package_journal,
                          user_id: user_id,
                          data: instance_double(Journal::WorkPackageJournal,
                                                'journal=': nil,
                                                save: true))
      end

      context 'with the replaced user' do
        let(:user_id) { principal.id }

        before do
          service_call
          journal.reload
        end

        it 'replaces user_id' do
          expect(journal.user_id)
            .to eql to_principal.id
        end
      end

      context 'with a different user' do
        let(:user_id) { other_user.id }

        before do
          service_call
          journal.reload
        end

        it 'replaces user_id' do
          expect(journal.user_id)
            .to eql other_user.id
        end
      end
    end

    shared_examples_for 'rewritten record' do |factory, attribute, format = Integer|
      let!(:model) do
        klass = FactoryBot.factories.find(factory).build_class
        all_attributes = other_attributes.merge(attribute => principal_id)

        inserted = ActiveRecord::Base.connection.select_one <<~SQL
          INSERT INTO #{klass.table_name}
          (#{all_attributes.keys.join(', ')})
          VALUES
          (#{all_attributes.values.join(', ')})
          RETURNING id
        SQL

        klass.find(inserted['id'])
      end

      let(:other_attributes) do
        defined?(attributes) ? attributes : {}
      end

      def expected(user, format)
        if format == String
          user.id.to_s
        else
          user.id
        end
      end

      context "for #{factory}" do
        context 'with the replaced user' do
          let(:principal_id) { principal.id }

          before do
            service_call
            model.reload
          end

          it "replaces #{attribute}" do
            expect(model.send(attribute))
              .to eql expected(to_principal, format)
          end
        end

        context 'with a different user' do
          let(:principal_id) { other_user.id }

          before do
            service_call
            model.reload
          end

          it "keeps #{attribute}" do
            expect(model.send(attribute))
              .to eql expected(other_user, format)
          end
        end
      end
    end

    context 'with Attachment' do
      it_behaves_like 'rewritten record',
                      :attachment,
                      :author_id

      it_behaves_like 'rewritten record',
                      :journal_attachment_journal,
                      :author_id do
        let(:attributes) do
          { journal_id: 1 }
        end
      end
    end

    context 'with Comment' do
      it_behaves_like 'rewritten record',
                      :comment,
                      :author_id
    end

    context 'with CustomValue' do
      it_behaves_like 'rewritten record',
                      :custom_value,
                      :value,
                      String do
        let(:user_cf) { FactoryBot.create(:user_wp_custom_field) }
        let(:attributes) do
          { custom_field_id: user_cf.id }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_customizable_journal,
                      :value,
                      String do
        let(:user_cf) { FactoryBot.create(:user_wp_custom_field) }
        let(:attributes) do
          { journal_id: 1,
            custom_field_id: user_cf.id }
        end
      end
    end

    context 'with Changeset' do
      it_behaves_like 'rewritten record',
                      :changeset,
                      :user_id do
        let(:attributes) do
          { repository_id: 1,
            revision: 1,
            committed_on: "date '2012-02-02'" }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_changeset_journal,
                      :user_id do
        let(:attributes) do
          { journal_id: 1,
            repository_id: 1,
            revision: 1,
            committed_on: "date '2012-02-02'" }
        end
      end
    end

    context 'with Message' do
      it_behaves_like 'rewritten record',
                      :message,
                      :author_id do
        let(:attributes) do
          { forum_id: 1 }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_message_journal,
                      :author_id do
        let(:attributes) do
          { journal_id: 1,
            forum_id: 1 }
        end
      end
    end

    context 'with MeetingContent' do
      it_behaves_like 'rewritten record',
                      :meeting_agenda,
                      :author_id do
        let(:attributes) do
          { type: "'MeetingAgenda'",
            created_at: 'NOW()',
            updated_at: 'NOW()' }
        end
      end

      it_behaves_like 'rewritten record',
                      :meeting_minutes,
                      :author_id do
        let(:attributes) do
          { type: "'MeetingMinutes'",
            created_at: 'NOW()',
            updated_at: 'NOW()' }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_meeting_content_journal,
                      :author_id do
        let(:attributes) do
          { journal_id: 1 }
        end
      end
    end

    context 'with MeetingParticipant' do
      it_behaves_like 'rewritten record',
                      :meeting_participant,
                      :user_id do
        let(:attributes) do
          { created_at: 'NOW()',
            updated_at: 'NOW()' }
        end
      end
    end

    context 'with News' do
      it_behaves_like 'rewritten record',
                      :news,
                      :author_id

      it_behaves_like 'rewritten record',
                      :journal_news_journal,
                      :author_id do
        let(:attributes) do
          { journal_id: 1 }
        end
      end
    end

    context 'with WikiContent' do
      it_behaves_like 'rewritten record',
                      :wiki_content,
                      :author_id do
        let(:attributes) do
          { page_id: 1,
            lock_version: 5 }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_wiki_content_journal,
                      :author_id do
        let(:attributes) do
          { journal_id: 1,
            page_id: 1 }
        end
      end
    end

    context 'with WorkPackage' do
      it_behaves_like 'rewritten record',
                      :work_package,
                      :assigned_to_id

      it_behaves_like 'rewritten record',
                      :work_package,
                      :responsible_id

      it_behaves_like 'rewritten record',
                      :journal_work_package_journal,
                      :assigned_to_id do
        let(:attributes) do
          { journal_id: 1 }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_work_package_journal,
                      :responsible_id do
        let(:attributes) do
          { journal_id: 1 }
        end
      end
    end

    context 'with TimeEntry' do
      it_behaves_like 'rewritten record',
                      :time_entry,
                      :user_id do
        let(:attributes) do
          { project_id: 1,
            hours: 5,
            activity_id: 1,
            spent_on: "date '2012-02-02'",
            tyear: 2021,
            tmonth: 12,
            tweek: 5 }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_time_entry_journal,
                      :user_id do
        let(:attributes) do
          { journal_id: 1,
            project_id: 1,
            hours: 5,
            activity_id: 1,
            spent_on: "date '2012-02-02'",
            tyear: 2021,
            tmonth: 12,
            tweek: 5 }
        end
      end
    end

    context 'with Budget' do
      it_behaves_like 'rewritten record',
                      :budget,
                      :author_id do
        let(:attributes) do
          { project_id: 1,
            subject: "'abc'",
            description: "'cde'",
            fixed_date: "date '2012-02-02'" }
        end
      end

      it_behaves_like 'rewritten record',
                      :journal_budget_journal,
                      :author_id do
        let(:attributes) do
          { journal_id: 1,
            project_id: 1,
            subject: "'abc'",
            fixed_date: "date '2012-02-02'" }
        end
      end
    end

    context 'with Query' do
      it_behaves_like 'rewritten record',
                      :query,
                      :user_id
    end

    context 'with CostQuery' do
      let(:query) { FactoryBot.create(:cost_query, user: principal) }

      it_behaves_like 'rewritten record',
                      :cost_query,
                      :user_id do
        let(:attributes) do
          { name: "'abc'",
            serialized: "'cde'" }
        end
      end

    end
  end
end
