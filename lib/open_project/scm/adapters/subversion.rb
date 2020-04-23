#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'uri'

module OpenProject
  module SCM
    module Adapters
      class Subversion < ::OpenProject::SCM::Adapters::Base
        include LocalClient

        def client_command
          @client_command ||= self.class.config[:client_command] || 'svn'
        end

        def svnadmin_command
          @svnadmin_command ||= (self.class.config[:svnadmin_command] || 'svnadmin')
        end

        def client_version
          @client_version ||= (svn_binary_version || [])
        end

        def svn_binary_version
          scm_version = scm_version_from_command_line.dup
          m = scm_version.match(%r{\A(.*?)((\d+\.)+\d+)})
          if m
            m[2].scan(%r{\d+}).map(&:to_i)
          end
        end

        def scm_version_from_command_line
          capture_out('--version')
        end

        ##
        # Subversion may be local or remote,
        # for now determine it by the URL type.
        def local?
          url.start_with?('file://')
        end

        ##
        # Returns the local repository path
        # (if applicable).
        def local_repository_path
          root_url.sub('file://', '')
        end

        def initialize(url, root_url = nil, login = nil, password = nil, _path_encoding = nil, identifier = nil)
          super(url, root_url)

          @login = login
          @password = password
          @identifier = identifier
        end

        def checkout_command
          'svn checkout'
        end

        def subtree_checkout?
          true
        end

        ##
        # Checks the status of this repository and throws unless it can be accessed
        # correctly by the adapter.
        #
        # @raise [SCMUnavailable] raised when repository is unavailable.
        def check_availability!
          # Check whether we can access svn repository uuid
          popen3(['info', '--xml', target]) do |stdout, stderr|
            doc = Nokogiri::XML(stdout.read)

            raise Exceptions::SCMEmpty if doc.at_xpath('/info/entry/commit[@revision="0"]')

            return if doc.at_xpath('/info/entry/repository/uuid')

            stderr.each_line do |l|
              Rails.logger.error("SVN access error: #{l}") if l =~ /E\d+:/
              raise Exceptions::SCMUnauthorized.new if l.include?('E215004: Authentication failed')
            end
          end

          raise Exceptions::SCMUnavailable
        end

        ##
        # Creates an empty repository using svnadmin
        #
        def create_empty_svn
          _, err, code = Open3.capture3(svnadmin_command, 'create', root_url)
          if code != 0
            msg = "Failed to create empty subversion repository with `#{svnadmin_command} create`"
            logger.error(msg)
            logger.debug("Error output is #{err}")
            raise Exceptions::CommandFailed.new(client_command, msg)
          end
        end

        # Get info about the svn repository
        def info
          cmd = build_svn_cmd(['info', '--xml', target])
          xml_capture(cmd, force_encoding: true) do |doc|
            Info.new(
              root_url: doc.xpath('/info/entry/repository/root').text,
              lastrev: extract_revision(doc.at_xpath('/info/entry/commit'))
            )
          end
        end

        def entries(path = nil, identifier = nil)
          path ||= ''
          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : 'HEAD'
          entries = Entries.new
          cmd = ['list', '--xml', "#{target(path)}@#{identifier}"]
          xml_capture(cmd, force_encoding: true) do |doc|
            doc.xpath('/lists/list/entry').each { |list| entries << extract_entry(list, path) }
          end
          entries.sort_by_name
        end

        def properties(path, identifier = nil)
          # proplist xml output supported in svn 1.5.0 and higher
          return nil unless client_version_above?([1, 5, 0])

          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : 'HEAD'
          cmd = ['proplist', '--verbose', '--xml', "#{target(path)}@#{identifier}"]
          properties = {}
          xml_capture(cmd, force_encoding: true) do |doc|
            doc.xpath('/properties/target/property').each do |prop|
              properties[prop['name']] = prop.text
            end
          end

          properties
        end

        def revisions(path = nil, identifier_from = nil, identifier_to = nil, options = {})
          revisions = Revisions.new
          fetch_revision_entries(identifier_from, identifier_to, options, path) do |logentry|
            paths = logentry.xpath('paths/path').map { |entry| build_path(entry) }
            paths.sort! { |x, y| x[:path] <=> y[:path] }

            r = extract_revision(logentry)
            r.paths = paths

            revisions << r
          end
          revisions
        end

        ##
        # For repositories that are actually checked-out sub directories of
        # other repositories Repository#fetch_changesets will fail trying to
        # go through revisions 1:200 because the lowest available revision
        # can be greater than 200.
        #
        # To fix this we find out the earliest available revision here
        # and start from there.
        def start_revision
          cmd = %w(log -r1:HEAD --limit 1) + [target('')]

          rev = capture_svn(cmd).lines.map(&:strip)
            .select { |line| line =~ /\Ar\d+ \|/ }
            .map { |line| line.split(" ").first.sub(/\Ar/, "") }
            .first

          rev ? rev.to_i : 0
        end

        def diff(path, identifier_from, identifier_to = nil, _type = 'inline')
          path ||= ''

          identifier_from = numeric_identifier(identifier_from)
          identifier_to = numeric_identifier(identifier_to, identifier_from - 1)

          cmd = ['diff', '-r', "#{identifier_to}:#{identifier_from}",
                 "#{target(path)}@#{identifier_from}"]
          capture_svn(cmd).lines
        end

        def numeric_identifier(identifier, default = '')
          if identifier && identifier.to_i > 0
            identifier.to_i
          else
            default
          end
        end

        def cat(path, identifier = nil)
          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : 'HEAD'
          cmd = ['cat', "#{target(path)}@#{identifier}"]
          capture_svn(cmd)
        end

        def annotate(path, identifier = nil)
          identifier = (identifier and identifier.to_i > 0) ? identifier.to_i : 'HEAD'
          cmd = ['blame', "#{target(path)}@#{identifier}"]
          blame = Annotate.new
          popen3(cmd) do |io, _|
            io.each_line do |line|
              next unless line =~ %r{^\s*(\d+)\s*(\S+)\s(.*)$}
              blame.add_line($3.rstrip, Revision.new(identifier: $1.to_i, author: $2.strip))
            end
          end
          blame
        end

        private

        ##
        # Builds the SVM command arguments around the given parameters
        # Appends to the parameter:
        # --username, --password    if specified for this repository
        # --no-auth-cache           force re-authentication
        # --non-interactive         avoid prompts
        def build_svn_cmd(args)
          if @login.present?
            args.push('--username', @login)
            args.push('--password', @password) if @password.present?
          end

          if self.class.config[:trustedssl]
            args.push('--trust-server-cert')
          end

          args.push('--no-auth-cache', '--non-interactive')
        end

        def xml_capture(cmd, opts = {})
          output = capture_svn(cmd, opts)
          doc = Nokogiri::XML(output)

          # Yield helper methods instead of doc
          yield doc
        end

        def extract_entry(entry, path)
          revision = extract_revision(entry.at_xpath('commit'))
          kind, size, name = parse_entry(entry)

          # Skip directory if there is no commit date (usually that
          # means that we don't have read access to it)
          return if kind == 'dir' && revision.time.nil?

          Entry.new(
            name: URI.unescape(name),
            path: ((path.empty? ? '' : "#{path}/") + name),
            kind: kind,
            size: size.empty? ? nil : size.to_i,
            lastrev: revision
          )
        end

        def parse_entry(entry)
          kind = entry['kind']
          size = entry.xpath('size').text
          name = entry.xpath('name').text

          [kind, size, name]
        end

        def build_path(entry)
          {
            action: entry['action'],
            path: entry.text,
            from_path: entry['copyfrom-path'],
            from_revision: entry['copyfrom-rev']
          }
        end

        def extract_revision(commit_node)
          # We may be unauthorized to read the commit date
          date =
            begin
              Time.parse(commit_node.xpath('date').text).localtime
            rescue ArgumentError
              nil
            end

          Revision.new(
            identifier: commit_node['revision'],
            time: date,
            message: commit_node.xpath('msg').text,
            author: commit_node.xpath('author').text
          )
        end

        def fetch_revision_entries(identifier_from, identifier_to, options, path, &block)
          path ||= ''
          identifier_from = numeric_identifier(identifier_from, 'HEAD')
          identifier_to = numeric_identifier(identifier_to, 1)
          cmd = ['log', '--xml', '-r', "#{identifier_from}:#{identifier_to}"]
          cmd << '--verbose' if options[:with_paths]
          cmd << '--limit' << options[:limit].to_s if options[:limit]
          cmd << target(path, peg: identifier_from)
          xml_capture(cmd, force_encoding: true) do |doc|
            doc.xpath('/log/logentry').each &block
          end
        end

        ##
        # Builds the full git arguments from the parameters
        # and return the executed stdout as a string
        def capture_svn(args, opt = {})
          cmd = build_svn_cmd(args)
          output = capture_out(cmd)

          if opt[:force_encoding] && output.respond_to?(:force_encoding)
            output.force_encoding('UTF-8')
          end

          output
        end

        ##
        # Target path with optional peg revision
        # http://svnbook.red-bean.com/en/1.7/svn.advanced.pegrevs.html
        def target(path = '', peg: nil)
          path = super(path)

          if peg
            path + "@#{peg}"
          else
            path
          end
        end


        ##
        # Builds the full git arguments from the parameters
        # and calls the given block with in, out, err, thread
        # from +Open3#popen3+.
        def popen3(args, &block)
          cmd = build_svn_cmd(args)
          super(cmd) do |_stdin, stdout, stderr, wait_thr|
            block.call(stdout, stderr)

            process = wait_thr.value
            return process.exitstatus == 0
          end
        end
      end
    end
  end
end
