require 'activerecord-import'
require_relative 'issue_reader'
require_relative 'aggregations'

module OpenProject::Bim::BcfXml
  class Importer
    MINIMUM_BCF_VERSION = "2.1"
    attr_reader :file, :project, :current_user

    DEFAULT_IMPORT_OPTIONS = {
      unknown_types_action: "use_default",
      unknown_statuses_action: "use_default",
      unknown_priorities_action: "use_default",
      invalid_people_action: "anonymize",
      unknown_mails_action: 'invite',
      non_members_action: 'chose',
      unknown_types_chose_ids: [],
      unknown_statuses_chose_ids: [],
      unknown_priorities_chose_ids: [],
      unknown_mails_invite_role_ids: [],
      non_members_chose_role_ids: []
    }.freeze

    def initialize(file, project, current_user:)
      @file = file
      @project = project
      @current_user = current_user
    end

    ##
    # Get a list of issues contained in a BCF
    # but do not perform the import
    def extractor_list
      @extractor_list ||= Zip::File.open(@file) do |zip|
        yield_markup_bcf_files(zip)
          .map do |entry|
          to_listing(MarkupExtractor.new(entry))
        end
      end
    end

    def aggregations
      @aggregations ||= Aggregations.new(extractor_list, @project)
    end

    def import!(options = {})
      options = DEFAULT_IMPORT_OPTIONS.merge(options)
      Zip::File.open(@file) do |zip|
        create_or_add_missing_members(options)

        # Extract all topics of the zip and save them
        synchronize_topics(zip, options)

        # TODO: Extract documents

        # TODO: Extract BIM snippets
      end
    rescue StandardError => e
      Rails.logger.error "Failed to import BCF Zip #{file}: #{e} #{e.message}"
      Rails.logger.debug { e.backtrace.join("\n") }
      raise
    end

    def bcf_version_valid?
      Zip::File.open(@file) do |zip|
        zip_entry = zip.find { |entry| entry.name.end_with?('bcf.version') }
        markup = zip_entry.get_input_stream.read
        doc = Nokogiri::XML(markup, nil, 'UTF-8')
        bcf_version = doc.xpath('/Version').first['VersionId']
        return Gem::Version.new(bcf_version) >= Gem::Version.new(MINIMUM_BCF_VERSION)
      end
    rescue StandardError => e
      # The uploaded file could be anything.
      false
    end

    private

    def create_or_add_missing_members(options)
      treat_invalid_people(options)
      treat_unknown_mails(options)
      treat_non_members(options)
    end

    def treat_invalid_people(options)
      if aggregations.invalid_people.any?
        unless options[:invalid_people_action] == 'anonymize'
          raise StandardError.new 'Invalid people found in import. Use valid email addresses.'
        end
      end
    end

    ##
    # Invite all unknown email addresses and add them
    def treat_unknown_mails(options)
      if treat_unknown_mails?(options)
        raise StandardError.new 'For inviting new users you need admin privileges.' unless User.current.admin?
        raise StandardError.new 'Enterprise Edition user limit reached.' unless enterprise_allow_new_users?

        aggregations.unknown_mails.each do |mail|
          add_unknown_mail(mail, options)
        end
      end
    end

    ##
    # Add all non members to project
    def treat_non_members(options)
      aggregations.clear_instance_cache

      if treat_non_members?(options)
        unless User.current.allowed_to?(:manage_members, project)
          raise StandardError.new 'For adding members to the project you need admin privileges.'
        end

        aggregations.non_members.each do |user|
          add_non_member(user, options)
        end
      end
    end

    def add_unknown_mail(mail, options)
      user = UserInvitation.invite_new_user(email: mail)
      member = Member.create(principal: user,
                             project: project)
      membership_service = ::Members::EditMembershipService.new(member,
                                                                save: true,
                                                                current_user: User.current)
      membership_service.call(attributes: { role_ids: options[:unknown_mails_invite_role_ids] })
    end

    def add_non_member(user, options)
      member = Member.create(principal: user,
                             project: project)
      membership_service = ::Members::EditMembershipService.new(member,
                                                                save: true,
                                                                current_user: User.current)
      membership_service.call(attributes: { role_ids: options[:non_members_chose_role_ids] })
    end

    def treat_unknown_mails?(options)
      aggregations.unknown_mails.any? &&
        options[:unknown_mails_action] == 'invite' &&
        options[:unknown_mails_invite_role_ids].any?
    end

    def treat_non_members?(options)
      aggregations.non_members.any? &&
        options[:non_members_action] == 'chose' &&
        options[:non_members_chose_role_ids].any?
    end

    def to_listing(extractor)
      keys = %i[uuid title priority status description author assignee modified_author due_date]
      Hash[keys.map { |k| [k, extractor.public_send(k)] }].tap do |attributes|
        attributes[:viewpoint_count] = extractor.viewpoints.count
        attributes[:comments_count]  = extractor.comments.count
        attributes[:people]          = extractor.people
        attributes[:mail_addresses]  = extractor.mail_addresses
        attributes[:status]          = extractor.status
        attributes[:type]            = extractor.type
      end
    end

    def synchronize_topics(zip, import_options)
      yield_markup_bcf_files(zip)
        .map do |entry|
          issue = IssueReader.new(project,
                                  zip,
                                  entry,
                                  current_user: current_user,
                                  import_options: import_options).extract!

          if issue.errors.blank?
            issue.save
          end
          issue
        end
    end

    ##
    # Yields topic bcf files (that contain topic entries and their uuid) from the ZIP files
    # while skipping all other entries
    def yield_markup_bcf_files(zip)
      zip.select { |entry| entry.name.end_with?('markup.bcf') }
    end

    def enterprise_allow_new_users?
      !OpenProject::Enterprise.user_limit_reached? || !OpenProject::Enterprise.fail_fast?
    end
  end
end
