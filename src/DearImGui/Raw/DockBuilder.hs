{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

{- |
Module: DearImGui.Raw.DockBuilder

Bindings for the @DockBuilder*@ family used to set up dock layouts
programmatically. These live in @imgui_internal.h@ — the API is
considered work-in-progress upstream and may change between ImGui
versions.
-}
module DearImGui.Raw.DockBuilder (
  dockBuilderDockWindow,
  dockBuilderGetNode,
  dockBuilderAddNode,
  dockBuilderRemoveNode,
  dockBuilderRemoveNodeDockedWindows,
  dockBuilderRemoveNodeChildNodes,
  dockBuilderSetNodePos,
  dockBuilderSetNodeSize,
  dockBuilderSplitNode,
  dockBuilderFinish,
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
  CFloat,
  CString,
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
C.include "imgui_internal.h"
Cpp.using "namespace ImGui"

-- | Wraps @ImGui::DockBuilderDockWindow()@.
dockBuilderDockWindow :: (MonadIO m) => CString -> ImGuiID -> m ()
dockBuilderDockWindow name nodeId = liftIO do
  [C.exp| void { DockBuilderDockWindow($(char* name), $(ImGuiID nodeId)) } |]

{- | Wraps @ImGui::DockBuilderGetNode()@. Returns 'Foreign.nullPtr' if not found.

  Do not retain the returned pointer across frames — nodes can be invalidated
  by any split/merge/remove operation.
-}
dockBuilderGetNode :: (MonadIO m) => ImGuiID -> m (Ptr ImGuiDockNode)
dockBuilderGetNode nodeId = liftIO do
  [C.exp| ImGuiDockNode* { DockBuilderGetNode($(ImGuiID nodeId)) } |]

{- | Wraps @ImGui::DockBuilderAddNode()@. Pass @0@ for @nodeId@ to allocate
  a new id.
-}
dockBuilderAddNode :: (MonadIO m) => ImGuiID -> ImGuiDockNodeFlags -> m ImGuiID
dockBuilderAddNode nodeId flags = liftIO do
  [C.exp| ImGuiID { DockBuilderAddNode($(ImGuiID nodeId), $(ImGuiDockNodeFlags flags)) } |]

{- | Wraps @ImGui::DockBuilderRemoveNode()@. Removes the node and all its
  children; docked windows become floating.
-}
dockBuilderRemoveNode :: (MonadIO m) => ImGuiID -> m ()
dockBuilderRemoveNode nodeId = liftIO do
  [C.exp| void { DockBuilderRemoveNode($(ImGuiID nodeId)) } |]

-- | Wraps @ImGui::DockBuilderRemoveNodeDockedWindows()@.
dockBuilderRemoveNodeDockedWindows :: (MonadIO m) => ImGuiID -> CBool -> m ()
dockBuilderRemoveNodeDockedWindows nodeId clearSettings = liftIO do
  [C.exp|
    void {
      DockBuilderRemoveNodeDockedWindows(
        $(ImGuiID nodeId),
        $(bool clearSettings)
      )
    }
  |]

{- | Wraps @ImGui::DockBuilderRemoveNodeChildNodes()@. Removes all splits;
  docked windows are re-docked to the remaining root.
-}
dockBuilderRemoveNodeChildNodes :: (MonadIO m) => ImGuiID -> m ()
dockBuilderRemoveNodeChildNodes nodeId = liftIO do
  [C.exp| void { DockBuilderRemoveNodeChildNodes($(ImGuiID nodeId)) } |]

-- | Wraps @ImGui::DockBuilderSetNodePos()@.
dockBuilderSetNodePos :: (MonadIO m) => ImGuiID -> Ptr ImVec2 -> m ()
dockBuilderSetNodePos nodeId posPtr = liftIO do
  [C.exp| void { DockBuilderSetNodePos($(ImGuiID nodeId), *$(ImVec2* posPtr)) } |]

{- | Wraps @ImGui::DockBuilderSetNodeSize()@. Call before splitting if you
  intend to split immediately after creation, otherwise split sizes may
  be unreliable.
-}
dockBuilderSetNodeSize :: (MonadIO m) => ImGuiID -> Ptr ImVec2 -> m ()
dockBuilderSetNodeSize nodeId sizePtr = liftIO do
  [C.exp| void { DockBuilderSetNodeSize($(ImGuiID nodeId), *$(ImVec2* sizePtr)) } |]

{- | Wraps @ImGui::DockBuilderSplitNode()@. Splits @nodeId@ into two children
  along @splitDir@ at @sizeRatio@. Writes the @id-at-dir@ and
  @id-at-opposite-dir@ into the provided pointers (either may be 'Foreign.nullPtr'
  to skip). Returns the original (now-parent) node id.
-}
dockBuilderSplitNode ::
  (MonadIO m) =>
  ImGuiID ->
  ImGuiDir ->
  CFloat ->
  Ptr ImGuiID ->
  Ptr ImGuiID ->
  m ImGuiID
dockBuilderSplitNode nodeId splitDir sizeRatio outAtDir outOpposite = liftIO do
  [C.exp|
    ImGuiID {
      DockBuilderSplitNode(
        $(ImGuiID nodeId),
        $(ImGuiDir splitDir),
        $(float sizeRatio),
        $(ImGuiID* outAtDir),
        $(ImGuiID* outOpposite)
      )
    }
  |]

-- | Wraps @ImGui::DockBuilderFinish()@. Call after building the layout.
dockBuilderFinish :: (MonadIO m) => ImGuiID -> m ()
dockBuilderFinish nodeId = liftIO do
  [C.exp| void { DockBuilderFinish($(ImGuiID nodeId)) } |]
