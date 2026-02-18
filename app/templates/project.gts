import { t } from 'ember-intl';

<template>
  <div>
    <h1 class="text-2xl font-bold mb-4">{{@model.name}} – {{t "main.preview"}}</h1>
    <video
      muted
      controls
      playsinline
      autoplay
      class="w-full rounded-lg border border-border"
    >
      <source src="/assets/media/{{@model.preview}}" type="video/mp4" />
    </video>
  </div>
  {{outlet}}
</template>
