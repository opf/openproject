##
# Extracts sections of a BCF markup file
# manually. If we want to extract the entire markup,
# this should be turned into a representable/xml decorator
require_relative 'file_entry'

module OpenProject::Bim::BcfXml
  class IssueReader
    attr_reader :zip, :entry, :issue, :extractor, :project, :user, :import_options
    attr_accessor :wp_last_updated_at, :is_update

    def initialize(project, zip, entry, current_user:, import_options:)
      @zip = zip
      @entry = entry
      @project = project
      @user = current_user
      @issue = find_or_initialize_issue
      @extractor = MarkupExtractor.new(entry)
      @import_options = import_options
      @wp_last_updated_at = nil
      @is_update = false
    end

    def extract!
      markup = extractor.doc.to_xml(indent: 2)

      issue.markup = markup
      extractor.markup = markup

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
      # If there are already errors during the BCF issue creation, don't create or update the WP.
      return if issue.errors.any?

      self.is_update = issue.work_package.present?
      self.wp_last_updated_at = issue.work_package&.updated_at

      call =
        if is_update
          update_work_package
        else
          create_work_package
        end

      if call.success?
        issue.work_package = call.result
        create_wp_comment(user, I18n.t('bcf.bcf_xml.import_update_comment')) if is_update
      else
        issue.errors.merge!(call.errors)
        Rails.logger.error "Failed to synchronize BCF #{issue.uuid} with work package: #{call.errors.full_messages.join('; ')}"
      end
    end

    def import_is_newer?
      extractor.modified_date && extractor.modified_date > wp_last_updated_at
    end

    def create_work_package
      attributes = work_package_attributes.merge(project: project)
      call = WorkPackages::CreateService.new(user: user).call(attributes)

      force_overwrite(call.result) if call.success?

      call
    end

    def author
      find_user_in_project(extractor.author) || User.system
    end

    def update_work_package
      if import_is_newer?
        WorkPackages::UpdateService
          .new(user: user, model: issue.work_package)
          .call(work_package_attributes)
      else
        import_is_outdated(issue)
      end
    end

    ###
    ## Get mapped and raw attributes from MarkupExtractor
    ## and return all values that are non-nil
    def work_package_attributes
      attributes = ::Bim::Bcf::Issues::TransformAttributesService
                   .new(project)
                   .call(extractor_attributes.merge(import_options: import_options))
                   .result
                   .merge(send_notifications: false)
                   .symbolize_keys

      attributes[:start_date] = extractor.creation_date.to_date unless is_update

      attributes
    end

    def extractor_attributes
      %i(type title description due_date assignee status priority).map do |key|
        [key, extractor.send(key)]
      end.to_h
    end

    ##
    # Extend comments with new or updated values from XML
    def build_comments
      extractor.comments.each do |comment_data|
        if issue.comments.has_uuid?(comment_data[:uuid], issue.id)
          # Comment has already been imported once.
          update_comment(comment_data)
        else
          # Cannot link to a journal when no work package
          next if issue.work_package.nil?

          new_comment(comment_data)
        end
      end
    end

    ##
    # Try to find an author with the given mail address
    def get_comment_author(comment)
      author = find_user_in_project(comment[:author])

      # If none found, use the current user
      return User.system if author.nil?

      # If found, check if the author can comment
      return User.system unless author.allowed_to?(:add_work_package_notes, project)

      author
    end

    ##
    # The uploading user might not be the author of the topic/work package. Further, we need to correct the
    # automatically set creation timestamps.
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

      wp_journal = ::Journal::WorkPackageJournal.find_by(journal_id: journal.id)
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

    def create_wp_comment(author, content)
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

          # Save the viewpoint as json
          json_viewpoint: viewpoint_as_json(vp[:uuid], read_entry(vp[:viewpoint])),
          viewpoint_name: vp[:viewpoint],

          # Save the snapshot as file attachment
          snapshot: as_file_entry(vp[:snapshot])
        )
      end
    end

    ##
    # Find existing issue or create new
    def find_or_initialize_issue
      bcf_issue = ::Bim::Bcf::Issue.eager_load(:work_package).find_by(uuid: topic_uuid)

      if bcf_issue.nil?
        return initialize_issue
      end

      if bcf_issue.work_package && bcf_issue.work_package.project_id != project.id
        bcf_issue = initialize_issue
        bcf_issue.errors.add :uuid, :uuid_already_taken
      end

      bcf_issue
    end

    def initialize_issue
      ::Bim::Bcf::Issue.new(uuid: topic_uuid)
    end

    ##
    # Get the topic name of an entry
    def topic_uuid
      entry.name.split('/').first
    end

    ##
    # Get an entry within the uuid
    def as_file_entry(filename)
      file_entry = zip.find_entry [topic_uuid, filename].join('/')

      if file_entry
        FileEntry.new(file_entry.get_input_stream, filename: filename)
      end
    end

    ##
    # Read an entry as string
    def read_entry(filename)
      file_entry = zip.find_entry [topic_uuid, filename].join('/')
      file_entry.get_input_stream.read
    end

    ##
    # Map the xml viewpoint as json
    def viewpoint_as_json(uuid, xml)
      ::OpenProject::Bim::BcfJson::ViewpointReader
        .new(uuid, xml)
        .result
    end

    def new_comment(comment_data)
      bcf_comment = issue.comments.build(uuid: comment_data[:uuid], viewpoint: viewpoint_by_uuid(comment_data[:viewpoint_uuid]))

      call = create_wp_comment_privileged(comment_data)

      new_comment_handler(bcf_comment, call, comment_data[:date])
    end

    def viewpoint_by_uuid(uuid)
      return nil if uuid.nil?

      issue.viewpoints.find { |vp| vp.uuid == uuid }
    end

    def create_wp_comment_privileged(comment_data)
      author = get_comment_author(comment_data)
      if author.id == User.system.id
        User.system.run_given do
          create_wp_comment(User.current, comment_data[:comment])
        end
      else
        create_wp_comment(author, comment_data[:comment])
      end
    end

    def new_comment_handler(bcf_comment, call, created_at)
      if call.success?
        call.result.update_columns(created_at: created_at)
        bcf_comment.journal = call.result
      else
        Rails.logger.error "Failed to create comment for BCF #{issue.uuid}: #{call.errors.full_messages.join('; ')}"
      end
    end

    def update_comment(comment_data)
      if comment_data[:modified_date]
        bcf_comment = issue.comments.find_by(comment_data.slice(:uuid))
        update_comment_viewpoint_by_uuid(bcf_comment, comment_data[:viewpoint_uuid])

        if bcf_comment.journal.created_at < comment_data[:modified_date]
          update_journal_attributes(bcf_comment, comment_data)
        end
      end
    end

    def update_comment_viewpoint_by_uuid(bcf_comment, viewpoint_uuid)
      bcf_comment.viewpoint = if viewpoint_uuid.nil?
                                nil
                              else
                                viewpoint_by_uuid(viewpoint_uuid)
                              end
    end

    def update_journal_attributes(bcf_comment, comment_data)
      bcf_comment.journal.update(notes: comment_data[:comment],
                                 created_at: comment_data[:modified_date])
      bcf_comment.journal.save
    end

    def import_is_outdated(issue)
      errors = ActiveModel::Errors.new(issue)
      errors.add :base,
                 :conflict,
                 message: I18n.t('bcf.bcf_xml.import.work_package_has_newer_changes',
                                 bcf_uuid: issue.uuid)

      ServiceResult.new(success: false, errors: errors)
    end
  end
end
