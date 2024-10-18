interface IGroupsCollapseEvent {
  state:{ [identifier:string]:boolean };
  allGroupsAreCollapsed:boolean;
  allGroupsAreExpanded:boolean;
  lastChangedGroup:string|null;
  allGroupsChanged:boolean;
  groupedBy:string|null;
}

interface IHierarchiesCollapseEvent {
  allHierarchiesChanged:boolean;
}
