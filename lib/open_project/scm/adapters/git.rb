#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_dependency 'open_project/scm/adapters'

module OpenProject
  module Scm
    module Adapters
      class Git < Base
        include LocalClient

        SCM_GIT_REPORT_LAST_COMMIT = true

        def initialize(url, root_url = nil, _login = nil, _password = nil, path_encoding = nil, identifier = nil)
          super(url, root_url)
          @flag_report_last_commit = SCM_GIT_REPORT_LAST_COMMIT
          @path_encoding = path_encoding.presence || 'UTF-8'
          @identifier = identifier

          if checkout? && identifier.blank?
            raise ArgumentError, %{
              No identifier given. The git adapter requires a project identifier when working
              on a repository remotely.
            }.squish
          end
        end

        def checkout_command
          'git clone'
        end

        def client_command
          @client_command ||= self.class.config[:client_command] || 'git'
        end

        def client_version
          @client_version ||= (git_binary_version || [])
        end

        def scm_version_from_command_line
          capture_out(%w[--version --no-color])
        end

        def git_binary_version
          scm_version = scm_version_from_command_line.dup
          if scm_version.respond_to?(:force_encoding)
            scm_version.force_encoding('ASCII-8BIT')
          end
          m = scm_version.match(%r{\A(.*?)((\d+\.)+\d+)})
          unless m.nil?
            m[2].scan(%r{\d+}).map(&:to_i)
          end
        end

        ##
        # Create a bare repository for the current path
        def initialize_bare_git
          unless checkout_uri.start_with?("/")
            raise ArgumentError, "Cannot initialize bare repository remotely at #{checkout_uri}"
          end

          capture_git(%w[init --bare --shared], no_chdir: true)
        end

        def git_dir
          @git_dir ||= URI.parse(checkout_uri).path
        end

        ##
        # Checks the status of this repository and throws unless it can be accessed
        # correctly by the adapter.
        #
        # @raise [ScmUnavailable] raised when repository is unavailable.
        def check_availability!
          refresh_repository!

          # If it is not empty, it should have at least one branch
          # Any exit code != 0 will raise here
          raise Exceptions::ScmEmpty unless branches.count > 0
        rescue Exceptions::CommandFailed => e
          logger.error("Availability check failed due to failed Git command: #{e.message}")
          raise Exceptions::ScmUnavailable
        end

        ##
        # Checks if the repository is up-to-date. It is not it's updated.
        # Checks out the repository if necessary.
        def refresh_repository!
          if checkout?
            checkout_repository! if !File.directory?(checkout_path)
            update_repository!
          end
        end

        def checkout_repository!
          Rails.logger.info "Checking out #{checkout_uri} to #{checkout_path}"

          FileUtils.mkdir_p checkout_path.parent
          capture_out(
            ["clone", checkout_uri, checkout_path.to_s],
            error_message: "Failed to clone #{checkout_uri} to #{checkout_path}"
          )
        end

        def update_repository!
          Rails.logger.debug "Fetching latest commits for #{checkout_path}"

          Dir.chdir checkout_path do
            fetch_all

            remote_branches = self.remote_branches
            local_branches = self.local_branches

            remote_branches.each do |remote_branch|
              local_branch = remote_branch.sub /^origin\//, ""

              if !local_branches.include?(local_branch)
                track_branch! local_branch, remote_branch
              else
                update_branch! local_branch, remote_branch
              end
            end
          end
        end

        def fetch_all
          capture_out %w[fetch --all], error_message: "Failed to fetch latest commits"
        end

        def remote_branches
          capture_out(%w[branch -r], error_message: "Failed to list remote branches")
            .split("\n")
            .map(&:strip)
            .reject { |b| b.include?("->") } # origin/HEAD -> origin/master
        end

        def local_branches
          capture_out(%w[branch], error_message: "Failed to list local branches")
            .split("\n")
            .map(&:strip)
            .map { |b| b.sub(/^\* /, "") } # remove marker for current branch
        end

        def track_branch!(local_branch, remote_branch)
          Rails.logger.info("Setting up new branch: #{local_branch} -> #{remote_branch}")

          capture_out(
            ["branch", "--track", local_branch, remote_branch],
            error_message: "Failed to track new branch #{remote_branch}"
          )
        end

        def update_branch!(local_branch, remote_branch)
          Rails.logger.debug("Updating branch: #{local_branch}")

          capture_out(
            ["update-ref", local_branch, remote_branch],
            error_message: "Failed update ref to #{remote_branch}"
          )
        end

        def info
          Info.new(root_url: url, lastrev: lastrev('', nil))
        end

        def bare?
          cmd_args = %w|rev-parse --is-bare-repository|
          capture_git(cmd_args).chomp == 'true'
        end

        def checkout?
          checkout_uri =~ /\A\w+:\/\/.+\Z/ # check if it starts file:// or http(s):// etc
        end

        def checkout_path
          Pathname(OpenProject::Configuration.scm_local_checkout_path)
            .join(@identifier)
            .expand_path
        end

        def checkout_uri
          root_url.presence || url
        end

        def branches
          return @branches if @branches
          @branches = []
          cmd_args = %w|branch --no-color|
          popen3(cmd_args) do |io|
            io.each_line do |line|
              @branches << line.match('\s*\*?\s*(.*)$')[1]
            end
          end
          @branches.sort!
        end

        def tags
          return @tags if @tags
          cmd_args = %w|tag|
          @tags = capture_git(cmd_args).lines.sort!.map(&:strip)
        end

        def default_branch
          bras = branches
          return nil if bras.nil?
          bras.include?('master') ? 'master' : bras.first
        end

        def entries(path, identifier = nil)
          entries = Entries.new
          path = scm_encode(@path_encoding, 'UTF-8', path)
          args = %w|ls-tree -l|
          args << "HEAD:#{path}" if identifier.nil?
          args << "#{identifier}:#{path}" if identifier

          parse_by_line(args, binmode: true) do |line|
            e = parse_entry(line, path, identifier)
            entries << e unless entries.detect { |entry| entry.name == e.name }
          end

          entries.sort_by_name
        end

        def parse_entry(line, path, identifier)
          if line.chomp =~ /^\d+\s+(\w+)\s+([0-9a-f]{40})\s+([0-9-]+)\t(.+)$/
            type = $1
            size = $3
            name = $4.force_encoding(@path_encoding)
            path = encode_full_path(name, path || '')

            Entry.new(
              name: scm_encode('UTF-8', @path_encoding, name),
              path: path,
              kind: (type == 'tree') ? 'dir' : 'file',
              size: (type == 'tree') ? nil : size,
              lastrev: @flag_report_last_commit ? lastrev(path, identifier) : Revision.new
            )
          end
        end

        def encode_full_path(name, path)
          full_path = path.empty? ? name : "#{path}/#{name}"
          scm_encode('UTF-8', @path_encoding, full_path)
        end

        def lastrev(path, rev)
          return nil if path.nil?
          args = %w|log --no-color --encoding=UTF-8 --date=iso --pretty=fuller --no-merges -n 1|
          args << rev if rev
          args << '--' << path unless path.empty?
          lines = capture_git(args).lines
          begin
            build_lastrev(lines)
          rescue NoMethodError
            logger.error("The revision '#{path}' has a wrong format")
            return nil
          end
        end

        def build_lastrev(lines)
          id = lines[0].split[1]
          author = lines[1].match('Author:\s+(.*)$')[1]
          time = Time.parse(lines[4].match('CommitDate:\s+(.*)$')[1])

          Revision.new(
            identifier: id,
            scmid: id,
            author: author,
            time: time,
            message: nil,
            paths: nil
          )
        end

        def revisions(path, identifier_from, identifier_to, options = {})
          revisions = Revisions.new
          args = build_revision_args(path, identifier_from, identifier_to, options)

          files = []
          changeset = {}
          parsing_descr = 0 # 0: not parsing desc or files, 1: parsing desc, 2: parsing files
          parse_by_line(args, binmode: true) do |line|
            if line =~ /^commit ([0-9a-f]{40})$/
              key = 'commit'
              value = $1
              if parsing_descr == 1 || parsing_descr == 2
                parsing_descr = 0
                revision = Revision.new(
                  identifier: changeset[:commit],
                  scmid: changeset[:commit],
                  author: changeset[:author],
                  time: Time.parse(changeset[:date]),
                  message: changeset[:description],
                  paths: files
                )
                if block_given?
                  yield revision
                else
                  revisions << revision
                end
                changeset = {}
                files = []
              end
              changeset[:commit] = $1
            elsif (parsing_descr == 0) && line =~ /^(\w+):\s*(.*)$/
              key = $1
              value = $2
              if key == 'Author'
                changeset[:author] = value
              elsif key == 'CommitDate'
                changeset[:date] = value
              end
            elsif (parsing_descr == 0) && line.chomp.to_s == ''
              parsing_descr = 1
              changeset[:description] = ''
            elsif (parsing_descr == 1 || parsing_descr == 2) &&
                  (line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\t(.+)$/)

              parsing_descr = 2
              fileaction = $1
              filepath = $2
              p = scm_encode('UTF-8', @path_encoding, filepath)
              files << { action: fileaction, path: p }
            elsif (parsing_descr == 1 || parsing_descr == 2) &&
                  (line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\d+\s+(\S+)\t(.+)$/)

              parsing_descr = 2
              fileaction = $1
              filepath = $3
              p = scm_encode('UTF-8', @path_encoding, filepath)
              files << { action: fileaction, path: p }
            elsif (parsing_descr == 1) && line.chomp.to_s == ''
              parsing_descr = 2
            elsif parsing_descr == 1
              changeset[:description] << line[4..-1]
            end
          end

          if changeset[:commit]
            revision = Revision.new(
              identifier: changeset[:commit],
              scmid: changeset[:commit],
              author: changeset[:author],
              time: Time.parse(changeset[:date]),
              message: changeset[:description],
              paths: files
            )

            if block_given?
              yield revision
            else
              revisions << revision
            end
          end

          revisions
        end

        def build_revision_args(path, identifier_from, identifier_to, options)
          args = %w|log --no-color --encoding=UTF-8 --raw --date=iso --pretty=fuller|
          args << '--reverse' if options[:reverse]
          args << '--all' if options[:all]
          args << '-n' << "#{options[:limit].to_i}" if options[:limit]
          from_to = ''
          from_to << "#{identifier_from}.." if identifier_from
          from_to << "#{identifier_to}" if identifier_to
          args << from_to if from_to.present?
          args << "--since=#{options[:since].strftime('%Y-%m-%d %H:%M:%S')}" if options[:since]
          args << '--' << scm_encode(@path_encoding, 'UTF-8', path) if path && !path.empty?

          args
        end

        def diff(path, identifier_from, identifier_to = nil)
          args = []
          if identifier_to
            args << 'diff' << '--no-color' << identifier_to << identifier_from
          else
            args << 'show' << '--no-color' << identifier_from
          end
          args << '--' << scm_encode(@path_encoding, 'UTF-8', path) unless path.empty?
          capture_git(args).lines.map(&:chomp)
        rescue Exceptions::CommandFailed
          nil
        end

        def annotate(path, identifier = nil)
          identifier = 'HEAD' if identifier.blank?
          args = %w|blame --encoding=UTF-8|
          args << '-p' << identifier << '--' << scm_encode(@path_encoding, 'UTF-8', path)
          blame = Annotate.new
          content = capture_git(args, binmode: true)

          # Deny to parse large binary files
          # Quick test for null bytes, this may not match all files,
          # but should be a reasonable workaround
          return nil if content.dup.force_encoding('BINARY').count("\x00") > 0

          identifier = ''
          # git shows commit author on the first occurrence only
          authors_by_commit = {}
          content.scrub.split("\n").each do |line|
            if line =~ /^([0-9a-f]{39,40})\s.*/
              identifier = $1
            elsif line =~ /^author (.+)/
              authors_by_commit[identifier] = $1.strip
            elsif line =~ /^\t(.*)/
              blame.add_line(
                $1,
                Revision.new(
                  identifier: identifier,
                  author: authors_by_commit[identifier]))
              identifier = ''
            end
          end
          blame
        end

        def cat(path, identifier = nil)
          if identifier.nil?
            identifier = 'HEAD'
          end
          args = %w|show --no-color|
          args << "#{identifier}:#{scm_encode(@path_encoding, 'UTF-8', path)}"
          capture_git(args, binmode: true)
        end

        class Revision < OpenProject::Scm::Adapters::Revision
          # Returns the readable identifier
          def format_identifier
            identifier[0, 8]
          end
        end

        protected

        ##
        # Builds the full git arguments from the parameters
        # and return the executed stdout as a string
        def capture_git(args, opt = {})
          opt = opt.merge(chdir: checkout_path) if checkout? && !opt[:no_chdir]
          cmd = build_git_cmd(args, opt.slice(:no_chdir))
          capture_out(cmd, opt)
        end

        ##
        # Builds the full git arguments from the parameters
        # and calls the given block with in, out, err, thread
        # from +Open3#popen3+.
        def popen3(args, opt = {}, &block)
          opt = opt.merge(chdir: checkout_path) if checkout?
          cmd = build_git_cmd(args)
          super(cmd, opt) do |_stdin, stdout, stderr, wait_thr|
            block.call(stdout)

            process = wait_thr.value
            if process.exitstatus != 0
              raise Exceptions::CommandFailed.new(
                'git',
                %{
                  `git #{args.join(' ')}` exited with non-zero status:
                  #{process.exitstatus} (#{stderr.read})
                }.squish
              )
            end
          end
        end

        ##
        # Runs the given arguments through git
        # and processes the result line by line.
        #
        def parse_by_line(cmd, opts = {}, &block)
          popen3(cmd) do |io|
            io.binmode if opts[:binmode]
            io.each_line &block
          end
        end

        def build_git_cmd(args, opts = {})
          if client_version_above?([1, 7, 2])
            args.unshift('-c', 'core.quotepath=false')
          end

          # make sure to use bare repository path to initialize a managed repository
          args.unshift('--git-dir', git_dir) unless checkout? && !opts[:no_chdir]
          args
        end
      end
    end
  end
end
