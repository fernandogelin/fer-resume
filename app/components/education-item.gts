import type { TOC } from '@ember/component/template-only';
import type { EducationEntry } from 'fer-resume/types/resume';
import { Card, CardContent } from 'fer-resume/components/ui/card';
import DateRange from 'fer-resume/components/date-range';
import Icon from 'fer-resume/components/icon';
import { School, Award, BookOpen } from 'lucide';
import { t } from 'ember-intl';

interface EducationItemSignature {
  Args: {
    model: EducationEntry;
  };
}

const EducationItem: TOC<EducationItemSignature> = <template>
  <Card @class="shadow-none border-0 bg-transparent py-2">
    <CardContent @class="px-0">
      <h4 class="flex items-center gap-2 font-semibold text-sm">
        <Icon @icon={{School}} @size={{16}} @class="text-muted-foreground" />
        {{@model.institution}}
      </h4>
      <p class="flex items-center gap-2 text-sm text-muted-foreground mt-1">
        <Icon @icon={{Award}} @size={{16}} />
        {{@model.area}}, {{@model.studyType}}
      </p>
      <DateRange class="mt-1" @startDate={{@model.startDate}} @endDate={{@model.endDate}} />
      {{#if @model.thesis}}
        <p class="flex items-center gap-2 text-sm mt-2">
          <Icon @icon={{BookOpen}} @size={{16}} @class="text-muted-foreground" />
          {{t "thesis"}}: {{@model.thesis}}
        </p>
      {{/if}}
    </CardContent>
  </Card>
</template>;

export default EducationItem;
