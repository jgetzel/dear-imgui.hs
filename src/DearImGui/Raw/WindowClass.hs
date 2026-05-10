{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

{- |
Module: DearImGui.Raw.WindowClass

Allocator + accessors for @ImGuiWindowClass@ — used with
'DearImGui.Raw.Docking.setNextWindowClass' and 'DearImGui.Raw.Docking.dockSpace'
to influence docking compatibility and platform-window behavior.
-}
module DearImGui.Raw.WindowClass (
  WindowClass (..),
  new,
  destroy,

  -- * Field setters
  setClassId,
  setParentViewportId,
  setFocusRouteParentWindowId,
  setViewportFlagsOverrideSet,
  setViewportFlagsOverrideClear,
  setDockNodeFlagsOverrideSet,
  setDockingAlwaysTabBar,
  setDockingAllowUnclassed,
)
where

-- base
import Control.Monad.IO.Class (
  MonadIO,
  liftIO,
 )
import Foreign (
  Ptr,
 )
import Foreign.C (
  CBool,
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

-- | Wraps @ImGuiWindowClass*@.
newtype WindowClass = WindowClass (Ptr ImGuiWindowClass)

-- | Allocate a default-initialized @ImGuiWindowClass@. Pair with 'destroy'.
new :: (MonadIO m) => m WindowClass
new = liftIO do
  WindowClass
    <$> [C.block|
    ImGuiWindowClass* {
      return IM_NEW(ImGuiWindowClass);
    }
  |]

-- | Free a 'WindowClass' allocated with 'new'.
destroy :: (MonadIO m) => WindowClass -> m ()
destroy (WindowClass wc) = liftIO do
  [C.block|
    void {
      IM_DELETE($(ImGuiWindowClass* wc));
    }
  |]

{- | User-defined class id. @0@ is the default (unclassed). Windows of
  different classes cannot dock together.
-}
setClassId :: (MonadIO m) => WindowClass -> ImGuiID -> m ()
setClassId (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->ClassId = $(ImGuiID v); } |]

{- | Hint for the platform backend. @-1@ = use default, @0@ = no parent,
  non-zero = request parent/child relationship between platform windows.
-}
setParentViewportId :: (MonadIO m) => WindowClass -> ImGuiID -> m ()
setParentViewportId (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->ParentViewportId = $(ImGuiID v); } |]

setFocusRouteParentWindowId :: (MonadIO m) => WindowClass -> ImGuiID -> m ()
setFocusRouteParentWindowId (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->FocusRouteParentWindowId = $(ImGuiID v); } |]

setViewportFlagsOverrideSet :: (MonadIO m) => WindowClass -> ImGuiViewportFlags -> m ()
setViewportFlagsOverrideSet (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->ViewportFlagsOverrideSet = $(ImGuiViewportFlags v); } |]

setViewportFlagsOverrideClear :: (MonadIO m) => WindowClass -> ImGuiViewportFlags -> m ()
setViewportFlagsOverrideClear (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->ViewportFlagsOverrideClear = $(ImGuiViewportFlags v); } |]

setDockNodeFlagsOverrideSet :: (MonadIO m) => WindowClass -> ImGuiDockNodeFlags -> m ()
setDockNodeFlagsOverrideSet (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->DockNodeFlagsOverrideSet = $(ImGuiDockNodeFlags v); } |]

setDockingAlwaysTabBar :: (MonadIO m) => WindowClass -> CBool -> m ()
setDockingAlwaysTabBar (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->DockingAlwaysTabBar = $(bool v); } |]

setDockingAllowUnclassed :: (MonadIO m) => WindowClass -> CBool -> m ()
setDockingAllowUnclassed (WindowClass wc) v = liftIO do
  [C.block| void { $(ImGuiWindowClass* wc)->DockingAllowUnclassed = $(bool v); } |]
