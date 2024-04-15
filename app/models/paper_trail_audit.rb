class PaperTrailAudit < ApplicationVersion
  self.table_name = :paper_trail_audits
  self.sequence_name = :paper_trail_audits_id_seq
end
