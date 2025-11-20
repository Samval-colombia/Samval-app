import { Component } from '@angular/core';

@Component({
  selector: 'button-demo',
  standalone: true,
  template: `
    <button class="button-demo" type="button">
      Demo Button
    </button>
  `,
  styleUrl: './button.component.less',
})
export class ButtonDemo {}
