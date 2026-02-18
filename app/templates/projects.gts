import ProjectCard from 'fer-resume/components/project-card';

<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
    {{#each @model.projects as |project|}}
      <ProjectCard @project={{project}} />
    {{/each}}
  </div>
</template>
