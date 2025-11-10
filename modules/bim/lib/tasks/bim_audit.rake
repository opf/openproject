# frozen_string_literal: true

namespace :bim do
  namespace :audit do
    desc 'Display audit log statistics'
    task stats: :environment do
      puts "\n=== BIM Audit Log Statistics ===\n"

      total_logs = Bim::AuditLog.count
      puts "Total audit log entries: #{total_logs}"

      if total_logs > 0
        # Breakdown by action type
        puts "\nActions by type:"
        Bim::AuditLog.group(:action_type).count.sort_by { |_, count| -count }.first(10).each do |action, count|
          percentage = (count.to_f / total_logs * 100).round(2)
          puts "  #{action.to_s.ljust(30)}: #{count.to_s.rjust(6)} (#{percentage}%)"
        end

        # Breakdown by severity
        puts "\nSeverity distribution:"
        Bim::AuditLog.group(:severity).count.each do |severity, count|
          percentage = (count.to_f / total_logs * 100).round(2)
          puts "  #{severity.to_s.capitalize.ljust(10)}: #{count.to_s.rjust(6)} (#{percentage}%)"
        end

        # Recent activity
        puts "\nRecent activity (last 7 days):"
        recent = Bim::AuditLog.since(7.days.ago).count
        puts "  #{recent} events"

        # Security-sensitive actions
        security_count = Bim::AuditLog.security_sensitive.count
        puts "\nSecurity-sensitive actions: #{security_count}"

        # Reversible actions
        reversible_count = Bim::AuditLog.reversible.not_reversed.count
        puts "Reversible (not reversed): #{reversible_count}"

        # Data integrity
        puts "\nData integrity:"
        logs_with_checksums = Bim::AuditLog.where.not(checksum: nil).count
        puts "  Logs with checksums: #{logs_with_checksums}"

        # Versioned entities
        versioned = Bim::AuditLog.where.not(entity_version: nil).count
        puts "  Versioned entity changes: #{versioned}"
      end

      puts "\n"
    end

    desc 'Clean up old audit logs (older than 2 years by default)'
    task cleanup: :environment do
      older_than = ENV['OLDER_THAN'] ? Time.parse(ENV['OLDER_THAN']) : Bim::AuditLog::DEFAULT_RETENTION_PERIOD.ago

      puts "Cleaning up audit logs older than #{older_than.strftime('%Y-%m-%d')}..."

      deleted_count = Bim::AuditLog.cleanup_old_logs(older_than: older_than)

      puts "✓ Deleted #{deleted_count} audit log entries"
    end

    desc 'Verify audit log integrity'
    task verify: :environment do
      puts "\n=== Verifying Audit Log Integrity ===\n"

      logs_to_check = if ENV['LOG_IDS']
                        Bim::AuditLog.where(id: ENV['LOG_IDS'].split(','))
                      elsif ENV['PROJECT_ID']
                        Bim::AuditLog.for_project(ENV['PROJECT_ID'])
                      else
                        Bim::AuditLog.where.not(checksum: nil).limit(ENV['LIMIT']&.to_i || 1000)
                      end

      total = logs_to_check.count
      puts "Checking #{total} audit log entries..."

      results = Bim::AuditLog.verify_integrity(logs_to_check)

      valid_count = results.count { |r| r[:valid] }
      invalid_count = results.count { |r| !r[:valid] }

      puts "\nResults:"
      puts "  ✓ Valid: #{valid_count}"
      puts "  ✗ Invalid: #{invalid_count}"

      if invalid_count > 0
        puts "\nInvalid entries:"
        results.select { |r| !r[:valid] }.each do |result|
          log = Bim::AuditLog.find(result[:id])
          puts "  - ID #{result[:id]}: #{log.action_type} at #{log.created_at}"
        end
      end

      puts "\n"
    end

    desc 'Export audit logs to CSV or JSON'
    task export: :environment do
      project_id = ENV['PROJECT_ID']
      format = ENV['FORMAT'] || 'csv'
      output_file = ENV['OUTPUT'] || "audit_logs_#{Time.current.to_i}.#{format}"

      raise 'PROJECT_ID required' unless project_id

      logs = Bim::AuditLog.for_project(project_id)

      # Apply filters
      logs = logs.since(Time.parse(ENV['SINCE'])) if ENV['SINCE']
      logs = logs.for_action(ENV['ACTION']) if ENV['ACTION']
      logs = logs.for_user(ENV['USER_ID']) if ENV['USER_ID']

      puts "Exporting #{logs.count} audit logs to #{output_file}..."

      case format
      when 'csv'
        csv_data = Bim::AuditLog.to_csv(logs)
        File.write(output_file, csv_data)
      when 'json'
        json_data = Bim::AuditLog.to_json_export(logs)
        File.write(output_file, json_data)
      else
        raise "Unsupported format: #{format}"
      end

      puts "✓ Exported to #{output_file}"
      puts "  File size: #{(File.size(output_file) / 1024.0).round(2)} KB"
    end

    desc 'Generate audit report for a project'
    task report: :environment do
      project_id = ENV['PROJECT_ID']
      since = ENV['SINCE'] ? Time.parse(ENV['SINCE']) : 30.days.ago

      raise 'PROJECT_ID required' unless project_id

      project = Project.find(project_id)
      logs = Bim::AuditLog.for_project(project_id).since(since)

      puts "\n=== Audit Report for #{project.name} ===\n"
      puts "Period: #{since.strftime('%Y-%m-%d')} to #{Time.current.strftime('%Y-%m-%d')}\n\n"

      puts "Summary:"
      puts "  Total events: #{logs.count}"
      puts "  Unique users: #{logs.pluck(:user_id).compact.uniq.count}"
      puts "  Security events: #{logs.security_sensitive.count}"
      puts "  Data changes: #{logs.with_changes.count}"
      puts "  Reversible actions: #{logs.reversible.not_reversed.count}"

      puts "\nTop actions:"
      logs.group(:action_type).count.sort_by { |_, count| -count }.first(5).each do |action, count|
        puts "  #{action.to_s.ljust(30)}: #{count}"
      end

      puts "\nTop users:"
      Bim::AuditLog.top_users(project_id, since: since).first(5).each do |user_data|
        user = User.find(user_data[:user_id])
        puts "  #{user.name.ljust(30)}: #{user_data[:action_count]} actions"
      end

      puts "\nSeverity distribution:"
      logs.group(:severity).count.each do |severity, count|
        puts "  #{severity.to_s.capitalize.ljust(10)}: #{count}"
      end

      puts "\n"
    end

    desc 'Show entity change history'
    task entity_history: :environment do
      entity_type = ENV['ENTITY_TYPE']
      entity_id = ENV['ENTITY_ID']

      raise 'ENTITY_TYPE and ENTITY_ID required' unless entity_type && entity_id

      logs = Bim::AuditLog.entity_history(entity_type, entity_id)

      puts "\n=== Change History for #{entity_type}##{entity_id} ===\n\n"

      if logs.empty?
        puts "No history found"
      else
        logs.each do |log|
          puts "#{log.formatted_timestamp} - #{log.user&.name || 'System'}"
          puts "  Action: #{log.action_description}"
          puts "  Severity: #{log.severity}"

          unless log.changes.empty?
            puts "  Changes:"
            log.changes.each do |key, value_pair|
              if value_pair.is_a?(Array) && value_pair.length == 2
                puts "    #{key}: #{value_pair[0].inspect} → #{value_pair[1].inspect}"
              end
            end
          end

          puts ""
        end

        puts "Total changes: #{logs.count}"
        puts "Current version: #{logs.last.entity_version}" if logs.last.entity_version
      end

      puts "\n"
    end

    desc 'Show entity versions'
    task entity_versions: :environment do
      entity_type = ENV['ENTITY_TYPE']
      entity_id = ENV['ENTITY_ID']

      raise 'ENTITY_TYPE and ENTITY_ID required' unless entity_type && entity_id

      logs = Bim::AuditLog.entity_versions(entity_type, entity_id)

      puts "\n=== Versions for #{entity_type}##{entity_id} ===\n\n"

      if logs.empty?
        puts "No versions found"
      else
        logs.each do |log|
          puts "Version #{log.entity_version} (previous: #{log.previous_version || 'none'})"
          puts "  #{log.formatted_timestamp} - #{log.user&.name || 'System'}"
          puts "  Action: #{log.action_description}"
          puts "  Changes: #{log.changes.keys.count} attributes"
          puts "  Has snapshot: #{log.has_snapshots? ? 'Yes' : 'No'}"
          puts ""
        end

        puts "Total versions: #{logs.count}"
      end

      puts "\n"
    end

    desc 'Purge all audit logs (DANGEROUS - use with caution!)'
    task purge: :environment do
      unless ENV['CONFIRM'] == 'yes'
        puts "This will DELETE ALL audit logs!"
        puts "To confirm, run: rake bim:audit:purge CONFIRM=yes"
        exit
      end

      count = Bim::AuditLog.count
      puts "Deleting #{count} audit log entries..."

      Bim::AuditLog.delete_all

      puts "✓ All audit logs deleted"
    end

    desc 'Calculate checksum for logs missing it'
    task calculate_checksums: :environment do
      logs_without_checksum = Bim::AuditLog.where(checksum: nil)
      count = logs_without_checksum.count

      puts "Calculating checksums for #{count} logs..."

      updated = 0
      logs_without_checksum.find_each do |log|
        log.send(:generate_checksum)
        if log.save(validate: false)
          updated += 1
          print "." if (updated % 100).zero?
        end
      end

      puts "\n✓ Updated #{updated} logs with checksums"
    end
  end
end
