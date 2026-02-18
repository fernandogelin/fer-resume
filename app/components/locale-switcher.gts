import type { TOC } from '@ember/component/template-only';
import Icon from 'fer-resume/components/icon';
import { Globe as GlobeIcon } from 'lucide-static';
import { t } from 'ember-intl';
import { on } from '@ember/modifier';

interface LocaleSwitcherSignature {
  Args: {
    currentLocale: string;
    onSwitch: (event: Event) => void;
  };
}

const isSelected = (locale: string, current: string): boolean =>
  locale === current;

const LocaleSwitcher: TOC<LocaleSwitcherSignature> = <template>
  <div class="flex items-center gap-2">
    <Icon @svg={{GlobeIcon}} @size={{16}} @class="text-muted-foreground" />
    <select
      aria-label={{t "actions.choose_language"}}
      class="text-sm bg-card border border-border rounded-md px-2 py-1 focus:outline-none focus:ring-2 focus:ring-ring"
      {{on "change" @onSwitch}}
    >
      <option selected={{(isSelected "en-se" @currentLocale)}} value="en-se">{{t "locales.en-se"}}</option>
      <option selected={{(isSelected "pt-br" @currentLocale)}} value="pt-br">{{t "locales.pt-br"}}</option>
      <option selected={{(isSelected "es" @currentLocale)}} value="es">{{t "locales.es"}}</option>
      <option selected={{(isSelected "fr" @currentLocale)}} value="fr">{{t "locales.fr"}}</option>
    </select>
  </div>
</template>;

export default LocaleSwitcher;
