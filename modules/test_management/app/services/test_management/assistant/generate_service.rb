# frozen_string_literal: true

module TestManagement
  module Assistant
    # Runs a queued generation (GenerateJob, as the requesting user): builds the source material,
    # asks the provider for draft test cases and stores the normalized drafts.
    class GenerateService
      TYPE_HINTS = {
        "positive" => "positive (happy path, valid input)",
        "negative" => "negative (invalid input, errors, permissions)",
        "edge" => "edge cases (empty, unusual or extreme values, interruptions)",
        "boundary" => "boundary values (limits, off-by-one)",
        "security" => "security (authorization, injection, data exposure)",
        "accessibility" => "accessibility (keyboard, screen reader, contrast)",
        "usability" => "usability (feedback, wording, discoverability)"
      }.freeze
      HEARTBEAT_EVERY = 5
      # Reasoning models spend completion tokens on chain-of-thought; leave headroom for the JSON.
      MIN_GENERATION_TOKENS = 12_288

      # client: defaults to the provider and model remembered on the generation (0021).
      def initialize(generation:, client: nil)
        @generation = generation
        @client = client || Client.new(config: ProviderChoice.for_record(generation).config)
      end

      def call
        return if generation.cancelled?
        return unless mark_running

        enter_step!("preparing_source")
        material = Sources.for(generation, user: generation.user)
        return clear_cancelled_progress if cancelled_after_reload?

        enter_step!("waiting_for_model",
                    progress_done: 2,
                    progress_total: TestManagement::AssistantGeneration::PROGRESS_STEPS.size)
        reply = with_heartbeat do
          client.chat(messages: messages(material),
                      max_tokens: generation_token_budget,
                      reasoning: { effort: "low" })
        end
        return clear_cancelled_progress if cancelled_after_reload?

        enter_step!("writing_drafts", progress_done: 0, progress_total: generation.count)

        drafts = Drafts.from_reply(reply.content, types: generation.case_types, count: generation.count)
        if drafts.empty?
          raise Client::Error, no_drafts_message(reply.content)
        end

        persist_drafts(drafts, usage: reply.usage)
      rescue Sources::Error, Client::Error => e
        fail_generation(e.message.first(1000)) unless generation.reload.cancelled?
      end

      def messages(material)
        prompt = Prompt.new
        [
          { role: "system", content: system_prompt(prompt) },
          { role: "user", content: user_prompt(prompt, material) }
        ]
      end

      private

      attr_reader :generation, :client

      def mark_running
        generation.reload
        return false if generation.cancelled?
        return false unless generation.status == "queued"

        generation.update!(status: "running", error: nil, drafts: [], usage: nil,
                           progress_step: "preparing_source",
                           progress_done: 1, progress_total: TestManagement::AssistantGeneration::PROGRESS_STEPS.size,
                           provider_model: client.config.display_label)
        true
      end

      def enter_step!(step, **attrs)
        generation.update!({ progress_step: step }.merge(attrs))
      end

      def persist_drafts(drafts, usage: nil)
        stored = []
        drafts.each do |draft|
          return clear_cancelled_progress if cancelled_after_reload?

          stored << draft
          generation.update!(drafts: stored, progress_step: "writing_drafts",
                             progress_done: stored.size,
                             progress_total: [generation.progress_total.to_i, drafts.size].max)
        end
        return clear_cancelled_progress if cancelled_after_reload?

        generation.update!(status: "done", drafts: stored, progress_step: "writing_drafts",
                           progress_done: stored.size, progress_total: stored.size, error: nil,
                           usage:)
      end

      def cancelled_after_reload?
        generation.reload.cancelled?
      end

      def clear_cancelled_progress
        generation.update!(drafts: [], progress_done: 0, usage: nil) if generation.cancelled?
      end

      def fail_generation(message)
        generation.update!(status: "failed", error: message)
      end

      def no_drafts_message(content)
        excerpt = Prompt.clean(content.to_s).gsub(/\s+/, " ").strip.first(500)
        base = I18n.t("test_management.assistant.errors.no_drafts")
        return base if excerpt.blank?

        "#{base} (model replied: #{excerpt}#{'…' if content.to_s.length > 500})"
      end

      # Keeps updated_at moving while the provider call runs so the UI can show "still working".
      def with_heartbeat
        stop = false
        thread = Thread.new do
          until stop
            sleep HEARTBEAT_EVERY
            break if stop

            ActiveRecord::Base.connection_pool.with_connection { generation.touch }
          end
        end
        yield
      ensure
        stop = true
        thread&.join(1)
      end

      def generation_token_budget
        [client.config.max_tokens, MIN_GENERATION_TOKENS].max
      end

      def system_prompt(prompt)
        <<~TEXT
          You are a senior QA engineer writing manual test cases for a test management tool.
          Follow ISTQB Foundation practices and common testing standards (IEEE 829 / ISO/IEC/IEEE 29119 style):
          clear objectives, traceability to the source, independent cases, explicit preconditions,
          atomic observable steps (action + expected result), and a mix of techniques that fit the
          requested kinds (equivalence partitioning, boundary values, decision tables / error guessing
          for negatives, and risk-based focus for security). Prefer testability and defect-finding
          value over superficial coverage.
          Write at most #{generation.count} distinct, independent test cases for the source material.
          Cover these kinds of tests: #{generation.case_types.map { TYPE_HINTS[it] }.join('; ')}.
          Your entire answer must be a single JSON object. Start with "{" as the first character.
          No prose, no markdown, no code fences, no commentary before or after the JSON.
          Exact shape:
          {"cases":[{"title":"…","type":"one of #{generation.case_types.join('|')}","priority":"critical|high|medium|low",
          "preconditions":"…","steps":[{"action":"…","expected_result":"…"}]}]}
          Each case has 1 to 12 concrete steps and every step has an observable expected result.
          Titles are short (under 120 characters) and unique. Do not invent features that the
          source does not describe. Write in the language of the source material.
          #{prompt.rules}
        TEXT
      end

      def user_prompt(prompt, material)
        "Write the test cases for this source material. Reply with JSON only.\n\n#{prompt.fence(material.label, material.text,
                                                                                                limit: Sources::MAX_SOURCE_CHARS)}"
      end
    end
  end
end
