import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';

interface IconSignature {
  Element: HTMLSpanElement;
  Args: {
    svg: string;
    size?: number;
    class?: string;
  };
}

export default class Icon extends Component<IconSignature> {
  renderIcon = modifier((element: HTMLSpanElement) => {
    const size = this.args.size ?? 18;
    element.innerHTML = this.args.svg
      .replace(/width="24"/g, `width="${size}"`)
      .replace(/height="24"/g, `height="${size}"`);
  });

  <template>
    <span
      class="inline-flex items-center shrink-0 {{@class}}"
      {{this.renderIcon}}
      ...attributes
    ></span>
  </template>
}
