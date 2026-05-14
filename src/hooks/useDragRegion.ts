import { invoke } from '@tauri-apps/api/core'
import { getCurrentWindow } from '@tauri-apps/api/window'
import { useCallback } from 'react'

const NO_DRAG_SELECTOR = [
  'button',
  'input',
  'select',
  'a',
  '[role="menu"]',
  '[role="menuitem"]',
  '[role="menuitemcheckbox"]',
  '[role="menuitemradio"]',
  '[data-no-drag]',
].join(', ')

function isDragDisabledTarget(target: EventTarget | null): boolean {
  return target instanceof Element && target.closest(NO_DRAG_SELECTOR) !== null
}

function performCurrentWindowTitlebarDoubleClick(): Promise<void> {
  return invoke<void>('perform_current_window_titlebar_double_click')
}

// Mobile WebViews have no draggable window — the desktop window-drag handler
// can interfere with synthetic touch->mouse event sequences, swallowing taps
// on buttons. Detect once at module load (UA is stable per WebView session).
const IS_MOBILE_WEBVIEW =
  typeof navigator !== 'undefined' &&
  /Android|iPhone|iPad|iPod/i.test(navigator.userAgent)

/**
 * Returns a mousedown handler that triggers Tauri window drag via startDragging().
 * More reliable than data-tauri-drag-region with titleBarStyle: Overlay in Tauri v2.
 *
 * On mobile platforms (Android/iOS), returns `undefined` so React doesn't attach
 * the handler at all — touch interactions reach buttons cleanly.
 */
export function useDragRegion() {
  const onMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button !== 0) return
    if (isDragDisabledTarget(e.target)) return
    e.preventDefault()
    if (e.detail === 2) {
      void performCurrentWindowTitlebarDoubleClick().catch(() => {})
      return
    }
    void getCurrentWindow().startDragging().catch(() => {})
  }, [])

  return { onMouseDown: IS_MOBILE_WEBVIEW ? undefined : onMouseDown }
}
