import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import { createElement } from 'lucide';
import type { IconNode } from 'lucide';

interface IconSignature {
  Element: HTMLSpanElement;
  Args: {
    icon: IconNode;
    size?: number;
    class?: string;
  };
}

export default class Icon extends Component<IconSignature> {
  renderIcon = modifier((element: HTMLSpanElement) => {
    const size = this.args.size ?? 18;
    const svg = createElement(this.args.icon, {
      'width': size,
      'height': size,
      'stroke-width': 2,
    });
    element.innerHTML = '';
    element.appendChild(svg);
  });

  <template>
    <span
      class="inline-flex items-center shrink-0 {{@class}}"
      {{this.renderIcon}}
      ...attributes
    ></span>
  </template>
}
