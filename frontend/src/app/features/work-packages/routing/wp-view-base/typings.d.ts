interface IGroupsCollapseEvent {
  state:Record<string, boolean>;
  allGroupsAreCollapsed:boolean;
  allGroupsAreExpanded:boolean;
  lastChangedGroup:string|null;
  allGroupsChanged:boolean;
  groupedBy:string|null;
}
