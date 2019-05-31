##
# Extracts sections of a BCF markup file
# manually. If we want to extract the entire markup,
# this should be turned into a representable/xml decorator
require_relative 'file_entry'

module OpenProject::Bcf::BcfXml
  class IssueReader
    attr_reader :zip, :entry, :issue, :extractor, :project, :user, :type

    def initialize(project, zip, entry, current_user:)
      @zip = zip
      @entry = entry
      @project = project
      @user = current_user
      @issue = find_or_initialize_issue
      @extractor = MarkupExtractor.new(entry)

      # TODO fixed type
      @type = ::Type.find_by(name: 'Issue [BCF]')
    end

    def extract!
      issue.markup = extractor.markup

      # Viewpoints will be extended on import
      build_viewpoints

      # Synchronize with a work package
      synchronize_with_work_package

      # Comments will be extended on import
      build_comments

      issue
    end

    private

    def synchronize_with_work_package
      is_update = issue.work_package.present?
      call =
        if is_update
          update_work_package
        else
          create_work_package
        end

      if call.success?
        issue.work_package = call.result
        create_comment(user, I18n.t('bcf.bcf_xml.import_update_comment')) if is_update
      else
        Rails.logger.error "Failed to synchronize BCF #{issue.uuid} with work package: #{call.errors.full_messages.join('; ')}"
      end
    end

    def import_is_newer?
      extractor.modified_date && extractor.modified_date > issue.work_package.updated_at
    end

    def create_work_package
      wp = WorkPackage.new work_package_attributes

      call = CreateWorkPackageService
        .new(user: user)
        .call(wp, send_notifications: false)

      if call.success?
        force_overwrite(wp)
      end

      call
    end

    def author
      find_user_in_project(extractor.author) || User.system
    end

    def assignee
      find_user_in_project(extractor.assignee)
    end

    def update_work_package
      if import_is_newer?
        WorkPackages::UpdateService
          .new(user: user, model: issue.work_package)
          .call(work_package_attributes.merge(send_notifications: false).symbolize_keys)
      else
        import_is_outdated(issue)
      end
    end

    ##
    # Get mapped and raw attributes from MarkupExtractor
    # and return all values that are non-nil
    def work_package_attributes
      {
        # Fixed attributes we know
        project: project,
        type: type,

        # Native attributes from the extractor
        subject: extractor.title,
        description: extractor.description,
        due_date: extractor.due_date,

        # Mapped attributes
        assigned_to: assignee,
        status_id: statuses.fetch(extractor.status, statuses[:default]),
        priority_id: priorities.fetch(extractor.priority, priorities[:default])
      }.compact
    end

    ##
    # Extend comments with new or updated values from XML
    def build_comments
      extractor.comments.each do |data|
        next if issue.comments.has_uuid?(data[:uuid]) # Comment has already been imported once.

        comment = issue.comments.build data.slice(:uuid)

        # Cannot link to a journal when no work package
        next if issue.work_package.nil?

        author = get_comment_author(data)

        call = create_comment(author, data[:comment])

        if call.success?
          comment.journal = call.result
        else
          Rails.logger.error "Failed to create comment for BCF #{issue.uuid}: #{call.errors.full_messages.join('; ')}"
        end
      end
    end

    ##
    # Try to find an author with the given mail address
    def get_comment_author(comment)
      author = find_user_in_project(comment[:author])

      # If none found, use the current user
      return user if author.nil?

      # If found, check if the author can comment
      return user unless author.allowed_to?(:add_work_package_notes, project)

      author
    end

    ##
    # The uploading user might not be the author of the topic/work package. Further, we need to correct the
    # automatically set craetion timestamps.
    def force_overwrite(work_package)
      created_at = extractor.creation_date
      if created_at || user != author
        force_overwrite_work_package(created_at, work_package)
        force_overwrite_first_journal(created_at, work_package)
      end
    end

    def force_overwrite_first_journal(created_at, work_package)
      journal = work_package.journals.first
      journal.update_columns(created_at: created_at,
                             user_id: author.id)

      wp_journal = ::WorkPackageJournal.find_by(journal_id: journal.id)
      wp_journal.update_columns author_id: author.id
    end

    def force_overwrite_work_package(created_at, work_package)
      work_package.update_columns(created_at: created_at,
                                  author_id: author.id)
    end

    ##
    # Try to find the given user by mail in the project
    def find_user_in_project(mail)
      project.users.find_by(mail: mail)
    end

    def create_comment(author, content)
      ::AddWorkPackageNoteService
        .new(user: author, work_package: issue.work_package)
        .call(content)
    end

    ##
    # Extract viewpoints from XML
    def build_viewpoints
      extractor.viewpoints.each do |vp|
        next if issue.viewpoints.has_uuid?(vp[:uuid])

        issue.viewpoints.build(
          issue: issue,
          uuid: vp[:uuid],

          # Save the viewpoint as XML
          viewpoint: read_entry(vp[:viewpoint]),
          viewpoint_name: vp[:viewpoint],

          # Save the snapshot as file attachment
          snapshot: as_file_entry(vp[:snapshot])
        )
      end
    end

    ##
    # Find existing issue or create new
    def find_or_initialize_issue
      ::Bcf::Issue.find_or_initialize_by(uuid: topic_uuid, project_id: project.id)
    end

    ##
    # Get the topic name of an entry
    def topic_uuid
      entry.name.split('/').first
    end

    ##
    # Get an entry within the uuid
    def as_file_entry(filename)
      entry = zip.find_entry [topic_uuid, filename].join('/')

      if entry
        FileEntry.new(entry.get_input_stream, filename: filename)
      end
    end

    ##
    # Read an entry as string
    def read_entry(filename)
      entry = zip.find_entry [topic_uuid, filename].join('/')
      entry.get_input_stream.read
    end

    ##
    # Keep a hash map of current status ids for faster lookup
    def statuses
      @statuses ||= Hash[Status.pluck(:name, :id)].merge(default: Status.default.id)
    end

    ##
    # Keep a hash map of current status ids for faster lookup
    def priorities
      @priorities ||= Hash[IssuePriority.pluck(:name, :id)].merge(default: IssuePriority.default.try(:id))
    end

    def import_is_outdated(issue)
      issue.errors.add :base,
                       :conflict,
                       message: I18n.t('bcf.bcf_xml.import.work_package_has_newer_changes',
                                       bcf_uuid: issue.uuid)
      ServiceResult.new success: false,
                        errors: issue.errors,
                        result: issue
    end
  end
end
