class WikiMenuItem < ActiveRecord::Base
  belongs_to :wiki
  belongs_to :parent, :class_name => 'WikiMenuItem'
  has_many :children, :class_name => 'WikiMenuItem', :dependent => :destroy, :foreign_key => :parent_id, :order => 'id ASC'

  serialize :options, Hash

  named_scope :main_items, lambda { |wiki_id|
    {:conditions => {:wiki_id => wiki_id, :parent_id => nil}, :order => 'id ASC'}
  }

  attr_accessible :name, :title

  validates_presence_of :title
  validates_format_of :title, :with => /^[^,\.\/\?\;\|\:]*$/
  validates_uniqueness_of :title, :scope => :wiki_id

  validates_presence_of :name

  def after_initialize
    self.options ||= Hash.new
  end

  def item_class
    title.dasherize
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
    !!options[:new_wiki_page]
  end

  def new_wiki_page=(value)
    options[:new_wiki_page] = value
  end

  def index_page
    !!options[:index_page]
  end

  def index_page=(value)
    options[:index_page] = value
  end

  def is_main_item?
    parent_id.nil?
  end

  def is_sub_item?
    !parent_id.nil?
  end
end
