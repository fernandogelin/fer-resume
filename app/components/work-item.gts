import type { TOC } from '@ember/component/template-only';
import type { WorkEntry } from 'fer-resume/types/resume';
import { Card, CardContent } from 'fer-resume/components/ui/card';
import DateRange from 'fer-resume/components/date-range';
import Icon from 'fer-resume/components/icon';
import { Building2, User, MapPin } from 'lucide-static';

interface WorkItemSignature {
  Args: {
    model: WorkEntry;
  };
}

const WorkItem: TOC<WorkItemSignature> = <template>
  <Card @class="shadow-none border-0 bg-transparent py-2">
    <CardContent @class="px-0">
      <h4 class="flex items-center gap-2 font-semibold text-sm">
        <Icon @svg={{Building2}} @size={{16}} @class="text-muted-foreground" />
        {{@model.company}}
      </h4>
      <p class="flex items-center gap-2 text-sm text-muted-foreground mt-1">
        <Icon @svg={{User}} @size={{16}} />
        {{@model.position}}
      </p>
      <div class="flex items-center gap-3 mt-1">
        <DateRange @startDate={{@model.startDate}} @endDate={{@model.endDate}} />
        <span class="flex items-center gap-1 text-xs text-muted-foreground">
          <Icon @svg={{MapPin}} @size={{14}} />
          {{@model.location}}
        </span>
      </div>
      <ul class="text-sm mt-2 space-y-1 list-disc list-inside">
        {{#each @model.highlights as |highlight|}}
          <li>{{highlight}}</li>
        {{/each}}
      </ul>
    </CardContent>
  </Card>
</template>;

export default WorkItem;
