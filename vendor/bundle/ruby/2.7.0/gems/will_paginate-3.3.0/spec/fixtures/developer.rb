class Developer < User
  has_and_belongs_to_many :projects, :join_table => 'developers_projects'

  scope :poor, lambda {
    where(['salary <= ?', 80000]).order('salary')
  }

  def self.per_page() 10 end
end
