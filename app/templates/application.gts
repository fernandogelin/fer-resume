import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';
import ProfileCard from 'fer-resume/components/profile-card';
import SkillsSection from 'fer-resume/components/skills-section';
import LocaleSwitcher from 'fer-resume/components/locale-switcher';

<template>
  {{pageTitle "Fernando Gelin"}}

  <div class="grid grid-cols-1 md:grid-cols-[300px_1fr] gap-6 p-4 md:p-6 max-w-5xl mx-auto min-h-screen">
    <aside class="space-y-4">
      <LocaleSwitcher
        @isEN={{@controller.isEN}}
        @isPT={{@controller.isPT}}
        @onSwitch={{@controller.switchLocale}}
      />
      {{#if @model.basics}}
        <ProfileCard @person={{@model.basics}} />
      {{/if}}
      {{#if @model.skills}}
        <SkillsSection @skills={{@model.skills}} />
      {{/if}}
    </aside>
    <main>
      <nav class="flex gap-2 mb-6">
        <LinkTo
          @route="index"
          class="inline-flex items-center justify-center rounded-md text-sm font-medium px-4 py-2 bg-card border border-border hover:bg-muted transition-colors"
        >
          {{t "main.resume"}}
        </LinkTo>
        <LinkTo
          @route="projects"
          class="inline-flex items-center justify-center rounded-md text-sm font-medium px-4 py-2 bg-card border border-border hover:bg-muted transition-colors"
        >
          {{t "main.projects"}}
        </LinkTo>
      </nav>
      {{outlet}}
    </main>
  </div>
</template>
