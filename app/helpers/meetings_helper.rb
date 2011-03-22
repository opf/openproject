module MeetingsHelper
  def format_participant_list(participants)
    participants.sort.collect{|p| link_to_user p.user}.join("; ")
  end
end
