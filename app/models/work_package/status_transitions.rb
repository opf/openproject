module WorkPackage::StatusTransitions

  include do

  end

# Return true if the issue is being reopened
  def reopened?
    if !new_record? && status_id_changed?
      status_was = IssueStatus.find_by_id(status_id_was)
      status_new = IssueStatus.find_by_id(status_id)
      if status_was && status_new && status_was.is_closed? && !status_new.is_closed?
        return true
      end
    end
    false
  end

  # Return true if the issue is being closed
  def closing?
    if !new_record? && status_id_changed?
      status_was = IssueStatus.find_by_id(status_id_was)
      status_new = IssueStatus.find_by_id(status_id)
      if status_was && status_new && !status_was.is_closed? && status_new.is_closed?
        return true
      end
    end
    false
  end
end