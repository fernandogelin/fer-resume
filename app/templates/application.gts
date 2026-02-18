import { pageTitle } from 'ember-page-title';
import ProfileCard from 'fer-resume/components/profile-card';
import SkillsSection from 'fer-resume/components/skills-section';
import LocaleSwitcher from 'fer-resume/components/locale-switcher';

<template>
  {{pageTitle "Fernando Gelin"}}

  <div class="grid grid-cols-1 md:grid-cols-[300px_1fr] gap-6 p-4 md:p-6 max-w-5xl mx-auto min-h-screen">
    <aside class="space-y-4">
      <ProfileCard @person={{@model.basics}} />
      <SkillsSection @skills={{@model.skills}} />
      <LocaleSwitcher
        @currentLocale={{@controller.currentLocale}}
        @onSwitch={{@controller.switchLocale}}
      />
    </aside>
    <main>
      {{outlet}}
    </main>
  </div>
</template>
