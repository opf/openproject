//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {performAnchorHijacking} from "./global-listeners/link-hijacking";
import {augmentedDatePicker} from "./global-listeners/augmented-date-picker";
import {refreshOnFormChanges} from 'core-app/globals/global-listeners/refresh-on-form-changes';
import {registerRequestForConfirmation} from "core-app/globals/global-listeners/request-for-confirmation";
import {DeviceService} from "core-app/modules/common/browser/device.service";
import {scrollHeaderOnMobile} from "core-app/globals/global-listeners/top-menu-scroll";

/**
 * A set of listeners that are relevant on every page to set sensible defaults
 */
(function($:JQueryStatic) {

  $(function() {
    $(document.documentElement!)
      .on('click', (evt:any) => {
        const target = jQuery(evt.target) as JQuery;

        // Create datepickers dynamically for Rails-based views
        augmentedDatePicker(evt, target);

        // Prevent angular handling clicks on href="#..." links from other libraries
        // (especially jquery-ui and its datepicker) from routing to <base url>/#
        performAnchorHijacking(evt, target);

        return true;
      });

    // Jump to the element given by location.hash, if present
    const hash = window.location.hash;
    if (hash && hash.startsWith('#')) {
      try {
        const el = document.querySelector(hash);
        el && el.scrollIntoView();
      } catch (e) {
        // This is very likely an invalid selector such as a Google Analytics tag.
        // We can safely ignore this and just not scroll in this case.
        // Still log the error so one can confirm the reason there is no scrolling.
        console.log("Could not scroll to given location hash: " + hash + " ( " + e.message + ")");
      }
    }

    // Global submitting hook,
    // necessary to avoid a data loss warning on beforeunload
    $(document).on('submit','form',function(){
      window.OpenProject.pageIsSubmitted = true;
    });

    // Add to content if warnings displayed
    if (document.querySelector('.warning-bar--item')) {
      let content = document.querySelector('#content') as HTMLElement;
      if (content) {
        content.style.marginBottom = '100px';
      }
    }

    // Global beforeunload hook
    $(window).on('beforeunload', (e:JQuery.TriggeredEvent) => {
      const event = e.originalEvent as BeforeUnloadEvent;
      if (window.OpenProject.pageWasEdited && !window.OpenProject.pageIsSubmitted) {
        // Cancel the event
        event.preventDefault();
        // Chrome requires returnValue to be set
        event.returnValue = '';
      }
    });

    // Disable global drag & drop handling, which results in the browser loading the image and losing the page
    $(document.documentElement!)
      .on('dragover drop', (evt:any) => {
        evt.preventDefault();
        return false;
      });

    refreshOnFormChanges();

    // Allow forms with [request-for-confirmation]
    // to show the password confirmation dialog
    registerRequestForConfirmation($);

    const deviceService:DeviceService = new DeviceService();
    // Register scroll handler on mobile header
    if (deviceService.isMobile) {
      scrollHeaderOnMobile();
    }
  });

}(jQuery));
