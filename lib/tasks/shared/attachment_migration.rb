module Tasks
  module Shared
    module AttachmentMigration
      module_function

      def move_obsolete_attachments_to_wiki!
        reset_journal_id_sequence!

        move_project_attachments_to_wiki!
        move_version_attachments_to_wiki!
      end

      ##
      # Why do we do this? Consider the migrations process:
      #
      # ... (other migrations)
      # |A| delete version and project attachments
      # |B| move these attachments to new wiki pages to prevent data loss (new)
      # ... (other migrations)
      # |C| migrate legacy journals to new format
      #
      # We are at 'B'. Creating new wiki pages and also updating attachment entries
      # creates journal entries (starting with ID 1).
      # Step 'C' assumes there are no journals yet which would normally be the case.
      # Due to the newly introduced step B there are some already, though.
      # The journal migrations wants to use the same IDs as in the original journals.
      # These may now be taken by the new attachment journals.
      #
      # To prevent this we skip all possible IDs of the legacy journals so the
      # journals created during the attachment business don't conflict with
      # the legacy journals.
      def reset_journal_id_sequence!
        con = ActiveRecord::Base.connection

        if OpenProject::Database.mysql?
          max_id = con.execute("SELECT MAX(id) FROM legacy_journals").to_a.first.first

          con.execute "ALTER TABLE journals AUTO_INCREMENT = #{max_id + 1}"
        else # Postgres
          max_id = con.execute("SELECT MAX(id) FROM legacy_journals").to_a.first["max"]

          con.execute "ALTER SEQUENCE journals_id_seq RESTART WITH #{max_id + 1}"
        end
      end

      def move_project_attachments_to_wiki!
        projects = affected_containers(Project).to_a

        projects.each_with_index do |project, i|
          enable_wiki! project

          page = create_project_attachments_page! project
          attachments = Attachment.where(container_type: "Project", container_id: project.id)

          puts "Moving #{attachments.size} Version attachments to wiki page \"#{page.title}\" [#{i + 1}/#{projects.size}]"

          attachments.each do |attachment|
            attachment.update! container_type: "WikiPage", container_id: page.id
          end
        end
      end

      def move_version_attachments_to_wiki!
        versions = affected_containers(Version).to_a

        versions.each_with_index do |version, i|
          enable_wiki! version.project

          page = create_version_attachments_page! version
          attachments = Attachment.where(container_type: "Version", container_id: version.id)

          puts "Moving #{attachments.size} Version attachments to wiki page '#{page.title}' [#{i + 1}/#{versions.size}]"

          attachments.each do |attachment|
            attachment.update! container_type: "WikiPage", container_id: page.id
          end
        end
      end

      def affected_containers(model)
        Attachment
          .where(container_type: model.name)
          .group(:container_id)
          .pluck(:container_id)
          .map { |id| model.find_by(id: id) }
      end

      def enable_wiki!(project)
        unless project.module_enabled? "wiki"
          project.enabled_modules.create name: "wiki"

          if project.wiki.nil?
            Wiki.create! project: project, start_page: "Wiki", status: 1
            project.reload
          end
        end
      end

      def create_project_attachments_page!(project, name: "Project Attachments")
        page = attachments_page! project.wiki, name: name

        if page.content.nil?
          text = I18n.t(
            :notice_attachment_migration_wiki_page,
            container_type: "Project",
            container_name: project.name
          )

          Migrations::Attachments::CurrentWikiContent.create!(
            page_id: page.id, author_id: User.system.id, text: text
          )
        end

        page
      end

      def create_version_attachments_page!(version, name: "Version '#{version.name}' Attachments")
        page = attachments_page! version.project.wiki, name: name

        if page.content.nil?
          text = I18n.t(
            :notice_attachment_migration_wiki_page,
            container_type: "Version",
            container_name: version.name
          )

          Migrations::Attachments::CurrentWikiContent.create!(
            page_id: page.id, author_id: User.system.id, text: text
          )
        end

        page
      end

      def attachments_page!(wiki, name:)
        page = wiki.pages.where(title: name).first

        if page
          page
        else
          Migrations::Attachments::CurrentWikiPage.create wiki_id: wiki.id, title: name
        end
      end

      def try_delete_attachments_from_projects_and_versions
        if !$stdout.isatty || user_agrees_to_delete_versions_and_projects_documents
          puts 'Delete all attachments attached to projects or versions...'

          Attachment.where(container_type: ['Version', 'Project']).destroy_all
        end
      rescue
        raise 'Cannot delete attachments from projects and versions! There may be migrations missing...?'
      end

      def user_agrees_to_delete_versions_and_projects_documents
        questions = ['CAUTION: This rake task will delete ALL attachments attached to versions or projects!',
                    "DISCLAIMER: This is the final warning: You're going to lose information!"]

        ask_for_confirmation(questions)
      end
    end
  end
end
