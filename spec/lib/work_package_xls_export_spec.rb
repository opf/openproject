require 'spec_helper'
require 'spreadsheet'

describe "WorkPackageXlsExport" do
  let(:project) { FactoryGirl.create :project }

  let(:parent) { FactoryGirl.create :work_package, project: project, subject: 'Parent' }
  let(:child_1) do
    FactoryGirl.create :work_package, parent: parent, project: project, subject: 'Child 1'
  end
  let(:child_2) do
    FactoryGirl.create :work_package, parent: parent, project: project, subject: 'Child 2'
  end

  let(:single) { FactoryGirl.create :work_package, project: project, subject: 'Single' }
  let(:followed) { FactoryGirl.create :work_package, project: project, subject: 'Followed' }

  let(:relation) do
    child_2.new_relation.tap do |r|
      r.to = followed
      r.relation_type = 'follows'
      r.delay = 0
      r.save
    end
  end

  let(:work_packages) do
    [parent, child_1, child_2, single, followed]
  end

  let(:current_user) { FactoryGirl.create :admin } # may export relations

  let(:query) { FactoryGirl.create :query }

  let(:sheet) do
    work_packages
    relation
    work_packages.each(&:reload) # to init .leaves and relations

    load_sheet export
  end

  let(:export) do
    OpenProject::XlsExport::WorkPackageXlsExport.new(
      project: project, work_packages: work_packages, query: query,
      current_user: current_user,
      with_relations: true
    )
  end

  def load_sheet(export)
    f = Tempfile.new 'result.xls'
    begin
      f.binmode
      f.write export.to_xls
    ensure
      f.close
    end

    sheet = Spreadsheet.open(f.path).worksheets.first
    f.unlink

    sheet
  end

  describe 'query' do
    it 'is the default query (the rest of the specs relies on this)' do
      expect(query.columns.map(&:name)).to eq [:id, :subject, :type, :status, :assigned_to]
    end
  end

  it 'writes 9 rows' do
    expect(sheet.rows.size).to eq 9 # 2 header rows + 7 content rows
  end

  it 'the first header row devides the sheet into work packages and relation columns' do
    expect(sheet.rows.first.take(7))
      .to eq ['Work packages', nil, nil, nil, nil, nil, 'Relations']
  end

  it 'the second header row includes the column names for work packages and relations' do
    expect(sheet.rows[1])
      .to eq [
        nil, 'ID', 'Subject', 'Type', 'Status', 'Assignee',
        nil, 'Relation type', 'Delay', 'ID', 'Type', 'Subject',
        nil
      ]
  end

  it 'duplicates rows for each relation' do
    expect(sheet.column(1).drop(2))
      .to eq [
        parent.id, parent.id, child_1.id, child_2.id, child_2.id, single.id, followed.id
      ]
  end

  # expected row and column indices

  PARENT = 2
  CHILD_1 = 4
  CHILD_2 = 5
  SINGLE = 7
  FOLLOWED = 8
  RELATION = 7
  RELATED_SUBJECT = 11

  it 'marks Parent as parent of Child 1 and 2' do
    expect(sheet.row(PARENT)[RELATION]).to eq 'parent of'
    expect(sheet.row(PARENT)[RELATED_SUBJECT]).to eq 'Child 1'

    expect(sheet.row(PARENT + 1)[RELATION]).to eq 'parent of'
    expect(sheet.row(PARENT + 1)[RELATED_SUBJECT]).to eq 'Child 2'
  end

  it 'shows Child 1 as child of Parent' do
    expect(sheet.row(CHILD_1)[RELATION]).to eq 'child of'
    expect(sheet.row(CHILD_1)[RELATED_SUBJECT]).to eq 'Parent'
  end

  it 'shows Child 2 as child of Parent' do
    expect(sheet.row(CHILD_2)[RELATION]).to eq 'child of'
    expect(sheet.row(CHILD_2)[RELATED_SUBJECT]).to eq 'Parent'
  end

  it 'shows Child 2 as following Followed' do
    expect(sheet.row(CHILD_2 + 1)[RELATION]).to eq 'follows'
    expect(sheet.row(CHILD_2 + 1)[RELATED_SUBJECT]).to eq 'Followed'
  end

  it 'shows no relation information for Single' do
    expect(sheet.row(SINGLE).drop(6).compact).to eq []
  end

  it 'shows Followed as preceding Child 2' do
    expect(sheet.row(FOLLOWED)[RELATION]).to eq 'precedes'
    expect(sheet.row(FOLLOWED)[RELATED_SUBJECT]).to eq 'Child 2'
  end

  it 'exports the correct data (examples)' do
    expect(sheet.row(PARENT))
      .to eq [
        nil, parent.id, parent.subject, parent.type.name, parent.status.name, parent.assigned_to,
        nil, 'parent of', nil, child_1.id, child_1.type.name, child_1.subject
      ] # delay nil as this is a parent-child relation not represented by an actual Relation record

    expect(sheet.row(SINGLE))
      .to eq [
        nil, single.id, single.subject, single.type.name, single.status.name, single.assigned_to
      ]

    expect(sheet.row(FOLLOWED))
      .to eq [
        nil, followed.id, followed.subject, followed.type.name, followed.status.name,
          followed.assigned_to,
        nil, 'precedes', 0, child_2.id, child_2.type.name, child_2.subject
      ]
  end

  context 'with someone who may not see related work packages' do
    # Technically not allowed to see any of the work packages.
    # The export only checks for related work packages, though.
    # It's not the export's responsibility to check that the passed
    # work packages may be seen.
    let(:current_user) { FactoryGirl.create :user }

    it 'shows each work package only once' do
      expect(sheet.column(1).drop(2))
        .to eq [
          parent.id, child_1.id, child_2.id, single.id, followed.id
        ]
    end

    it 'shows no relation information' do
      relation_data = sheet.rows
        .drop(2) # drop headers
        .map { |row| row.drop(6) } # leave only relation columns
        .flatten
        .compact

      expect(relation_data).to be_empty
    end
  end
end
