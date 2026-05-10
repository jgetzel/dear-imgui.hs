{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module: DearImGui.Docking

High-level helpers for the docking and multi-viewport API. These wrap
'DearImGui.Raw.Docking', 'DearImGui.Raw.Viewport', and
'DearImGui.Raw.WindowClass' with bracketed allocators and value-style
ImVec2 marshalling.

Requires building dear-imgui against ImGui's @docking@ branch.
-}
module DearImGui.Docking (
  -- * Dock space
  dockSpace,
  dockSpaceOverMainViewport,
  dockSpaceOverViewport,
  setNextWindowDockID,

  -- * Window class
  withWindowClass,

  -- * Viewport queries
  getMainViewportSize,
  getMainViewportWorkSize,
  getMainViewportPos,
  getMainViewportWorkPos,

  -- * Re-exports of raw helpers that don't need wrapping
  Raw.getWindowDockID,
  Raw.isWindowDocked,
  Raw.setNextWindowClass,
)
where

-- base
import Control.Monad.IO.Class (
  MonadIO,
  liftIO,
 )
import Foreign (
  Ptr,
  alloca,
  nullPtr,
  peek,
  with,
 )

-- unliftio
import UnliftIO (
  MonadUnliftIO,
 )
import UnliftIO.Exception (
  bracket,
 )

-- dear-imgui
import DearImGui.Enums
import qualified DearImGui.Raw.Docking as Raw
import qualified DearImGui.Raw.Viewport as Viewport
import qualified DearImGui.Raw.WindowClass as WC
import DearImGui.Structs

{- | Submit a docking node into the current window. Wraps 'Raw.dockSpace'
  with stack-allocated 'ImVec2' and a defaulted (null) 'WC.WindowClass'.
  Pass an 'ImVec2' of @(0, 0)@ to fill the available area.
-}
dockSpace :: (MonadIO m) => ImGuiID -> ImVec2 -> ImGuiDockNodeFlags -> m ImGuiID
dockSpace dockId size flags = liftIO do
  with size \sizePtr ->
    Raw.dockSpace dockId sizePtr flags nullPtr

{- | Submit a dock space covering the given viewport. Use
  'dockSpaceOverMainViewport' for the main-viewport default.
-}
dockSpaceOverViewport ::
  (MonadIO m) =>
  ImGuiID ->
  Ptr ImGuiViewport ->
  ImGuiDockNodeFlags ->
  m ImGuiID
dockSpaceOverViewport dockId vp flags =
  liftIO $
    Raw.dockSpaceOverViewport dockId vp flags nullPtr

{- | Cover the main viewport with an invisible host window containing a
  dock space. The most common docking entry point — call once per frame
  after @newFrame@.
-}
dockSpaceOverMainViewport :: (MonadIO m) => m ImGuiID
dockSpaceOverMainViewport =
  liftIO $
    Raw.dockSpaceOverViewport 0 nullPtr ImGuiDockNodeFlags_None nullPtr

-- | Set the dock id for the next-submitted window with the given condition.
setNextWindowDockID :: (MonadIO m) => ImGuiID -> ImGuiCond -> m ()
setNextWindowDockID = Raw.setNextWindowDockID

-- | Allocate a 'WC.WindowClass', run an action with it, and free it.
withWindowClass :: (MonadUnliftIO m) => (WC.WindowClass -> m a) -> m a
withWindowClass = bracket WC.new WC.destroy

--------------------------------------------------------------------------------
-- Viewport conveniences

getMainViewportPos :: (MonadIO m) => m ImVec2
getMainViewportPos = liftIO do
  vp <- Viewport.getMainViewport
  alloca \outPtr -> do
    Viewport.viewportPos vp outPtr
    peek outPtr

getMainViewportSize :: (MonadIO m) => m ImVec2
getMainViewportSize = liftIO do
  vp <- Viewport.getMainViewport
  alloca \outPtr -> do
    Viewport.viewportSize vp outPtr
    peek outPtr

getMainViewportWorkPos :: (MonadIO m) => m ImVec2
getMainViewportWorkPos = liftIO do
  vp <- Viewport.getMainViewport
  alloca \outPtr -> do
    Viewport.viewportWorkPos vp outPtr
    peek outPtr

getMainViewportWorkSize :: (MonadIO m) => m ImVec2
getMainViewportWorkSize = liftIO do
  vp <- Viewport.getMainViewport
  alloca \outPtr -> do
    Viewport.viewportWorkSize vp outPtr
    peek outPtr
