<script setup lang="ts">
import { ref } from "vue";
import type { TreeNode } from "../composables/useFileTree";

withDefaults(defineProps<{
  nodes: TreeNode[];
  currentPath: string;
  selectedPath?: string;
  renamingPath?: string;
  depth?: number;
}>(), {
  selectedPath: "",
  renamingPath: "",
  depth: 0,
});

const emit = defineEmits<{
  (e: "open", path: string): void;
  (e: "select", path: string): void;
  (e: "context", event: MouseEvent, path: string): void;
  (e: "rename", path: string): void;
  (e: "submitRename", path: string, name: string): void;
  (e: "cancelRename"): void;
}>();

const collapsed = ref<Record<string, boolean>>({});

function toggle(key: string) {
  collapsed.value[key] = !collapsed.value[key];
}

function focusRenameInput(el: unknown) {
  if (!(el instanceof HTMLInputElement)) return;
  requestAnimationFrame(() => {
    el.focus();
    el.select();
  });
}

function submitRename(path: string, event: Event) {
  emit("submitRename", path, (event.target as HTMLInputElement).value);
}
</script>

<template>
  <ul class="tree" :class="{ root: !depth }">
    <li v-for="node in nodes" :key="node.path || node.name" class="tree-item">
      <template v-if="node.isDir">
        <div
          class="row dir"
          :style="{ paddingLeft: (depth || 0) * 12 + 8 + 'px' }"
          @click="toggle(node.name + ':' + (depth || 0))"
        >
          <span class="caret">
            {{ collapsed[node.name + ":" + (depth || 0)] ? "▶" : "▼" }}
          </span>
          <span class="name">{{ node.name }}</span>
        </div>
        <FileTree
          v-if="!collapsed[node.name + ':' + (depth || 0)] && node.children"
          :nodes="node.children"
          :current-path="currentPath"
          :selected-path="selectedPath"
          :renaming-path="renamingPath"
          :depth="(depth || 0) + 1"
          @open="(p) => emit('open', p)"
          @select="(p) => emit('select', p)"
          @context="(event, p) => emit('context', event, p)"
          @rename="(p) => emit('rename', p)"
          @submit-rename="(p, name) => emit('submitRename', p, name)"
          @cancel-rename="emit('cancelRename')"
        />
      </template>
      <template v-else>
        <div
          class="row file"
          :class="{ active: currentPath === node.path, selected: selectedPath === node.path }"
          :style="{ paddingLeft: (depth || 0) * 12 + 22 + 'px' }"
          :title="node.path"
          role="button"
          tabindex="0"
          @focus="emit('select', node.path)"
          @click="emit('select', node.path); emit('open', node.path)"
          @contextmenu.prevent.stop="emit('context', $event, node.path)"
          @keydown.enter.prevent="emit('open', node.path)"
          @keydown.f2.prevent.stop="emit('rename', node.path)"
        >
          <input
            v-if="renamingPath === node.path"
            :ref="focusRenameInput"
            class="rename-input"
            :value="node.name"
            @click.stop
            @mousedown.stop
            @keydown.enter.prevent.stop="submitRename(node.path, $event)"
            @keydown.esc.prevent.stop="emit('cancelRename')"
            @keydown.stop
            @blur="submitRename(node.path, $event)"
          />
          <span v-else class="name">{{ node.name }}</span>
        </div>
      </template>
    </li>
  </ul>
</template>

<style scoped>
.tree {
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: 13px;
}
.tree.root {
  padding: 4px 0;
}
.row {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px 3px 8px;
  cursor: pointer;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: var(--tree-row-color);
  user-select: none;
}
.row:hover {
  background: var(--tree-row-hover-bg);
}
.row.active {
  background: var(--tree-row-active-bg);
  color: var(--tree-row-active-color);
  box-shadow: var(--tree-row-active-shadow);
}
.row.selected:not(.active) {
  background: var(--tree-row-hover-bg);
}
.caret {
  font-size: 10px;
  color: var(--tree-caret-color);
  width: 12px;
  display: inline-block;
}
.dir .name {
  font-weight: 500;
  color: var(--tree-dir-color);
}
.file .name {
  color: var(--tree-file-color);
}
.row.active .name {
  color: var(--tree-row-active-color);
}
.name {
  overflow: hidden;
  text-overflow: ellipsis;
}
.rename-input {
  width: 100%;
  min-width: 0;
  height: 22px;
  padding: 0 6px;
  border: 1px solid var(--link);
  border-radius: 5px;
  outline: none;
  background: var(--bg);
  color: var(--fg);
  font: inherit;
}
</style>
