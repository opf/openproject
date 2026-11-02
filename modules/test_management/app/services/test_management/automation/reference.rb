# frozen_string_literal: true

module TestManagement
  module Automation
    # Repo-qualified automation references (0016).
    #
    #   [<name>[/e2e]:]<file or class>[#<title path>]
    #
    #   shop:tests/cart.spec.ts#cart › adds an item       unit / integration test of repo "shop"
    #   shop/e2e:e2e/checkout.spec.ts#checkout › pays     end-to-end test of repo "shop"
    #   tests/cart.spec.ts#cart › adds an item            unqualified (before 0016; still valid)
    #
    # <name> is the reference name of a CI connection of the project (CiConnection#reference_qualifier_name:
    # the reference_name setting, else the last segment of the repository path). "/e2e" marks
    # end-to-end tests; it is informative and does not change matching (shop: and shop/e2e: are
    # the same repository). The part after the qualifier is the reference the report produces
    # (Playwright "<file>#<title path joined by ' › '>", JUnit "<classname>#<name>", native "reference").
    #
    # A prefix only counts as a qualifier when it names a connection of the project; anything else
    # ("Feature: Login#…", "a.spec.ts:12#…", "api:users", "https://…") stays an unqualified
    # reference, so existing references keep their meaning.
    class Reference
      PREFIX = %r{\A(?<name>[A-Za-z0-9][A-Za-z0-9_.-]{0,99})(?<e2e>/e2e)?:(?<body>.+)\z}m
      # The body may not look like the rest of a URL, a Windows path, a line number or "::" (pytest ids).
      BODY_EXCLUDED = %r{\A(?:[\s:/\\]|\d+(?::\d+)?(?:#|\z))}
      E2E_PATH = %r{(?:\A|[/._-])e2e(?:[/._-]|\z)}i
      E2E_DIRECTORIES = %w[cypress].freeze
      E2E_FORMATS = %w[playwright_json].freeze
      E2E_TEST_TYPES = %w[e2e end-to-end end2end].freeze

      attr_reader :raw, :name, :body

      # names: reference names of the project's connections (Array / Set of lower-case strings);
      # nil accepts any syntactically valid qualifier.
      def self.parse(raw, names: nil)
        new(raw, names)
      end

      def self.build(name, body, e2e: false)
        return body.to_s if name.blank?

        "#{name}#{'/e2e' if e2e}:#{body}"
      end

      def initialize(raw, names)
        @raw = raw.to_s.strip
        match = PREFIX.match(@raw)
        if match && !match[:body].match?(BODY_EXCLUDED) && (names.nil? || names.include?(match[:name].downcase))
          @name = match[:name]
          @e2e = match[:e2e].present?
          @body = match[:body]
        else
          @body = @raw
          @e2e = false
        end
      end

      def qualified? = name.present?
      def e2e? = @e2e

      # File / class part ("tests/cart.spec.ts") and title part ("cart › adds an item").
      def path = body.split("#", 2).first.to_s.strip
      def fragment = body.split("#", 2)[1].to_s.strip.presence

      def for_name?(other)
        qualified? && other.present? && name.casecmp?(other.to_s)
      end

      # Is a test end-to-end? First match wins:
      # 1. upload option testType ("e2e" -> yes, any other value -> no);
      # 2. the connection's e2e_tests setting (always / never);
      # 3. auto: Playwright JSON reports, or a path with an "e2e" segment (e2e/…, tests/e2e/…,
      #    checkout.e2e.ts, checkout.e2e-spec.ts) or below cypress/.
      def self.e2e?(path:, connection: nil, test_type: nil, format: nil)
        return E2E_TEST_TYPES.include?(test_type.to_s.downcase) if test_type.present?

        case connection&.e2e_tests
        when "always" then return true
        when "never" then return false
        end
        return true if E2E_FORMATS.include?(format.to_s)

        path = path.to_s.delete_prefix("./")
        path.match?(E2E_PATH) || E2E_DIRECTORIES.include?(path.split("/").first.to_s.downcase)
      end

      # Reference handling of one upload: which stored references a reported test matches, and
      # which reference is written to a case created or linked by the upload.
      #   name – the connection's reference name, else the last segment of ci.repository; nil
      #          when unknown (then references stay unqualified, as before 0016).
      class Context
        attr_reader :name

        def initialize(project:, connection: nil, options: nil, format: nil)
          @connection = connection
          @options = options
          @format = format
          @names = CiConnection.reference_names(project)
          @name = connection&.reference_qualifier_name || repository_name(options)
          @names |= [@name.downcase] if @name
        end

        # Stored references that match a reported reference, most specific first:
        # "<name>:<body>", "<name>/e2e:<body>", then the unqualified body. A report reference that is
        # itself qualified ("other:…", e.g. a tm_ref annotation) uses its own name.
        def candidates(reference)
          parsed = Reference.parse(reference, names: @names)
          return [] if parsed.body.blank?

          name = parsed.name || @name
          qualified = name ? [name, name.downcase].uniq.flat_map { |n| ["#{n}:#{parsed.body}", "#{n}/e2e:#{parsed.body}"] } : []
          (qualified + [parsed.body]).uniq
        end

        # Reference stored on a case created or linked by this upload.
        def reference_for(record)
          parsed = Reference.parse(record.reference, names: @names)
          return parsed.raw if parsed.qualified? || @name.nil?

          e2e = Reference.e2e?(path: record.file.presence || parsed.path, connection: @connection,
                               test_type: @options&.test_type, format: @format)
          Reference.build(@name, parsed.body, e2e:)
        end

        private

        def repository_name(options)
          repo = options&.ci&.dig("repository").to_s.strip.delete_suffix(".git")
          repo.split("/").last.to_s.gsub(/[^A-Za-z0-9_.-]+/, "-").gsub(/\A[^A-Za-z0-9]+|-+\z/, "").first(100).presence
        end
      end
    end
  end
end
