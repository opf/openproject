/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import {Controller} from '@hotwired/stimulus';
import {createRoot} from 'react-dom/client';
import {Box, Button, SelectPanel, ThemeProvider} from '@primer/react';
import React from 'react';

export default class TestButtonController extends Controller {
  static targets = [
    'root',
  ];

  declare readonly rootTarget: HTMLElement;

  connect() {
    const root = createRoot(this.rootTarget);
    root.render(this.buttonTest());
    // root.render(this.selectPanelTest());
  }

  buttonTest() {
    return (
      <ThemeProvider>
        <Box m={2}>
          <Button size="small">Search</Button>
        </Box>
      </ThemeProvider>
    )
  }

  selectPanelTest() {
      const items = [{text: 'Item 1', id: 1}, {text: 'Item 2', id: 2}];
      let open = true;
      const onOpenChange = (o:boolean, gesture:string) => {
          console.log(o);
          console.log(gesture);
          open = !open;
      };

      return (
      <ThemeProvider>
        <Box m={2}>
          <SelectPanel
            onFilterChange={() => {}}
            items={items}
            open={open}
            onOpenChange={onOpenChange}
            selected={items[0]}
            onSelectedChange={() => {}}
          ></SelectPanel>
        </Box>
      </ThemeProvider>
    )
  }

  selectPanelTest2() {
    function getColorCircle(color: string) {
      return function () {
        return (
          <Box
            borderWidth="1px"
            borderStyle="solid"
            bg={color}
            borderColor={color}
            width={14}
            height={14}
            borderRadius={10}
            margin="auto"
          />
        )
      }
    }

    const items = [
      {leadingVisual: getColorCircle('#a2eeef'), text: 'enhancement', id: 1},
      {leadingVisual: getColorCircle('#d73a4a'), text: 'bug', id: 2},
      {leadingVisual: getColorCircle('#0cf478'), text: 'good first issue', id: 3},
      {leadingVisual: getColorCircle('#ffd78e'), text: 'design', id: 4},
      {leadingVisual: getColorCircle('#ff0000'), text: 'blocker', id: 5},
      {leadingVisual: getColorCircle('#a4f287'), text: 'backend', id: 6},
      {leadingVisual: getColorCircle('#8dc6fc'), text: 'frontend', id: 7},
    ]

    const [selected, _] = React.useState([items[0], items[1]])
    const [filter, setFilter] = React.useState('')
    const filteredItems = items.filter(item => item.text.toLowerCase().startsWith(filter.toLowerCase()))
    const [open, setOpen] = React.useState(false)

    return (
      <ThemeProvider>
        <SelectPanel
          renderAnchor={({children, 'aria-labelledby': ariaLabelledBy, ...anchorProps}) => (
            <Button aria-labelledby={` ${ariaLabelledBy}`} {...anchorProps}>
              {children || 'Select Labels'}
            </Button>
          )}
          placeholderText="Filter Labels"
          open={open}
          onOpenChange={setOpen}
          items={filteredItems}
          selected={selected}
          onSelectedChange={() => {
          }}
          onFilterChange={setFilter}
          showItemDividers={true}
          overlayProps={{width: 'small', height: 'xsmall'}}
        ></SelectPanel>
      </ThemeProvider>
    )
  }
}
