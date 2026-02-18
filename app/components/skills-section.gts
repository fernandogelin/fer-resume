import type { TOC } from '@ember/component/template-only';
import type { Skill } from 'fer-resume/types/resume';
import { Card, CardContent, CardHeader, CardTitle } from 'fer-resume/components/ui/card';
import { Badge } from 'fer-resume/components/ui/badge';
import { t } from 'ember-intl';

interface SkillsSectionSignature {
  Args: {
    skills: Skill[];
  };
}

const SkillsSection: TOC<SkillsSectionSignature> = <template>
  <Card>
    <CardHeader>
      <CardTitle>{{t "main.skills"}}</CardTitle>
    </CardHeader>
    <CardContent>
      <div class="space-y-3">
        {{#each @skills as |skill|}}
          <div>
            <p class="text-sm font-medium mb-1">{{skill.name}}</p>
            <div class="flex flex-wrap gap-1">
              {{#each skill.keywords as |keyword|}}
                <Badge @variant="outline" @class="text-xs">{{keyword}}</Badge>
              {{/each}}
            </div>
          </div>
        {{/each}}
      </div>
    </CardContent>
  </Card>
</template>;

export default SkillsSection;
