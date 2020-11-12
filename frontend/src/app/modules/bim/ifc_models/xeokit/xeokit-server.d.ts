import {GonType} from "../../../common/gon/gon.service";

declare global {
  interface Window {
    gon:GonType;
  }
}