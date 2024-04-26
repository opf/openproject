class RecurringMeeting < ApplicationRecord
  serialize :schedule, coder: IceCube::Schedule

  belongs_to :project
  belongs_to :author, class_name: "User"

  has_many :meetings, inverse_of: :recurring_meeting

  scope :visible, ->(*args) {
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_meetings))
  }
end
