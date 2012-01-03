#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'cgi'

module Redmine
  module Scm
    module Adapters
      class CommandFailed < StandardError #:nodoc:
      end

      class AbstractAdapter #:nodoc:
        class << self
          def client_command
            ""
          end

          # Returns the version of the scm client
          # Eg: [1, 5, 0] or [] if unknown
          def client_version
            []
          end

          # Returns the version string of the scm client
          # Eg: '1.5.0' or 'Unknown version' if unknown
          def client_version_string
            v = client_version || 'Unknown version'
            v.is_a?(Array) ? v.join('.') : v.to_s
          end

          # Returns true if the current client version is above
          # or equals the given one
          # If option is :unknown is set to true, it will return
          # true if the client version is unknown
          def client_version_above?(v, options={})
            ((client_version <=> v) >= 0) || (client_version.empty? && options[:unknown])
          end

          def client_available
            true
          end

          def shell_quote(str)
            if Redmine::Platform.mswin?
              '"' + str.gsub(/"/, '\\"') + '"'
            else
              "'" + str.gsub(/'/, "'\"'\"'") + "'"
            end
          end
        end

        def initialize(url, root_url=nil, login=nil, password=nil,
                       path_encoding=nil)
          @url = url
          @login = login if login && !login.empty?
          @password = (password || "") if @login
          @root_url = root_url.blank? ? retrieve_root_url : root_url
        end

        def adapter_name
          'Abstract'
        end

        def supports_cat?
          true
        end

        def supports_annotate?
          respond_to?('annotate')
        end

        def root_url
          @root_url
        end

        def url
          @url
        end

        # get info about the svn repository
        def info
          return nil
        end

        # Returns the entry identified by path and revision identifier
        # or nil if entry doesn't exist in the repository
        def entry(path=nil, identifier=nil)
          parts = path.to_s.split(%r{[\/\\]}).select {|n| !n.blank?}
          search_path = parts[0..-2].join('/')
          search_name = parts[-1]
          if search_path.blank? && search_name.blank?
            # Root entry
            Entry.new(:path => '', :kind => 'dir')
          else
            # Search for the entry in the parent directory
            es = entries(search_path, identifier)
            es ? es.detect {|e| e.name == search_name} : nil
          end
        end

        # Returns an Entries collection
        # or nil if the given path doesn't exist in the repository
        def entries(path=nil, identifier=nil)
          return nil
        end

        def branches
          return nil
        end

        def tags
          return nil
        end

        def default_branch
          return nil
        end

        def properties(path, identifier=nil)
          return nil
        end

        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          return nil
        end

        def diff(path, identifier_from, identifier_to=nil)
          return nil
        end

        def cat(path, identifier=nil)
          return nil
        end

        def with_leading_slash(path)
          path ||= ''
          (path[0,1]!="/") ? "/#{path}" : path
        end

        def with_trailling_slash(path)
          path ||= ''
          (path[-1,1] == "/") ? path : "#{path}/"
        end

        def without_leading_slash(path)
          path ||= ''
          path.gsub(%r{^/+}, '')
        end

        def without_trailling_slash(path)
          path ||= ''
          (path[-1,1] == "/") ? path[0..-2] : path
         end

        def shell_quote(str)
          self.class.shell_quote(str)
        end

      private
        def retrieve_root_url
          info = self.info
          info ? info.root_url : nil
        end

        def target(path)
          path ||= ''
          base = path.match(/^\//) ? root_url : url
          shell_quote("#{base}/#{path}".gsub(/[?<>\*]/, ''))
        end

        def logger
          self.class.logger
        end

        def shellout(cmd, &block)
          self.class.shellout(cmd, &block)
        end

        def self.logger
          RAILS_DEFAULT_LOGGER
        end

        def self.shellout(cmd, &block)
          logger.debug "Shelling out: #{strip_credential(cmd)}" if logger && logger.debug?
          if Rails.env == 'development'
            # Capture stderr when running in dev environment
            cmd = "#{cmd} 2>>#{RAILS_ROOT}/log/scm.stderr.log"
          end
          begin
            if RUBY_VERSION < '1.9'
              mode = "r+"
            else
              mode = "r+:ASCII-8BIT"
            end
            IO.popen(cmd, mode) do |io|
              io.close_write
              block.call(io) if block_given?
            end
          rescue Errno::ENOENT => e
            msg = strip_credential(e.message)
            # The command failed, log it and re-raise
            logger.error("SCM command failed, make sure that your SCM binary (eg. svn) is in PATH (#{ENV['PATH']}): #{strip_credential(cmd)}\n  with: #{msg}")
            raise CommandFailed.new(msg)
          end
        end

        # Hides username/password in a given command
        def self.strip_credential(cmd)
          q = (Redmine::Platform.mswin? ? '"' : "'")
          cmd.to_s.gsub(/(\-\-(password|username))\s+(#{q}[^#{q}]+#{q}|[^#{q}]\S+)/, '\\1 xxxx')
        end

        def strip_credential(cmd)
          self.class.strip_credential(cmd)
        end

        def scm_iconv(to, from, str)
          return nil if str.nil?
          return str if to == from
          begin
            Iconv.conv(to, from, str)
          rescue Iconv::Failure => err
            logger.error("failed to convert from #{from} to #{to}. #{err}")
            nil
          end
        end
      end

      class Entries < Array
        def sort_by_name
          sort {|x,y|
            if x.kind == y.kind
              x.name.to_s <=> y.name.to_s
            else
              x.kind <=> y.kind
            end
          }
        end

        def revisions
          revisions ||= Revisions.new(collect{|entry| entry.lastrev}.compact)
        end

        # Required since Ruby 1.9.3 as the core compact always returns an
        # instance of Array. This method follows the spec for Array#compact
        def compact
          ary = self.dup
          ary.compact!
          ary
        end
      end

      class Info
        attr_accessor :root_url, :lastrev
        def initialize(attributes={})
          self.root_url = attributes[:root_url] if attributes[:root_url]
          self.lastrev = attributes[:lastrev]
        end
      end

      class Entry
        attr_accessor :name, :path, :kind, :size, :lastrev
        def initialize(attributes={})
          self.name = attributes[:name] if attributes[:name]
          self.path = attributes[:path] if attributes[:path]
          self.kind = attributes[:kind] if attributes[:kind]
          self.size = attributes[:size].to_i if attributes[:size]
          self.lastrev = attributes[:lastrev]
        end

        def is_file?
          'file' == self.kind
        end

        def is_dir?
          'dir' == self.kind
        end

        def is_text?
          Redmine::MimeType.is_type?('text', name)
        end
      end

      class Revisions < Array
        def latest
          sort {|x,y|
            unless x.time.nil? or y.time.nil?
              x.time <=> y.time
            else
              0
            end
          }.last
        end
      end

      class Revision
        attr_accessor :scmid, :name, :author, :time, :message, :paths, :revision, :branch
        attr_writer :identifier

        def initialize(attributes={})
          self.identifier = attributes[:identifier]
          self.scmid = attributes[:scmid]
          self.name = attributes[:name] || self.identifier
          self.author = attributes[:author]
          self.time = attributes[:time]
          self.message = attributes[:message] || ""
          self.paths = attributes[:paths]
          self.revision = attributes[:revision]
          self.branch = attributes[:branch]
        end

        # Returns the identifier of this revision; see also Changeset model
        def identifier
          (@identifier || revision).to_s
        end

        # Returns the readable identifier.
        def format_identifier
          identifier
        end
      end

      class Annotate
        attr_reader :lines, :revisions

        def initialize
          @lines = []
          @revisions = []
        end

        def add_line(line, revision)
          @lines << line
          @revisions << revision
        end

        def content
          content = lines.join("\n")
        end

        def empty?
          lines.empty?
        end
      end
    end
  end
end
