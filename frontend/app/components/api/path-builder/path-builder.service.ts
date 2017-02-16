//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

import {opApiModule} from '../../../angular-modules';

class PathTemplate {
  /**
   * The template string of the path segment.
   */
  public template:string;
  /**
   * The children of the path segment.
   */
  public children:{ [childName: string]: any } = {};
  /**
   * The optional parents of the path segment.
   * Parents are only prepended to the path segment, if a parameter of the same name as the parent
   * is provided.
   */
  public parents:any = {};

  /**
   * Create the object while initialising its optional parents and children.
   *
   * @param config
   * @param parent
   */
  constructor(public config?:any, public parent?:PathTemplate) {
    var children:{[name:string]: PathTemplate};
    var parents:{[name:string]: PathTemplate};

    if (!Array.isArray(config)) {
      this.config = [config];
    }

    [this.template = '', children = {}, parents = {}] = this.config;

    angular.forEach(children, (childConfig, childName) => {
      this.children[childName] = new PathTemplate(childConfig, this);
    });

    angular.forEach(parents, (parentConfig, parentName:string) => {
      this.parents[parentName] = new PathTemplate(parentConfig, this.parent);
    });
  }

  /**
   * Return the path as a callable instance.
   * Children of the pathTemplate object are properties of the callable.
   *
   * @return {(params?:{})=>string}
   */
  public callable() {
    const callable = (params:any = {}) => {
      return URI.expand(this.build(params), params).valueOf();
    };

    angular.forEach(this.children, (child:any, childName:string) => {
      (callable as any)[childName] = child.callable();
    });

    return callable;
  }

  /**
   * Merge parent templates (if any) with the current template recursively.
   *
   * @param params
   * @return {string}
   */
  public build(params:any):string {
    var parent:PathTemplate|undefined;
    params = _.pickBy(params, (value:any) => !!value);

    Object.keys(params).forEach(name => {
      parent = this.parents[name];
    });

    parent = parent || this.parent;
    const parentTemplate:string = parent ? parent.build(params) + '/' : '';

    return parentTemplate + this.template;
  }
}

/**
 * Allows defining flexible paths using urijs.
 *
 * See the following links for more information on URITemplate and urijs.
 * uirjs: https://medialize.github.io/URI.js/docs.html
 * URITemplates: https://tools.ietf.org/html/rfc6570#section-2.1
 */
export class PathBuilderService {
  /**
   * Return a collection of callable paths.
   *
   * @see path
   * @param templates
   * @return A collection of callable paths
   */
  public buildPaths(templates:{[name:string]: any}) {
    const pathCollection:{[name:string]: any} = {};

    angular.forEach(templates, (config:any, name:string) => {
      pathCollection[name] = new PathTemplate(config).callable();
    });

    return pathCollection;
  }
}

opApiModule.service('pathBuilder', PathBuilderService);
