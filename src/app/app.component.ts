import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ButtonDemo } from "./components/button/button.component";

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, ButtonDemo],
  templateUrl: './app.component.html',
  styleUrl: './app.component.less'
})
export class AppComponent {
  title = 'Samval-UI';
}
