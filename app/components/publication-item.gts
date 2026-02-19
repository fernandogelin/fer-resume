import type { TOC } from '@ember/component/template-only';
import type { Publication } from 'fer-resume/types/resume';
import Icon from 'fer-resume/components/icon';
import { ExternalLink } from 'lucide-static';

interface PublicationItemSignature {
  Args: {
    model: Publication;
  };
}

const PublicationItem: TOC<PublicationItemSignature> = <template>
  <div class="py-2">
    <p class="text-sm font-medium">
      {{#if @model.url}}
        <a
          href={{@model.url}}
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-start gap-1"
        >
          {{@model.title}}
          <Icon @svg={{ExternalLink}} @size={{12}} @class="mt-1 shrink-0" />
        </a>
      {{else}}
        {{@model.title}}
      {{/if}}
    </p>
    <p class="text-xs text-muted-foreground mt-1">
      {{@model.authors}}
    </p>
    <p class="text-xs text-muted-foreground italic">
      {{@model.journal}}, {{@model.year}}
    </p>
  </div>
</template>;

export default PublicationItem;
