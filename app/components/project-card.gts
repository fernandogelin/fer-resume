import type { TOC } from '@ember/component/template-only';
import type { Project } from 'fer-resume/types/resume';
import { Card, CardContent, CardHeader, CardTitle } from 'fer-resume/components/ui/card';
import { Badge } from 'fer-resume/components/ui/badge';
import Icon from 'fer-resume/components/icon';
import { Github, ExternalLink, MonitorPlay } from 'lucide';
import { t } from 'ember-intl';
import { LinkTo } from '@ember/routing';

interface ProjectCardSignature {
  Args: {
    project: Project;
  };
}

const ProjectCard: TOC<ProjectCardSignature> = <template>
  <Card>
    <CardHeader>
      <CardTitle>{{@project.name}}</CardTitle>
    </CardHeader>
    <CardContent>
      <div class="flex flex-wrap gap-1 mb-3">
        {{#each @project.labels as |label|}}
          <Badge @variant="secondary" @class="text-xs">{{label}}</Badge>
        {{/each}}
      </div>
      <p class="text-sm mb-3">{{@project.description}}</p>
      <div class="flex flex-col gap-2">
        {{#if @project.repo}}
          <a
            href={{@project.repo}}
            class="flex items-center gap-2 text-sm"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Icon @icon={{Github}} @size={{16}} />
            {{t "actions.go_to_github_repo"}}
          </a>
        {{/if}}
        {{#if @project.url}}
          <a
            href={{@project.url}}
            class="flex items-center gap-2 text-sm"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Icon @icon={{ExternalLink}} @size={{16}} />
            {{t "actions.view_site"}}
          </a>
        {{/if}}
        {{#if @project.preview}}
          <LinkTo @route="project" @model={{@project.id}} class="flex items-center gap-2 text-sm">
            <Icon @icon={{MonitorPlay}} @size={{16}} />
            {{t "main.preview"}}
          </LinkTo>
        {{/if}}
      </div>
    </CardContent>
  </Card>
</template>;

export default ProjectCard;
