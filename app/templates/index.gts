import ResumeSection from 'fer-resume/components/resume-section';
import WorkItem from 'fer-resume/components/work-item';
import EducationItem from 'fer-resume/components/education-item';
import PublicationItem from 'fer-resume/components/publication-item';
import { Laptop, GraduationCap, BookOpen } from 'lucide-static';

<template>
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

  <ResumeSection @titleKey="main.publications" @icon={{BookOpen}}>
    {{#each @model.publications as |pub|}}
      <PublicationItem @model={{pub}} />
    {{/each}}
  </ResumeSection>
</template>
