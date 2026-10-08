{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

{- |
Module: DearImGui.Raw.Style

Read and write the current context's @ImGuiStyle@ directly, so a theme
can be set once instead of pushed every frame. Style vars are looked up
through @GetStyleVarInfo()@ from @imgui_internal.h@, the table
@PushStyleVar()@ uses.

Each call returns false, and touches nothing, when the var or color is
out of range or the var is of the other type.
-}
module DearImGui.Raw.Style (
  getStyleVar,
  setStyleVar,
  getStyleVarFloat,
  setStyleVarFloat,
  getStyleColor,
  setStyleColor,
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
  CBool (..),
  CFloat,
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

C.verbatim
  "static void* styleVarPtr(ImGuiStyleVar idx, unsigned count) {\n\
  \  if (idx < 0 || idx >= ImGuiStyleVar_COUNT) return NULL;\n\
  \  const ImGuiStyleVarInfo* info = ImGui::GetStyleVarInfo(idx);\n\
  \  if (info->DataType != ImGuiDataType_Float || info->Count != count) return NULL;\n\
  \  return info->GetVarPtr(&ImGui::GetStyle());\n\
  \}"

-- | Read an 'ImVec2' style var.
getStyleVar :: (MonadIO m) => ImGuiStyleVar -> Ptr ImVec2 -> m CBool
getStyleVar var out = liftIO do
  [C.block| bool {
    ImVec2* p = (ImVec2*)styleVarPtr($(ImGuiStyleVar var), 2);
    if (p) *$(ImVec2* out) = *p;
    return p != NULL;
  } |]

-- | Write an 'ImVec2' style var.
setStyleVar :: (MonadIO m) => ImGuiStyleVar -> Ptr ImVec2 -> m CBool
setStyleVar var val = liftIO do
  [C.block| bool {
    ImVec2* p = (ImVec2*)styleVarPtr($(ImGuiStyleVar var), 2);
    if (p) *p = *$(ImVec2* val);
    return p != NULL;
  } |]

-- | Read a float style var.
getStyleVarFloat :: (MonadIO m) => ImGuiStyleVar -> Ptr CFloat -> m CBool
getStyleVarFloat var out = liftIO do
  [C.block| bool {
    float* p = (float*)styleVarPtr($(ImGuiStyleVar var), 1);
    if (p) *$(float* out) = *p;
    return p != NULL;
  } |]

-- | Write a float style var.
setStyleVarFloat :: (MonadIO m) => ImGuiStyleVar -> CFloat -> m CBool
setStyleVarFloat var val = liftIO do
  [C.block| bool {
    float* p = (float*)styleVarPtr($(ImGuiStyleVar var), 1);
    if (p) *p = $(float val);
    return p != NULL;
  } |]

-- | Read a style color.
getStyleColor :: (MonadIO m) => ImGuiCol -> Ptr ImVec4 -> m CBool
getStyleColor col out = liftIO do
  [C.block| bool {
    ImGuiCol idx = $(ImGuiCol col);
    if (idx < 0 || idx >= ImGuiCol_COUNT) return false;
    *$(ImVec4* out) = GetStyle().Colors[idx];
    return true;
  } |]

-- | Write a style color.
setStyleColor :: (MonadIO m) => ImGuiCol -> Ptr ImVec4 -> m CBool
setStyleColor col val = liftIO do
  [C.block| bool {
    ImGuiCol idx = $(ImGuiCol col);
    if (idx < 0 || idx >= ImGuiCol_COUNT) return false;
    GetStyle().Colors[idx] = *$(ImVec4* val);
    return true;
  } |]
