import type { TOC } from '@ember/component/template-only';
import Icon from 'fer-resume/components/icon';
import { Separator } from 'fer-resume/components/ui/separator';
import { t } from 'ember-intl';
import type { IconNode } from 'lucide';

interface ResumeSectionSignature {
  Args: {
    titleKey: string;
    icon: IconNode;
  };
  Blocks: {
    default: [];
  };
}

const ResumeSection: TOC<ResumeSectionSignature> = <template>
  <section class="mb-8">
    <div class="flex items-center gap-2 mb-4">
      <Icon @icon={{@icon}} @size={{22}} @class="text-primary" />
      <h2 class="text-lg font-semibold">{{t @titleKey}}</h2>
    </div>
    <Separator @class="mb-4" />
    <div class="space-y-4">
      {{yield}}
    </div>
  </section>
</template>;

export default ResumeSection;
