import type { TOC } from '@ember/component/template-only';
import Icon from 'fer-resume/components/icon';
import { Globe } from 'lucide';
import { t } from 'ember-intl';
import { on } from '@ember/modifier';

interface LocaleSwitcherSignature {
  Args: {
    isEN: boolean;
    isPT: boolean;
    onSwitch: (event: Event) => void;
  };
}

const LocaleSwitcher: TOC<LocaleSwitcherSignature> = <template>
  <div class="flex items-center gap-2 mb-4">
    <Icon @icon={{Globe}} @size={{16}} @class="text-muted-foreground" />
    <select
      aria-label={{t "actions.choose_language"}}
      class="text-sm bg-card border border-border rounded-md px-2 py-1 focus:outline-none focus:ring-2 focus:ring-ring"
      {{on "change" @onSwitch}}
    >
      <option selected={{@isEN}} value="en-se">{{t "locales.en-se"}}</option>
      <option selected={{@isPT}} value="pt-br">{{t "locales.pt-br"}}</option>
    </select>
  </div>
</template>;

export default LocaleSwitcher;
