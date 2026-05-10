{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

{- |
Module: DearImGui.Raw.Viewport

Bindings for ImGui's viewport / multi-viewport API. The multi-viewport
features (UpdatePlatformWindows, RenderPlatformWindowsDefault) require
ImGui's @docking@ branch.
-}
module DearImGui.Raw.Viewport (
  -- * Lookup
  getMainViewport,
  getWindowViewport,
  findViewportByID,
  findViewportByPlatformHandle,
  setNextWindowViewport,

  -- * Multi-viewport rendering
  updatePlatformWindows,
  renderPlatformWindowsDefault,
  destroyPlatformWindows,

  -- * Viewport accessors
  viewportID,
  viewportFlags,
  viewportPos,
  viewportSize,
  viewportWorkPos,
  viewportWorkSize,
  viewportDpiScale,
  viewportParentViewportId,
  viewportPlatformHandle,
  viewportPlatformHandleRaw,
)
where

-- base
import Control.Monad.IO.Class (
  MonadIO,
  liftIO,
 )
import Foreign (
  Ptr,
  castPtr,
 )

-- dear-imgui
import DearImGui.Enums
import DearImGui.Raw.Context (
  imguiContext,
 )
import DearImGui.Structs

-- inline-c
import qualified Language.C.Inline as C

-- inline-c-cpp
import qualified Language.C.Inline.Cpp as Cpp

C.context (Cpp.cppCtx <> C.bsCtx <> imguiContext)
C.include "imgui.h"
Cpp.using "namespace ImGui"

-- | Wraps @ImGui::GetMainViewport()@. Returns the primary viewport, never null.
getMainViewport :: (MonadIO m) => m (Ptr ImGuiViewport)
getMainViewport = liftIO do
  [C.exp| ImGuiViewport* { GetMainViewport() } |]

{- | Wraps @ImGui::GetWindowViewport()@. Returns the viewport associated with
  the current window.
-}
getWindowViewport :: (MonadIO m) => m (Ptr ImGuiViewport)
getWindowViewport = liftIO do
  [C.exp| ImGuiViewport* { GetWindowViewport() } |]

-- | Wraps @ImGui::FindViewportByID()@.
findViewportByID :: (MonadIO m) => ImGuiID -> m (Ptr ImGuiViewport)
findViewportByID vid = liftIO do
  [C.exp| ImGuiViewport* { FindViewportByID($(ImGuiID vid)) } |]

-- | Wraps @ImGui::FindViewportByPlatformHandle()@.
findViewportByPlatformHandle :: (MonadIO m) => Ptr a -> m (Ptr ImGuiViewport)
findViewportByPlatformHandle handle = liftIO do
  let handle' = castPtr handle
  [C.exp| ImGuiViewport* { FindViewportByPlatformHandle($(void* handle')) } |]

-- | Wraps @ImGui::SetNextWindowViewport()@.
setNextWindowViewport :: (MonadIO m) => ImGuiID -> m ()
setNextWindowViewport vid = liftIO do
  [C.exp| void { SetNextWindowViewport($(ImGuiID vid)) } |]

{- | Call after @EndFrame@/@Render@ in your main loop. Creates, updates, and
  destroys platform windows for secondary viewports.

  Wraps @ImGui::UpdatePlatformWindows()@.
-}
updatePlatformWindows :: (MonadIO m) => m ()
updatePlatformWindows = liftIO do
  [C.exp| void { UpdatePlatformWindows() } |]

{- | Render and present each non-minimized secondary viewport. Pass 'Foreign.nullPtr'
  for both arguments unless you have custom platform/renderer args.

  Wraps @ImGui::RenderPlatformWindowsDefault()@.
-}
renderPlatformWindowsDefault :: (MonadIO m) => m ()
renderPlatformWindowsDefault = liftIO do
  [C.exp|
    void {
      RenderPlatformWindowsDefault(NULL, NULL)
    }
  |]

{- | Tear down platform windows for all viewports. Normally called automatically
  by 'DearImGui.Raw.destroyContext'; expose for early shutdown from backends.

  Wraps @ImGui::DestroyPlatformWindows()@.
-}
destroyPlatformWindows :: (MonadIO m) => m ()
destroyPlatformWindows = liftIO do
  [C.exp| void { DestroyPlatformWindows() } |]

--------------------------------------------------------------------------------
-- Viewport struct accessors

viewportID :: (MonadIO m) => Ptr ImGuiViewport -> m ImGuiID
viewportID vp = liftIO do
  [C.exp| ImGuiID { $(ImGuiViewport* vp)->ID } |]

viewportFlags :: (MonadIO m) => Ptr ImGuiViewport -> m ImGuiViewportFlags
viewportFlags vp = liftIO do
  [C.exp| ImGuiViewportFlags { $(ImGuiViewport* vp)->Flags } |]

viewportPos :: (MonadIO m) => Ptr ImGuiViewport -> Ptr ImVec2 -> m ()
viewportPos vp out = liftIO do
  [C.block|
    void {
      *$(ImVec2* out) = $(ImGuiViewport* vp)->Pos;
    }
  |]

viewportSize :: (MonadIO m) => Ptr ImGuiViewport -> Ptr ImVec2 -> m ()
viewportSize vp out = liftIO do
  [C.block|
    void {
      *$(ImVec2* out) = $(ImGuiViewport* vp)->Size;
    }
  |]

viewportWorkPos :: (MonadIO m) => Ptr ImGuiViewport -> Ptr ImVec2 -> m ()
viewportWorkPos vp out = liftIO do
  [C.block|
    void {
      *$(ImVec2* out) = $(ImGuiViewport* vp)->WorkPos;
    }
  |]

viewportWorkSize :: (MonadIO m) => Ptr ImGuiViewport -> Ptr ImVec2 -> m ()
viewportWorkSize vp out = liftIO do
  [C.block|
    void {
      *$(ImVec2* out) = $(ImGuiViewport* vp)->WorkSize;
    }
  |]

viewportDpiScale :: (MonadIO m) => Ptr ImGuiViewport -> m C.CFloat
viewportDpiScale vp = liftIO do
  [C.exp| float { $(ImGuiViewport* vp)->DpiScale } |]

viewportParentViewportId :: (MonadIO m) => Ptr ImGuiViewport -> m ImGuiID
viewportParentViewportId vp = liftIO do
  [C.exp| ImGuiID { $(ImGuiViewport* vp)->ParentViewportId } |]

-- | Higher-level platform handle (e.g. @SDL_WindowID@ for SDL, @HWND@ for Win32).
viewportPlatformHandle :: (MonadIO m) => Ptr ImGuiViewport -> m (Ptr ())
viewportPlatformHandle vp = liftIO do
  [C.exp| void* { $(ImGuiViewport* vp)->PlatformHandle } |]

{- | Lower-level native window handle (always @HWND@ on Win32, unused elsewhere).
  Returns 'Foreign.nullPtr' if unset.
-}
viewportPlatformHandleRaw :: (MonadIO m) => Ptr ImGuiViewport -> m (Ptr ())
viewportPlatformHandleRaw vp = liftIO do
  [C.exp| void* { $(ImGuiViewport* vp)->PlatformHandleRaw } |]
