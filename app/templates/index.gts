import ResumeSection from 'fer-resume/components/resume-section';
import WorkItem from 'fer-resume/components/work-item';
import EducationItem from 'fer-resume/components/education-item';
import Icon from 'fer-resume/components/icon';
import { FileDown, Laptop, GraduationCap } from 'lucide-static';
import { t } from 'ember-intl';

<template>
  <div class="mb-6">
    <a
      href="assets/pdf/fernando-gelin-senior-software-engineer-resume.pdf"
      download
      class="inline-flex items-center gap-2 text-sm font-medium text-primary hover:text-primary/80 transition-colors"
    >
      <Icon @svg={{FileDown}} @size={{18}} />
      {{t "actions.download"}}
    </a>
  </div>

  <ResumeSection @titleKey="main.work" @icon={{Laptop}}>
    {{#each @model.work as |work|}}
      <WorkItem @model={{work}} />
    {{/each}}
  </ResumeSection>

  <ResumeSection @titleKey="main.education" @icon={{GraduationCap}}>
    {{#each @model.education as |education|}}
      <EducationItem @model={{education}} />
    {{/each}}
  </ResumeSection>
</template>
