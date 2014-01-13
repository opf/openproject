var examples = [
  {name: "pjBlack", hex:  "#000000"}, 
  {name: "pjRed", hex:  "#FF0013"}, 
  {name: "pjYellow", hex:   "#FEFE56"}, 
  {name: "pjLime", hex:   "#82FFA1"}, 
  {name: "pjAqua", hex:   "#C0DDFC"}, 
  {name: "pjBlue", hex:   "#1E16F4"}, 
  {name: "pjFuchsia", hex:  "#FF7FF7"}, 
  {name: "pjWhite", hex:  "#FFFFFF"}, 
  {name: "pjMaroon", hex:   "#850005"}, 
  {name: "pjGreen", hex:  "#008025"}, 
  {name: "pjOlive", hex:  "#7F8027"}, 
  {name: "pjNavy", hex:   "#09067A"}, 
  {name: "pjPurple", hex:   "#86007B"}, 
  {name: "pjTeal", hex:   "#008180"}, 
  {name: "pjGray", hex:   "#808080"}, 
  {name: "pjSilver", hex:   "#BFBFBF"}
];

Factory.define('Color', Timeline.Color)
  .sequence('id')
  .sequence('name', function (i) {return given[i] || "Color No. " + i;})
  .sequence('position')
  .sequence('hexcode', function (i) {return given[i] || "#000000";});