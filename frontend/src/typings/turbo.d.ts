export interface TurboElement {
  reload:() => void;
}

export interface TurboStreamElement extends HTMLElement {
  action:string;
  target:string;
}
