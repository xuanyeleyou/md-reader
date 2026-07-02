<script setup lang="ts">
import { ref, watch, nextTick } from "vue";

export interface ContextMenuItem {
  label: string;
  shortcut?: string;
  disabled?: boolean;
  divider?: boolean;
  action?: () => void;
}

const props = withDefaults(defineProps<{
  visible: boolean;
  x: number;
  y: number;
  items: ContextMenuItem[];
  width?: number;
}>(), {
  width: 180,
});

const emit = defineEmits<{
  (e: "close"): void;
}>();

const menuRef = ref<HTMLElement | null>(null);

function positionMenu() {
  if (!menuRef.value || !props.visible) return;
  const menu = menuRef.value;
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const mw = props.width;
  const mh = menu.offsetHeight || 200;
  const margin = 4;
  let left = props.x;
  let top = props.y;
  if (left + mw > vw - margin) left = vw - mw - margin;
  if (top + mh > vh - margin) top = vh - mh - margin;
  if (left < margin) left = margin;
  if (top < margin) top = margin;
  menu.style.left = left + "px";
  menu.style.top = top + "px";
}

watch(() => props.visible, (v) => {
  if (v) nextTick(positionMenu);
});

function onItemClick(item: ContextMenuItem) {
  if (item.disabled || item.divider) return;
  item.action?.();
  emit("close");
}

function onBackdropClick() {
  emit("close");
}
</script>

<template>
  <Teleport to="body">
    <div v-if="visible" class="context-backdrop" @click="onBackdropClick" @contextmenu.prevent="onBackdropClick" />
    <div
      v-if="visible"
      ref="menuRef"
      class="context-menu"
      :style="{ width: width + 'px' }"
    >
      <template v-for="(item, i) in items" :key="i">
        <div v-if="item.divider" class="context-divider" />
        <div
          v-else
          class="context-item"
          :class="{ disabled: item.disabled }"
          @click="onItemClick(item)"
        >
          <span class="context-label">{{ item.label }}</span>
          <span v-if="item.shortcut" class="context-shortcut">{{ item.shortcut }}</span>
        </div>
      </template>
    </div>
  </Teleport>
</template>

<style scoped>
.context-backdrop {
  position: fixed;
  inset: 0;
  z-index: 9998;
}
.context-menu {
  position: fixed;
  z-index: 9999;
  background: var(--shell-export-bg);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 4px 0;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
  font-size: 13px;
  overflow: hidden;
}
.context-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 14px;
  cursor: pointer;
  color: var(--fg);
  gap: 12px;
}
.context-item:hover {
  background: var(--shell-export-hover-bg);
}
.context-item.disabled {
  opacity: 0.4;
  pointer-events: none;
}
.context-divider {
  height: 1px;
  margin: 4px 8px;
  background: var(--border);
}
.context-shortcut {
  font-size: 11px;
  color: var(--fg-muted, #999);
  flex-shrink: 0;
}
</style>
