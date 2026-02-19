import Component from '@glimmer/component';
import { type Registry as Services, service } from '@ember/service';
import Icon from 'fer-resume/components/icon';
import { Clock } from 'lucide-static';
import { t } from 'ember-intl';

interface DateRangeSignature {
  Element: HTMLSpanElement;
  Args: {
    startDate: string;
    endDate: string | null;
  };
}

export default class DateRange extends Component<DateRangeSignature> {
  @service declare intl: Services['intl'];

  get start(): string {
    return new Intl.DateTimeFormat(this.intl.primaryLocale, {
      year: 'numeric',
      month: 'short',
    }).format(new Date(this.args.startDate));
  }

  get end(): string {
    if (this.args.endDate) {
      return new Intl.DateTimeFormat(this.intl.primaryLocale, {
        year: 'numeric',
        month: 'short',
      }).format(new Date(this.args.endDate));
    }
    return this.intl.t('time.present') as unknown as string;
  }

  <template>
    <span class="flex items-center gap-1 text-xs text-muted-foreground" ...attributes>
      <Icon @svg={{Clock}} @size={{14}} />
      {{this.start}} – {{this.end}}
    </span>
  </template>
}
