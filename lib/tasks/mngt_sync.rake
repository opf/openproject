# frozen_string_literal: true

namespace :mngt do
  desc "Inspect raw fields returned by the external people API"
  task inspect_api: :environment do
    begin
      people = Mngt::ExternalPeopleService.all
    rescue Mngt::ExternalPeopleService::Error => e
      puts "ERROR: #{e.message}"
      exit 1
    end

    puts "Total people: #{people.size}"
    puts ""

    if people.any?
      puts "=== Fields on first record ==="
      puts people.first.keys.inspect
      puts ""
      puts "=== First 3 records ==="
      people.first(3).each_with_index do |p, i|
        puts "--- [#{i}] ---"
        p.each { |k, v| puts "  #{k}: #{v.inspect}" }
      end
      puts ""
    end

    puts "=== Unique values per field ==="
    %w[company area sector].each do |field|
      values = people.filter_map { |p| p[field].presence }.uniq.sort
      next if values.empty?

      puts "#{field} (#{values.size} unique): #{values.inspect}"
    end
  end

  # ---------------------------------------------------------------------------
  # Dry run: show what sector sub-projects would be created/synced
  # Uses IDs when available, falls back to name-matching (read-only).
  # ---------------------------------------------------------------------------
  desc "Dry run: show what sector sub-projects would be created/synced"
  task dry_run_sectors: :environment do
    begin
      people = Mngt::ExternalPeopleService.all
    rescue Mngt::ExternalPeopleService::Error => e
      puts "ERROR: #{e.message}"
      exit 1
    end

    puts "=== Mapeamento empresa → área → setor (dry run) ===\n\n"

    # Build unique org tree from people data, keyed by API IDs
    tree = {}
    people.each do |p|
      cid = p["company_id"]
      aid = p["area_id"]
      sid = p["sector_id"]
      next unless cid

      tree[cid] ||= { name: p["company"], areas: {} }
      next unless aid

      tree[cid][:areas][aid] ||= { name: p["area"], sectors: {} }
      next unless sid

      tree[cid][:areas][aid][:sectors][sid] = p["sector"]
    end

    to_create = 0; to_skip = 0

    tree.each do |company_id, company_data|
      company_name    = company_data[:name]
      company_project = find_project_dry(api_company_id: company_id, name: company_name)

      puts "[#{company_name}] (id:#{company_id}, projeto=#{company_project&.name || 'NÃO ENCONTRADO'})"

      company_data[:areas].each do |area_id, area_data|
        area_name    = area_data[:name]
        area_project = company_project ? find_project_dry(api_company_id: company_id, api_area_id: area_id,
                                                          name: area_name, parent_id: company_project.id) : nil

        area_label = area_project ? area_project.name : "SERIA CRIADO"
        puts "  └─ #{area_name} (id:#{area_id}, projeto=#{area_label})"

        area_data[:sectors].each do |sector_id, sector_name|
          sector_project = area_project ? find_project_dry(api_company_id: company_id, api_area_id: area_id,
                                                           api_sector_id: sector_id, name: sector_name,
                                                           parent_id: area_project.id) : nil

          status = if sector_project
            to_skip += 1
            "já existe (id:#{sector_project.id})"
          else
            to_create += 1
            "SERIA CRIADO"
          end
          puts "     └─ #{sector_name} (id:#{sector_id}) — #{status}"
        end
      end

      puts ""
    end

    puts "--- Resumo ---"
    puts "Criar: #{to_create} | Já existem: #{to_skip}"
  end

  # ---------------------------------------------------------------------------
  # Backfill: assign API IDs to already-existing company/area projects.
  # Uses people data to derive the full (company_id, area_id, sector_id) tree,
  # then name-matches to existing projects and records the link. Idempotent.
  # ---------------------------------------------------------------------------
  desc "Backfill API IDs onto existing company/area/sector projects"
  task backfill_project_ids: :environment do
    begin
      people = Mngt::ExternalPeopleService.all
    rescue Mngt::ExternalPeopleService::Error => e
      puts "ERROR: #{e.message}"
      exit 1
    end

    # Build unique org tree from people data
    tree = {}
    people.each do |p|
      cid = p["company_id"]
      aid = p["area_id"]
      sid = p["sector_id"]
      next unless cid

      tree[cid] ||= { name: p["company"], areas: {} }
      next unless aid

      tree[cid][:areas][aid] ||= { name: p["area"], sectors: {} }
      next unless sid

      tree[cid][:areas][aid][:sectors][sid] = p["sector"]
    end

    linked = 0; not_found = 0

    tree.each do |company_id, company_data|
      company_name    = company_data[:name]
      company_project = Project.active.where(parent_id: nil).find { |p|
        Mngt::Companies.normalize(p.name) == Mngt::Companies.normalize(company_name)
      }

      if company_project
        upsert_api_id(company_project.id, company_id, nil, nil)
        puts "  [empresa] #{company_name} (api_id:#{company_id}) → projeto #{company_project.id} ✓"
        linked += 1
      else
        puts "  [empresa] #{company_name} (api_id:#{company_id}) → NÃO ENCONTRADO"
        not_found += 1
      end

      company_data[:areas].each do |area_id, area_data|
        area_name    = area_data[:name]
        area_project = company_project ? Project.active.where(parent_id: company_project.id).find { |p|
          Mngt::Companies.normalize(p.name) == Mngt::Companies.normalize(area_name)
        } : nil

        if area_project
          upsert_api_id(area_project.id, company_id, area_id, nil)
          puts "    [área] #{area_name} (api_id:#{area_id}) → projeto #{area_project.id} ✓"
          linked += 1
        else
          puts "    [área] #{area_name} (api_id:#{area_id}) → NÃO ENCONTRADO"
          not_found += 1
        end

        area_data[:sectors].each do |sector_id, sector_name|
          sector_project = area_project ? Project.active.where(parent_id: area_project.id).find { |p|
            Mngt::Companies.normalize(p.name) == Mngt::Companies.normalize(sector_name)
          } : nil

          if sector_project
            upsert_api_id(sector_project.id, company_id, area_id, sector_id)
            puts "      [setor] #{sector_name} (api_id:#{sector_id}) → projeto #{sector_project.id} ✓"
            linked += 1
          else
            puts "      [setor] #{sector_name} (api_id:#{sector_id}) → não existe ainda"
          end
        end
      end
    end

    puts "\n--- Resumo ---"
    puts "Vinculados: #{linked} | Não encontrados: #{not_found}"
  end

  # ---------------------------------------------------------------------------
  # Full dry run: empresa, área, setor e membros (por usuário)
  # ---------------------------------------------------------------------------
  desc "Full dry run: empresa, área, setor e membros"
  task dry_run_all: :environment do
    Mngt::UserSyncService.dry_run_all
  end

  # ---------------------------------------------------------------------------
  # Helpers (available within the namespace)
  # ---------------------------------------------------------------------------

  def find_project_dry(api_company_id: nil, api_area_id: nil, api_sector_id: nil,
                       name: nil, parent_id: nil)
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
    scope.find { |p| Mngt::Companies.normalize(p.name) == normalized }
  end

  def upsert_api_id(project_id, company_id, area_id, sector_id)
    record = Mngt::ProjectApiId.find_or_initialize_by(project_id: project_id)
    record.assign_attributes(api_company_id: company_id, api_area_id: area_id, api_sector_id: sector_id)
    record.save!
  end
end
