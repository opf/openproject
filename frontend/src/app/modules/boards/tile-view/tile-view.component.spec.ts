import { ComponentFixture, TestBed, async } from '@angular/core/testing';
import { DebugElement } from '@angular/core';
import { By } from '@angular/platform-browser';
import { TileViewComponent } from './tile-view.component';

fdescribe('shows tiles', () => {
  let app:TileViewComponent;
  let fixture:ComponentFixture<TileViewComponent>;
  let element:DebugElement;

  let tilesStub = [{attribute:'basic', text:'Basic board',
  icon:'icon-boards', description: `Create a board in which you can freely
  create lists and order your work packages within.
  Moving work packages between lists do not change the work package itself.`}];

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [
        TileViewComponent],
      providers: [],
    }).compileComponents();

    fixture = TestBed.createComponent(TileViewComponent);
    app = fixture.debugElement.componentInstance;
    app.tiles = tilesStub;
    element = fixture.debugElement;
  });

  it('should render the componenet successfully', () => {
    fixture.detectChanges();
      let tile = document.querySelector('.tile-blocks--container');
      expect(document.contains(tile)).toBeTruthy();
  });

  it('should show each tile', () => {
    fixture.detectChanges();
      let tile:HTMLElement = element.query(By.css('.tile-block')).nativeElement;
      expect(tile.innerText).toContain('Basic board');

  });

  it('should show the icon', () => {
    fixture.detectChanges();
      let tile = document.querySelector('.tile-block--icon');
      expect(document.contains(tile)).toBeTruthy();

  });
});