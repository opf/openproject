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

      email_index  = build_email_index(people)
      managed_ids  = load_managed_user_ids

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
          puts "  #{p['corporate_email']} — #{p['fullname']} (#{p['company']} / #{p['area']})"
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
      slug         = Mngt::Companies.slug_for_company_name(company_name)
      return unless slug

      ensure_stream_channel_membership("#{slug}--geral")

      membro_role     = Role.find(MEMBRO_ROLE_ID)
      company_project = find_project(nil, company_name)
      area_project    = company_project ? find_project(company_project.id, area_name) : nil

      [company_project, area_project].compact.each do |project|
        next if already_member?(project)

        member = Member.new(project: project, principal: @user)
        member.roles << membro_role
        member.save!
        Rails.logger.info("[Mngt::UserSync] Added #{@user.mail} to '#{project.name}'")
      end
    rescue => e
      Rails.logger.error("[Mngt::UserSync] perform_sync failed for #{@user.mail}: #{e.message}")
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
      slug         = Mngt::Companies.slug_for_company_name(company_name)

      unless slug
        puts "#{prefix}: empresa '#{company_name}' não mapeada — ignorado"
        return
      end

      channel_id      = "#{slug}--geral"
      company_project = find_project(nil, company_name)
      area_project    = company_project ? find_project(company_project.id, area_name) : nil

      puts "#{prefix}:"
      puts "    empresa=#{company_name}, área=#{area_name.presence || '(vazia)'} → canal '#{channel_id}'"

      if company_project
        label = already_member?(company_project) ? "já membro" : "SERIA ADICIONADO"
        puts "    Projeto empresa: #{company_project.name} (id:#{company_project.id}) — #{label}"
      else
        puts "    Projeto empresa: nenhum encontrado para '#{company_name}'"
      end

      if area_project
        label = already_member?(area_project) ? "já membro" : "SERIA ADICIONADO"
        puts "    Projeto área: #{area_project.name} (id:#{area_project.id}) — #{label}"
      elsif company_project && area_name.present?
        puts "    Projeto área: nenhum encontrado para '#{area_name}'"
      end
    end

    def ensure_stream_channel_membership(channel_id)
      svc = Mngt::StreamChannelService.new(@user)
      svc.upsert_current_user
      svc.add_to_team_channel(channel_id)
    rescue Mngt::StreamChannelService::Error => e
      Rails.logger.warn("[Mngt::UserSync] Stream #{channel_id} failed for #{@user.mail}: #{e.message}")
    end

    def find_project(parent_id, name)
      return nil if name.blank?

      scope      = parent_id ? Project.active.where(parent_id: parent_id) : Project.active.where(parent_id: nil)
      normalized = Mngt::Companies.normalize(name)
      scope.find { |p| Mngt::Companies.normalize(p.name) == normalized }
    end

    def already_member?(project)
      Member.exists?(project: project, principal: @user)
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
