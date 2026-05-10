{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

{- |
Module: DearImGui.Raw.Docking

Bindings for ImGui's docking API (only available when building against
ImGui's @docking@ branch).
-}
module DearImGui.Raw.Docking (
  dockSpace,
  dockSpaceOverViewport,
  setNextWindowDockID,
  setNextWindowClass,
  getWindowDockID,
  isWindowDocked,
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

{- | Create an explicit dockspace node within the current window.

Wraps @ImGui::DockSpace()@.
-}
dockSpace ::
  (MonadIO m) =>
  ImGuiID ->
  Ptr ImVec2 ->
  ImGuiDockNodeFlags ->
  -- | Window class (pass 'Foreign.nullPtr' for default).
  Ptr ImGuiWindowClass ->
  m ImGuiID
dockSpace dockId sizePtr flags wc = liftIO do
  [C.exp|
    ImGuiID {
      DockSpace(
        $(ImGuiID dockId),
        *$(ImVec2* sizePtr),
        $(ImGuiDockNodeFlags flags),
        $(const ImGuiWindowClass* wc)
      )
    }
  |]

{- | Create an invisible dockspace covering an entire viewport.

Wraps @ImGui::DockSpaceOverViewport()@. Pass 'Foreign.nullPtr' for the
viewport pointer to use the main viewport.
-}
dockSpaceOverViewport ::
  (MonadIO m) =>
  ImGuiID ->
  Ptr ImGuiViewport ->
  ImGuiDockNodeFlags ->
  Ptr ImGuiWindowClass ->
  m ImGuiID
dockSpaceOverViewport dockId vp flags wc = liftIO do
  [C.exp|
    ImGuiID {
      DockSpaceOverViewport(
        $(ImGuiID dockId),
        $(const ImGuiViewport* vp),
        $(ImGuiDockNodeFlags flags),
        $(const ImGuiWindowClass* wc)
      )
    }
  |]

-- | Set the dock node id for the next window. Wraps @ImGui::SetNextWindowDockID()@.
setNextWindowDockID :: (MonadIO m) => ImGuiID -> ImGuiCond -> m ()
setNextWindowDockID dockId cond = liftIO do
  [C.exp| void { SetNextWindowDockID($(ImGuiID dockId), $(ImGuiCond cond)) } |]

-- | Set the window class for the next window. Wraps @ImGui::SetNextWindowClass()@.
setNextWindowClass :: (MonadIO m) => Ptr ImGuiWindowClass -> m ()
setNextWindowClass wc = liftIO do
  [C.exp| void { SetNextWindowClass($(const ImGuiWindowClass* wc)) } |]

{- | Get the dock node id of the current window, or @0@ if not docked.
  Wraps @ImGui::GetWindowDockID()@.
-}
getWindowDockID :: (MonadIO m) => m ImGuiID
getWindowDockID = liftIO do
  [C.exp| ImGuiID { GetWindowDockID() } |]

{- | Whether the current window is docked into another window.
  Wraps @ImGui::IsWindowDocked()@.
-}
isWindowDocked :: (MonadIO m) => m Bool
isWindowDocked = liftIO do
  (0 /=) <$> [C.exp| bool { IsWindowDocked() } |]
