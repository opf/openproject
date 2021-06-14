import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';
import { DebugElement } from '@angular/core';
import { By } from '@angular/platform-browser';
import { TileViewComponent } from './tile-view.component';
import { ImageHelpers } from "core-app/helpers/images/path-helper";
import imagePath = ImageHelpers.imagePath;

describe('shows tiles', () => {
  let app:TileViewComponent;
  let fixture:ComponentFixture<TileViewComponent>;
  let element:DebugElement;

  const tilesStub = [{
    attribute: 'basic',
    text: 'Basic board',
    icon: 'icon-boards',
    image: imagePath('board_creation_modal/lists.svg'),
    description: `Create a board in which you can freely
  create lists and order your work packages within.
  Moving work packages between lists do not change the work package itself.`
  }];

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
    const tile = document.querySelector('.tile-blocks--container');
    expect(document.contains(tile)).toBeTruthy();
  });

  it('should show each tile', () => {
    fixture.detectChanges();
    const tile:HTMLElement = element.query(By.css('.tile-block')).nativeElement;
    expect(tile.textContent).toContain('Basic');

  });

  it('should show the image', () => {
    fixture.detectChanges();
    const tile = document.querySelector('.tile-block-image');
    expect(document.contains(tile)).toBeTruthy();

  });
});