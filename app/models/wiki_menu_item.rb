class WikiMenuItem < ActiveRecord::Base
  belongs_to :wiki
  belongs_to :parent, :class_name => 'WikiMenuItem'
  has_many :children, :class_name => 'WikiMenuItem', :dependent => :destroy, :foreign_key => :parent_id

  named_scope :main_items, lambda { |wiki_id|
    {:conditions => {:wiki_id => wiki_id, :parent_id => nil}}
  }

  attr_accessible :name, :title

  before_destroy :validate_if_at_least_one_item_exists

  validates_presence_of :title
  validates_format_of :title, :with => /^[^,\.\/\?\;\|\:]*$/

  validates_presence_of :name

  def validate_if_at_least_one_item_exists
    if self.is_main_item? and not new_record? and WikiMenuItem.main_items(wiki_id).size <= 1
      errors.add_to_base(:wiki_cannot_delete_last_item)
      return false
    end
  end

  def setting
    if new_record?
      :no_item
    elsif is_main_item?
      :main_item
    else
      :sub_item
    end
  end

  def new_wiki_page
  end

  def index_page
  end

  def is_main_item?
    parent_id.nil?
  end

  def is_sub_item?
    !parent_id.nil?
  end
end
