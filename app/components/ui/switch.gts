import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { cn } from 'fer-resume/lib/utils';

interface SwitchSignature {
  Element: HTMLButtonElement;
  Args: {
    checked?: boolean;
    disabled?: boolean;
    class?: string;
    onCheckedChange?: (checked: boolean) => void;
  };
}

export default class Switch extends Component<SwitchSignature> {
  get checked(): boolean {
    return this.args.checked ?? false;
  }

  get classes(): string {
    return cn(
      'peer inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full border border-transparent transition-colors outline-none',
      'focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50',
      this.checked ? 'bg-primary' : 'bg-input',
      this.args.class,
    );
  }

  get thumbClasses(): string {
    return cn(
      'pointer-events-none block h-4 w-4 rounded-full bg-background shadow-sm ring-0 transition-transform',
      this.checked ? 'translate-x-4' : 'translate-x-0.5',
    );
  }

  @action
  toggle(): void {
    if (this.args.disabled) return;
    this.args.onCheckedChange?.(!this.checked);
  }

  <template>
    <button
      type='button'
      role='switch'
      aria-checked={{this.checked}}
      disabled={{@disabled}}
      class={{this.classes}}
      {{on 'click' this.toggle}}
      ...attributes
    >
      <span class={{this.thumbClasses}}></span>
    </button>
  </template>
}
