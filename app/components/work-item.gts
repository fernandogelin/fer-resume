import type { TOC } from '@ember/component/template-only';
import type { WorkEntry } from 'fer-resume/types/resume';
import { Card, CardContent } from 'fer-resume/components/ui/card';
import DateRange from 'fer-resume/components/date-range';
import Icon from 'fer-resume/components/icon';
import { Building2, User } from 'lucide-static';

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
      <DateRange class="mt-1" @startDate={{@model.startDate}} @endDate={{@model.endDate}} />
      <p class="text-sm mt-2">{{@model.summary}}</p>
    </CardContent>
  </Card>
</template>;

export default WorkItem;
