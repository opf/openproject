# frozen_string_literal: true

module Mngt
  class UserSyncService
    MEMBRO_ROLE_ID        = 4
    MANAGED_CACHE_KEY     = "mngt_api_managed_user_ids_v1"
    MANAGED_CACHE_EXPIRES = 365.days

    def initialize(user)
      @user = user
    end

    # -----------------------------------------------------------------------
    # Class-level entry points
    # -----------------------------------------------------------------------

    def self.dry_run_all
      puts "[DRY RUN] Buscando pessoas na API externa..."

      begin
        people = ExternalPeopleService.all
      rescue ExternalPeopleService::Error => e
        puts "[DRY RUN] ERRO ao buscar API: #{e.message}"
        return
      end

      email_index = build_email_index(people)
      managed_ids = load_managed_user_ids

      puts "[DRY RUN] #{people.size} pessoas na API (#{email_index.size} com e-mail)"
      puts "[DRY RUN] #{User.active.count} usuários ativos no OpenProject"
      puts "[DRY RUN] #{managed_ids.size} usuários rastreados pelo sync\n\n"

      to_create = []; to_sync = []; to_reactivate = []; to_deactivate = []

      email_index.each do |email, person|
        user = User.find_by(mail: email)
        if user.nil?
          to_create << person
        elsif user.active?
          to_sync << [user, person]
        else
          to_reactivate << [user, person]
        end
      end

      User.where(id: managed_ids.to_a).active.each do |user|
        to_deactivate << user unless email_index.key?(user.mail&.downcase)
      end

      if to_create.any?
        puts "=== SERIAM CRIADOS (#{to_create.size}) ==="
        to_create.each do |p|
          puts "  #{p['corporate_email']} — #{p['fullname']} (#{p['company']} / #{p['area']} / #{p['sector']})"
        end
        puts ""
      end

      if to_sync.any?
        puts "=== SERIAM SINCRONIZADOS (#{to_sync.size}) ==="
        to_sync.each do |user, person|
          new(user).send(:report_dry_run, person)
        end
        puts ""
      end

      if to_reactivate.any?
        puts "=== SERIAM REATIVADOS (#{to_reactivate.size}) ==="
        to_reactivate.each do |user, _person|
          puts "  #{user.mail}"
        end
        puts ""
      end

      if to_deactivate.any?
        puts "=== SERIAM INATIVADOS (#{to_deactivate.size}) ==="
        to_deactivate.each { |u| puts "  #{u.mail}" }
        puts ""
      end

      puts "--- Resumo ---"
      puts "Criar: #{to_create.size} | Sincronizar: #{to_sync.size} | " \
           "Reativar: #{to_reactivate.size} | Inativar: #{to_deactivate.size}"
    end

    def self.sync_all
      Rails.logger.info("[Mngt::UserSync] Starting full sync")

      begin
        people = ExternalPeopleService.all
      rescue ExternalPeopleService::Error => e
        Rails.logger.error("[Mngt::UserSync] API fetch failed: #{e.message}")
        return
      end

      email_index     = build_email_index(people)
      managed_ids     = load_managed_user_ids
      new_managed_ids = Set.new

      email_index.each do |email, person|
        user = User.find_by(mail: email) || build_user(person)
        next unless user

        unless user.active?
          user.activate
          Rails.logger.info("[Mngt::UserSync] Reactivating #{email}")
        end
        user.save! if user.new_record? || user.changed?

        new_managed_ids << user.id
        new(user).perform_sync(person)
      end

      User.where(id: managed_ids.to_a).active.each do |user|
        next if email_index.key?(user.mail&.downcase)

        user.lock!
        new(user).deactivate_stream_user
        Rails.logger.info("[Mngt::UserSync] Deactivated #{user.mail} (no longer in API)")
      end

      save_managed_user_ids(new_managed_ids)
      Rails.logger.info("[Mngt::UserSync] Done — managed #{new_managed_ids.size} users")
    end

    # -----------------------------------------------------------------------
    # Instance: sync a single user (for ad-hoc use)
    # -----------------------------------------------------------------------

    def sync(dry_run: false)
      people = ExternalPeopleService.all
      person = people.find { |p| p["corporate_email"]&.downcase == @user.mail&.downcase }

      dry_run ? report_dry_run(person) : perform_sync(person)
    rescue ExternalPeopleService::Error => e
      Rails.logger.warn("[Mngt::UserSync] API fetch failed for #{@user.mail}: #{e.message}")
    end

    def perform_sync(person)
      return unless person

      company_name = person["company"]
      area_name    = person["area"]
      sector_name  = person["sector"]
      company_id   = person["company_id"]
      area_id      = person["area_id"]
      sector_id    = person["sector_id"]

      slug = Mngt::Companies.slug_for_company_name(company_name)
      return unless slug

      Mngt::UserProfile.upsert(
        { user_id: @user.id, company_slug: slug },
        unique_by: :user_id,
        update_only: [:company_slug]
      )

      ensure_stream_channel_membership("#{slug}--geral")

      company_project = find_project(api_company_id: company_id, name: company_name)
      return unless company_project

      area_project   = nil
      sector_project = nil

      if area_id || area_name.present?
        area_project = find_or_create_area_project(company_project, area_name, company_id, area_id)

        if area_project && (sector_id || sector_name.present?)
          sector_project = find_or_create_sector_project(area_project, sector_name,
                                                         company_id, area_id, sector_id)
        end
      end

      add_user_to_assigned_projects(company_project, area_project, sector_project)
    rescue => e
      Rails.logger.error("[Mngt::UserSync] perform_sync failed for #{@user.mail}: #{e.message}\n#{e.backtrace.first(3).join("\n")}")
    end

    # -----------------------------------------------------------------------
    private
    # -----------------------------------------------------------------------

    def report_dry_run(person)
      prefix = "  #{@user.mail}"

      unless person
        puts "#{prefix}: não encontrado na API"
        return
      end

      company_name = person["company"]
      area_name    = person["area"]
      sector_name  = person["sector"]
      company_id   = person["company_id"]
      area_id      = person["area_id"]
      sector_id    = person["sector_id"]
      slug         = Mngt::Companies.slug_for_company_name(company_name)

      unless slug
        puts "#{prefix}: empresa '#{company_name}' não mapeada — ignorado"
        return
      end

      company_project = find_project(api_company_id: company_id, name: company_name,
                                     record_link: false)
      area_project    = company_project ? find_project(api_company_id: company_id, api_area_id: area_id,
                                                       name: area_name, parent_id: company_project.id,
                                                       record_link: false) : nil
      sector_project  = area_project ? find_project(api_company_id: company_id, api_area_id: area_id,
                                                     api_sector_id: sector_id, name: sector_name,
                                                     parent_id: area_project.id, record_link: false) : nil

      puts "#{prefix}:"
      puts "    empresa=#{company_name}, área=#{area_name.presence || '(vazia)'}, setor=#{sector_name.presence || '(vazio)'}"
      puts "    → canal '#{slug}--geral'"

      [
        [company_project, "Espaço empresa",  company_name],
        [area_project,    "Espaço área",     area_name],
        [sector_project,  "Espaço setor",    sector_name]
      ].each do |project, label, name|
        if project
          status = explicit_member?(@user.id, project.id) ? "já membro" : "SERIA ADICIONADO"
          puts "    #{label}: #{project.name} (id:#{project.id}) — #{status}"
        elsif name.present?
          puts "    #{label}: '#{name}' — SERIA CRIADO"
        end
      end
    end

    # Lookup by API IDs first; falls back to name-matching and optionally records the link.
    # Pass record_link: false for dry-run paths to avoid writing to DB.
    def find_project(api_company_id: nil, api_area_id: nil, api_sector_id: nil,
                     name: nil, parent_id: nil, record_link: true)
      if api_company_id
        binding = Mngt::ProjectApiId.find_by(
          api_company_id: api_company_id,
          api_area_id:    api_area_id,
          api_sector_id:  api_sector_id
        )
        return binding.project if binding&.project&.active?
      end

      return nil if name.blank?

      scope      = parent_id ? Project.active.where(parent_id:) : Project.active.where(parent_id: nil)
      normalized = Mngt::Companies.normalize(name)
      project    = scope.find { |p| Mngt::Companies.normalize(p.name) == normalized }

      if project && api_company_id && record_link
        record = Mngt::ProjectApiId.find_or_initialize_by(project_id: project.id)
        record.assign_attributes(api_company_id:, api_area_id:, api_sector_id:)
        record.save!
      end

      project
    end

    def find_or_create_area_project(company_project, area_name, api_company_id, api_area_id)
      project = find_project(
        api_company_id: api_company_id,
        api_area_id:    api_area_id,
        name:           area_name,
        parent_id:      company_project.id
      )
      return project if project
      return nil if area_name.blank?

      project = Project.new(
        name:                 area_name,
        parent_id:            company_project.id,
        workspace_type:       :program,
        public:               false,
        enabled_module_names: Setting.default_projects_modules
      )

      if project.save
        Mngt::ProjectApiId.create!(
          project:        project,
          api_company_id: api_company_id,
          api_area_id:    api_area_id,
          api_sector_id:  nil
        )
        Rails.logger.info("[Mngt::UserSync] Created area project '#{area_name}' under '#{company_project.name}'")
        project
      else
        Rails.logger.error("[Mngt::UserSync] Failed to create area project '#{area_name}': " \
                           "#{project.errors.full_messages.join(', ')}")
        nil
      end
    end

    def find_or_create_sector_project(area_project, sector_name, api_company_id, api_area_id,
                                      api_sector_id)
      project = find_project(
        api_company_id: api_company_id,
        api_area_id:    api_area_id,
        api_sector_id:  api_sector_id,
        name:           sector_name,
        parent_id:      area_project.id
      )
      return project if project
      return nil if sector_name.blank?

      project = Project.new(
        name:                 sector_name,
        parent_id:            area_project.id,
        workspace_type:       :project,
        public:               false,
        enabled_module_names: Setting.default_projects_modules
      )

      if project.save
        Mngt::ProjectApiId.create!(
          project:        project,
          api_company_id: api_company_id,
          api_area_id:    api_area_id,
          api_sector_id:  api_sector_id
        )
        Rails.logger.info("[Mngt::UserSync] Created sector project '#{sector_name}' under '#{area_project.name}'")
        project
      else
        Rails.logger.error("[Mngt::UserSync] Failed to create sector project '#{sector_name}': " \
                           "#{project.errors.full_messages.join(', ')}")
        nil
      end
    end

    # Adds @user explicitly to their assigned path in the hierarchy:
    # company project + their area + their sector (whichever exist).
    def add_user_to_assigned_projects(company_project, area_project, sector_project)
      [company_project, area_project, sector_project].compact.each do |project|
        next if explicit_member?(@user.id, project.id)

        call = Members::CreateService
                 .new(user: system_user, contract_class: EmptyContract)
                 .call(principal: @user, project_id: project.id, role_ids: [MEMBRO_ROLE_ID])

        unless call.success?
          Rails.logger.error("[Mngt::UserSync] Failed to add #{@user.mail} to " \
                             "'#{project.name}': #{call.errors.full_messages.join(', ')}")
        end
      end
    rescue => e
      Rails.logger.error("[Mngt::UserSync] add_user_to_assigned_projects failed for #{@user.mail}: #{e.message}")
    end

    def explicit_member?(user_id, project_id)
      Member
        .joins(:member_roles)
        .where(user_id:, project_id:, member_roles: { inherited_from: nil })
        .exists?
    end

    def deactivate_stream_user
      Mngt::StreamChannelService.new(@user).deactivate_user
    end

    def ensure_stream_channel_membership(channel_id)
      svc = Mngt::StreamChannelService.new(@user)
      svc.upsert_current_user
      svc.add_to_team_channel(channel_id)
    rescue Mngt::StreamChannelService::Error => e
      Rails.logger.warn("[Mngt::UserSync] Stream #{channel_id} failed for #{@user.mail}: #{e.message}")
    end

    def system_user
      @system_user ||= User.system
    end

    # -----------------------------------------------------------------------
    # Private class methods
    # -----------------------------------------------------------------------

    def self.build_email_index(people)
      people
        .select { |p| p["corporate_email"].present? }
        .index_by { |p| p["corporate_email"].downcase }
    end
    private_class_method :build_email_index

    def self.build_user(person)
      email    = person["corporate_email"]
      fullname = person["fullname"].to_s.strip
      parts    = fullname.split(" ", 2)
      base     = email.split("@").first
      login    = unique_login(base)

      user = User.new(
        login:     login,
        mail:      email,
        firstname: parts[0].presence || "Usuário",
        lastname:  parts[1].presence || "—",
        language:  "pt-BR"
      )
      user.activate

      if user.save
        Rails.logger.info("[Mngt::UserSync] Created user #{email}")
        user
      else
        Rails.logger.error("[Mngt::UserSync] Failed to create #{email}: #{user.errors.full_messages.join(', ')}")
        nil
      end
    end
    private_class_method :build_user

    def self.unique_login(base)
      login = base
      i     = 2
      while User.exists?(login: login)
        login = "#{base}#{i}"
        i    += 1
      end
      login
    end
    private_class_method :unique_login

    def self.load_managed_user_ids
      raw = Rails.cache.read(MANAGED_CACHE_KEY)
      raw.is_a?(Array) ? raw.to_set : Set.new
    end
    private_class_method :load_managed_user_ids

    def self.save_managed_user_ids(ids)
      Rails.cache.write(MANAGED_CACHE_KEY, ids.to_a, expires_in: MANAGED_CACHE_EXPIRES)
    end
    private_class_method :save_managed_user_ids
  end
end
