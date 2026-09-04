# frozen_string_literal: true

namespace :bim do
  namespace :cache do
    desc 'Display IFC cache statistics'
    task stats: :environment do
      stats = Bim::IfcModels::ResultCacheService.cache_statistics

      puts "\n" + "=" * 60
      puts "IFC CONVERSION CACHE STATISTICS"
      puts "=" * 60
      puts "\nCache Entries: #{stats[:total]}"
      puts "Total Size: #{stats[:size_mb]} MB"
      puts "\nPerformance Metrics:"
      puts "  Cache Hits: #{stats[:stats][:hits]}"
      puts "  Cache Misses: #{stats[:stats][:misses]}"
      puts "  Hit Rate: #{stats[:stats][:hit_rate]}%"
      puts "  Stores: #{stats[:stats][:stores]}"
      puts "  Evictions: #{stats[:stats][:evictions]}"
      puts "=" * 60 + "\n"
    end

    desc 'Clean up expired IFC cache entries'
    task cleanup: :environment do
      puts "\nCleaning up expired IFC cache entries..."
      count = Bim::IfcModels::ResultCacheService.cleanup_expired
      puts "✓ Cleaned up #{count} expired cache entries\n"
    end

    desc 'Clear all IFC cache entries'
    task clear: :environment do
      cache_dir = Rails.root.join('tmp', Bim::IfcModels::ResultCacheService::CACHE_DIR_BASE)

      if Dir.exist?(cache_dir)
        print "\nThis will delete ALL cached IFC conversions. Are you sure? (y/N): "
        confirm = STDIN.gets.chomp.downcase

        if confirm == 'y'
          FileUtils.rm_rf(cache_dir)
          Bim::IfcModels::ResultCacheService.reset_stats!
          puts "✓ All IFC cache entries cleared\n"
        else
          puts "✗ Operation cancelled\n"
        end
      else
        puts "✓ Cache directory does not exist (already clean)\n"
      end
    end

    desc 'Warm up cache for all IFC models'
    task warmup: :environment do
      puts "\nWarming up IFC cache (converting all uncached models)..."

      models_to_process = Bim::IfcModels::IfcModel.where(conversion_status: [
        Bim::IfcModels::IfcModel.conversion_statuses[:pending],
        Bim::IfcModels::IfcModel.conversion_statuses[:error]
      ])

      total = models_to_process.count
      processed = 0

      if total.zero?
        puts "✓ No models need processing\n"
        return
      end

      puts "Found #{total} models to process...\n"

      models_to_process.find_each do |model|
        processed += 1
        print "\r[#{processed}/#{total}] Processing: #{model.title.truncate(40)}..."

        begin
          cache_service = Bim::IfcModels::ResultCacheService.new(model)
          unless cache_service.cached?
            Bim::IfcModels::IfcConversionJob.perform_now(model)
          end
        rescue StandardError => e
          puts "\n  ✗ Failed: #{e.message}"
        end
      end

      puts "\n✓ Cache warmup complete (#{processed} models processed)\n"
    end

    desc 'Show detailed cache report'
    task report: :environment do
      cache_dir = Rails.root.join('tmp', Bim::IfcModels::ResultCacheService::CACHE_DIR_BASE)

      unless Dir.exist?(cache_dir)
        puts "\n✗ No cache directory found\n"
        return
      end

      cache_entries = Dir.glob(File.join(cache_dir, '*', 'cache.json'))

      puts "\n" + "=" * 80
      puts "DETAILED IFC CACHE REPORT"
      puts "=" * 80

      total_size = 0
      cache_data = []

      cache_entries.each do |cache_file|
        begin
          data = JSON.parse(File.read(cache_file))
          cache_dir_path = File.dirname(cache_file)

          # Calculate directory size
          dir_size = Dir.glob(File.join(cache_dir_path, '**', '*'))
                        .select { |f| File.file?(f) }
                        .sum { |f| File.size(f) }

          total_size += dir_size

          cache_data << {
            checksum: data['checksum'][0..7],
            filename: data['ifc_filename'],
            ifc_size_mb: (data['ifc_size'] / 1024.0 / 1024.0).round(2),
            cache_size_mb: (dir_size / 1024.0 / 1024.0).round(2),
            created: Time.parse(data['created_at']).strftime('%Y-%m-%d %H:%M'),
            accessed: Time.parse(data['accessed_at']).strftime('%Y-%m-%d %H:%M')
          }
        rescue StandardError => e
          puts "Warning: Failed to read cache file #{cache_file}: #{e.message}"
        end
      end

      # Sort by cache size (largest first)
      cache_data.sort_by! { |d| -d[:cache_size_mb] }

      puts "\nTotal Entries: #{cache_data.count}"
      puts "Total Cache Size: #{(total_size / 1024.0 / 1024.0).round(2)} MB\n"
      puts "\nTop Entries by Size:"
      puts "-" * 80
      printf "%-10s %-30s %12s %12s %17s\n", "Checksum", "Filename", "IFC (MB)", "Cache (MB)", "Last Accessed"
      puts "-" * 80

      cache_data.first(20).each do |entry|
        printf "%-10s %-30s %12.2f %12.2f %17s\n",
               entry[:checksum],
               entry[:filename].truncate(28),
               entry[:ifc_size_mb],
               entry[:cache_size_mb],
               entry[:accessed]
      end

      if cache_data.count > 20
        puts "\n... and #{cache_data.count - 20} more entries"
      end

      puts "=" * 80 + "\n"
    end

    desc 'Benchmark cache performance'
    task benchmark: :environment do
      require 'benchmark'

      puts "\n" + "=" * 60
      puts "IFC CACHE PERFORMANCE BENCHMARK"
      puts "=" * 60

      # Find a model to test
      test_model = Bim::IfcModels::IfcModel.where(conversion_status: :completed).first

      unless test_model
        puts "\n✗ No converted models found for benchmarking\n"
        return
      end

      puts "\nTest Model: #{test_model.title}"
      puts "File Size: #{(test_model.ifc_attachment.filesize / 1024.0 / 1024.0).round(2)} MB\n"

      cache_service = Bim::IfcModels::ResultCacheService.new(test_model)

      # Ensure cache exists
      unless cache_service.cached?
        puts "Warming up cache for test model..."
        Bim::IfcModels::ViewConverterService.new(test_model).call
      end

      puts "\nRunning benchmark (10 iterations)...\n"

      times = Benchmark.measure do
        10.times do
          cache_service = Bim::IfcModels::ResultCacheService.new(test_model)
          cache_service.retrieve
        end
      end

      avg_time = (times.real / 10.0 * 1000).round(2)

      puts "\nResults:"
      puts "  Average retrieval time: #{avg_time} ms"
      puts "  Throughput: #{(10.0 / times.real).round(2)} retrievals/sec"
      puts "=" * 60 + "\n"
    end
  end
end
