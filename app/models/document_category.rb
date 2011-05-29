class DocumentCategory < Enumeration
  has_many :documents, :foreign_key => 'category_id'

  OptionName = :enumeration_doc_categories

  def option_name
    OptionName
  end

  def objects_count
    documents.count
  end

  def transfer_relations(to)
    documents.update_all("category_id = #{to.id}")
  end
end
