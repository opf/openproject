module OpenProject::Bim::BcfXml
  class Aggregations
    attr_reader :listings, :project, :instance_cache

    def initialize(listing, project)
      @listings = listing
      @project = project

      @instance_cache = {}
    end

    def all_people
      @instance_cache[:all_people] ||= listings.map { |entry| entry[:people] }.flatten.uniq
    end

    def all_mails
      @instance_cache[:all_mails] ||= listings.map { |entry| entry[:mail_addresses] }.flatten.uniq
    end

    def known_users
      @instance_cache[:known_users] ||= User.where(mail: all_mails).includes(:memberships)
    end

    def unknown_mails
      @instance_cache[:unknown_mails] ||= all_mails.map(&:downcase) - known_users.map(&:mail).map(&:downcase)
    end

    def members
      @instance_cache[:members] ||= known_users.select { |user| user.projects.map(&:id).include? @project.id }
    end

    def non_members
      @instance_cache[:non_members] ||= known_users - members
    end

    def invalid_people
      @instance_cache[:invalid_people] ||= all_people - all_mails
    end

    def all_statuses
      @instance_cache[:all_statuses] ||= listings.map { |entry| entry[:status] }.flatten.uniq
    end

    def unknown_statuses
      @instance_cache[:unknown_statuses] ||= all_statuses - Status.all.map(&:name)
    end

    def all_types
      @instance_cache[:all_types] ||= listings.map { |entry| entry[:type] }.flatten.uniq
    end

    def unknown_types
      @instance_cache[:unknown_types] ||= all_types - Type.all.map(&:name)
    end

    def all_priorities
      @instance_cache[:all_priorities] ||= listings.map { |entry| entry[:priority] }.flatten.uniq
    end

    def unknown_priorities
      @instance_cache[:unknown_priorities] ||= all_priorities - IssuePriority.all.map(&:name)
    end

    def clear_instance_cache
      @instance_cache = {}
    end
  end
end
