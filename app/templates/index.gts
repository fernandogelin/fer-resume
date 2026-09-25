import ProfileCard from 'fer-resume/components/profile-card';
import type { TOC } from '@ember/component/template-only';
import SkillsSection from 'fer-resume/components/skills-section';
import ResumeSection from 'fer-resume/components/resume-section';
import WorkItem from 'fer-resume/components/work-item';
import EducationItem from 'fer-resume/components/education-item';
import PublicationItem from 'fer-resume/components/publication-item';
import type { ResumeData } from 'fer-resume/types/resume';
import { Laptop, GraduationCap, BookOpen, Award } from 'lucide-static';

interface IndexTemplateSignature {
  Args: {
    model: ResumeData;
  };
}

const IndexTemplate: TOC<IndexTemplateSignature> = <template>
  <div
    class='resume-content grid grid-cols-1 md:grid-cols-[300px_1fr] gap-6 p-4 md:p-6 max-w-5xl mx-auto min-h-screen'
  >
    <aside class='space-y-4'>
      <ProfileCard @person={{@model.basics}} />
    </aside>
    <main>
      {{#if @model.basics.summary}}
        <p class='mb-6 text-sm leading-relaxed text-muted-foreground'>
          {{@model.basics.summary}}
        </p>
      {{/if}}
      <ResumeSection @titleKey='main.work' @icon={{Laptop}}>
        {{#each @model.work as |work|}}
          <WorkItem @model={{work}} />
        {{/each}}
      </ResumeSection>

      <ResumeSection @titleKey='main.education' @icon={{GraduationCap}}>
        {{#each @model.education as |education|}}
          <EducationItem @model={{education}} />
        {{/each}}
      </ResumeSection>

      <ResumeSection @titleKey='main.certifications' @icon={{Award}}>
        {{#each @model.certifications as |certification|}}
          <EducationItem @model={{certification}} />
        {{/each}}
      </ResumeSection>

      <ResumeSection @titleKey='main.publications' @icon={{BookOpen}}>
        {{#each @model.publications as |pub|}}
          <PublicationItem @model={{pub}} />
        {{/each}}
      </ResumeSection>
      <SkillsSection @skills={{@model.skills}} />
    </main>
  </div>
</template>;

export default IndexTemplate;
