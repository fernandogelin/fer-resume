import type { TOC } from '@ember/component/template-only';
import type { Skill } from 'fer-resume/types/resume';
import { t } from 'ember-intl';

interface SkillsSectionSignature {
  Args: {
    skills: Skill[];
  };
}

const SkillsSection: TOC<SkillsSectionSignature> = <template>
  <section class="mb-8 border-t pt-4">
    <h2 class="text-sm font-semibold mb-3">{{t "main.skills"}}</h2>
    <dl class="space-y-2 text-sm text-muted-foreground">
      {{#each @skills as |skill|}}
        <div>
          <dt class="inline font-medium">{{skill.name}}: </dt>
          <dd class="inline">
            {{#each skill.keywords as |keyword index|}}{{#if index}}, {{/if}}{{keyword}}{{/each}}
          </dd>
        </div>
      {{/each}}
    </dl>
  </section>
</template>;

export default SkillsSection;
