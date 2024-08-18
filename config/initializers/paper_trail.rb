PaperTrail.config.enabled = true # PT will be disabled by rspec
PaperTrail.config.has_paper_trail_defaults = {
  versions: {
    class_name: "::PaperTrailAudit",
    name: :paper_trail_audits
  },
  version: :paper_trail_audit,
  meta: {
    whodunnit: ->(*) { User.current.id },
    stack: ->(*) {
      backtrace = Rails.backtrace_cleaner.clean caller
      backtrace.join("\n")
    }
  },
  on: %i[destroy]
}
