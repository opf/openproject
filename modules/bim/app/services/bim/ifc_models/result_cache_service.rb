# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#++

module Bim
  module IfcModels
    # Service to cache and retrieve IFC conversion results
    # Caches XKT files and metadata by file checksum for instant retrieval
    class ResultCacheService
      # Configuration constants
      CACHE_VERSION = 1 # Increment to invalidate all caches
      CACHE_TTL = 90.days
      CACHE_DIR_BASE = 'ifc_cache'
      COMPRESSION_ENABLED = true

      # Statistics tracking
      class CacheStats
        attr_accessor :hits, :misses, :stores, :evictions

        def initialize
          @hits = 0
          @misses = 0
          @stores = 0
          @evictions = 0
        end

        def hit_rate
          total = hits + misses
          return 0.0 if total.zero?
          (hits.to_f / total * 100).round(2)
        end

        def to_h
          {
            hits: hits,
            misses: misses,
            stores: stores,
            evictions: evictions,
            hit_rate: hit_rate
          }
        end
      end

      class << self
        def stats
          @stats ||= CacheStats.new
        end

        def reset_stats!
          @stats = CacheStats.new
        end
      end

      attr_reader :ifc_model, :file_checksum

      def initialize(ifc_model)
        @ifc_model = ifc_model
        @file_checksum = calculate_checksum
      end

      # Check if cached result exists for this IFC file
      def cached?
        cache_key = build_cache_key
        cache_entry_exists?(cache_key) && !cache_expired?(cache_key)
      end

      # Retrieve cached XKT and metadata if available
      def retrieve
        return nil unless cached?

        cache_key = build_cache_key
        cache_path = cache_file_path(cache_key)

        Rails.logger.info "Cache HIT for IFC model #{ifc_model.id} (checksum: #{file_checksum[0..7]})"
        self.class.stats.hits += 1

        # Load cached data
        cached_data = load_cache_data(cache_path)
        return nil unless cached_data

        # Apply cached XKT to model
        apply_cached_xkt(cached_data[:xkt_path])

        # Apply cached metadata
        apply_cached_metadata(cached_data[:metadata]) if cached_data[:metadata]

        # Update cache access time
        touch_cache(cache_path)

        cached_data
      rescue StandardError => e
        Rails.logger.error "Failed to retrieve cache: #{e.message}"
        self.class.stats.misses += 1
        nil
      end

      # Store conversion results in cache
      def store(xkt_path:, metadata: nil)
        cache_key = build_cache_key
        cache_path = cache_file_path(cache_key)

        ensure_cache_directory!

        Rails.logger.info "Caching IFC model #{ifc_model.id} (checksum: #{file_checksum[0..7]})"
        self.class.stats.stores += 1

        # Prepare cache data
        cache_data = {
          version: CACHE_VERSION,
          checksum: file_checksum,
          ifc_filename: ifc_model.ifc_attachment.filename,
          ifc_size: ifc_model.ifc_attachment.filesize,
          xkt_path: copy_xkt_to_cache(xkt_path, cache_key),
          metadata: metadata,
          created_at: Time.current.iso8601,
          accessed_at: Time.current.iso8601
        }

        # Compress and save
        save_cache_data(cache_path, cache_data)

        cache_data
      rescue StandardError => e
        Rails.logger.error "Failed to store cache: #{e.message}"
        nil
      end

      # Clear cache for this specific model
      def clear
        cache_key = build_cache_key
        cache_path = cache_file_path(cache_key)

        if File.exist?(cache_path)
          FileUtils.rm_rf(File.dirname(cache_path))
          Rails.logger.info "Cleared cache for IFC model #{ifc_model.id}"
        end
      end

      # Clear all expired caches
      def self.cleanup_expired
        cache_base_dir = Rails.root.join('tmp', CACHE_DIR_BASE)
        return unless Dir.exist?(cache_base_dir)

        expired_count = 0
        Dir.glob(File.join(cache_base_dir, '*', 'cache.json')).each do |cache_file|
          if cache_expired?(cache_file)
            FileUtils.rm_rf(File.dirname(cache_file))
            expired_count += 1
            stats.evictions += 1
          end
        end

        Rails.logger.info "Cleaned up #{expired_count} expired IFC caches"
        expired_count
      end

      # Get cache statistics
      def self.cache_statistics
        cache_base_dir = Rails.root.join('tmp', CACHE_DIR_BASE)
        return { total: 0, size: 0 } unless Dir.exist?(cache_base_dir)

        cache_entries = Dir.glob(File.join(cache_base_dir, '*', 'cache.json'))
        total_size = cache_entries.sum do |cache_file|
          Dir.glob(File.join(File.dirname(cache_file), '**', '*'))
             .select { |f| File.file?(f) }
             .sum { |f| File.size(f) }
        end

        {
          total: cache_entries.count,
          size: total_size,
          size_mb: (total_size / 1024.0 / 1024.0).round(2),
          stats: stats.to_h
        }
      end

      private

      def build_cache_key
        "#{CACHE_VERSION}_#{file_checksum}"
      end

      def cache_file_path(cache_key)
        Rails.root.join('tmp', CACHE_DIR_BASE, cache_key, 'cache.json')
      end

      def cache_entry_exists?(cache_key)
        File.exist?(cache_file_path(cache_key))
      end

      def cache_expired?(cache_path)
        cache_path = cache_file_path(cache_path) if cache_path.is_a?(String) && !cache_path.end_with?('.json')
        return true unless File.exist?(cache_path)

        cache_data = JSON.parse(File.read(cache_path))
        accessed_at = Time.parse(cache_data['accessed_at'])
        accessed_at < CACHE_TTL.ago
      rescue StandardError
        true
      end

      def ensure_cache_directory!
        cache_key = build_cache_key
        cache_dir = File.dirname(cache_file_path(cache_key))
        FileUtils.mkdir_p(cache_dir)
      end

      def copy_xkt_to_cache(xkt_path, cache_key)
        cache_dir = File.dirname(cache_file_path(cache_key))
        cached_xkt_path = File.join(cache_dir, 'model.xkt')

        if COMPRESSION_ENABLED
          # Compress XKT for storage efficiency
          cached_xkt_path += '.gz'
          compress_file(xkt_path, cached_xkt_path)
        else
          FileUtils.cp(xkt_path, cached_xkt_path)
        end

        cached_xkt_path
      end

      def compress_file(source, destination)
        Zlib::GzipWriter.open(destination) do |gz|
          File.open(source, 'rb') do |file|
            while (chunk = file.read(8192))
              gz.write(chunk)
            end
          end
        end
      end

      def decompress_file(source, destination)
        Zlib::GzipReader.open(source) do |gz|
          File.open(destination, 'wb') do |file|
            while (chunk = gz.read(8192))
              file.write(chunk)
            end
          end
        end
      end

      def save_cache_data(cache_path, data)
        File.write(cache_path, JSON.pretty_generate(data))
      end

      def load_cache_data(cache_path)
        return nil unless File.exist?(cache_path)

        data = JSON.parse(File.read(cache_path), symbolize_names: true)

        # Verify cache version
        return nil if data[:version] != CACHE_VERSION

        data
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse cache data: #{e.message}"
        nil
      end

      def apply_cached_xkt(cached_xkt_path)
        return unless File.exist?(cached_xkt_path)

        # Decompress if needed
        if cached_xkt_path.end_with?('.gz')
          tmp_xkt = Tempfile.new(['model', '.xkt'])
          decompress_file(cached_xkt_path, tmp_xkt.path)
          ifc_model.xkt_attachment = File.new(tmp_xkt.path)
          tmp_xkt.close
          tmp_xkt.unlink
        else
          ifc_model.xkt_attachment = File.new(cached_xkt_path)
        end
      end

      def apply_cached_metadata(metadata_hash)
        return unless metadata_hash

        # Create or update metadata record
        ifc_metadata = ifc_model.ifc_model_metadata || ifc_model.build_ifc_model_metadata

        ifc_metadata.update!(
          ifc_version: metadata_hash[:ifc_version],
          entity_count: metadata_hash[:entity_count],
          geometry_count: metadata_hash[:geometry_count],
          spatial_structure: metadata_hash[:spatial_structure] || {},
          property_sets: metadata_hash[:property_sets] || {},
          quantities: metadata_hash[:quantities] || {},
          classifications: metadata_hash[:classifications] || {},
          materials: metadata_hash[:materials] || {},
          types: metadata_hash[:types] || {},
          validation_result: metadata_hash[:validation_result] || {},
          file_checksum: file_checksum
        )
      end

      def touch_cache(cache_path)
        cache_data = JSON.parse(File.read(cache_path))
        cache_data['accessed_at'] = Time.current.iso8601
        File.write(cache_path, JSON.pretty_generate(cache_data))
      rescue StandardError => e
        Rails.logger.warn "Failed to touch cache: #{e.message}"
      end

      def calculate_checksum
        return @file_checksum if @file_checksum

        ifc_attachment = ifc_model.ifc_attachment
        return nil unless ifc_attachment&.diskfile&.path

        @file_checksum = Digest::SHA256.file(ifc_attachment.diskfile.path).hexdigest
      rescue StandardError => e
        Rails.logger.error "Failed to calculate checksum: #{e.message}"
        nil
      end
    end
  end
end
