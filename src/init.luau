--Main module for Nexus Buffered Replication.
--!strict

local BufferedRemoteEventReceiver = require(script:WaitForChild("Receiver"):WaitForChild("BufferedRemoteEventReceiver"))
local PlayerBufferedRemoteEventReceiver = require(script:WaitForChild("Receiver"):WaitForChild("PlayerBufferedRemoteEventReceiver"))
local BufferedRemoteEventSender = require(script:WaitForChild("Sender"):WaitForChild("BufferedRemoteEventSender"))
local EnrollableRemoteEvent = require(script:WaitForChild("Sender"):WaitForChild("EnrollableRemoteEvent"))

export type BufferedRemoteEventReceiver<TKey, TData> = BufferedRemoteEventReceiver.BufferedRemoteEventReceiver<TKey, TData>
export type PlayerBufferedRemoteEventReceiver<TData> = PlayerBufferedRemoteEventReceiver.PlayerBufferedRemoteEventReceiver<TData>
export type BufferedRemoteEvent = BufferedRemoteEventSender.BufferedRemoteEvent
export type BufferedRemoteEventSender<TKey, TData> = BufferedRemoteEventSender.BufferedRemoteEventSender<TKey, TData>
export type EnrollableRemoteEvent = EnrollableRemoteEvent.EnrollableRemoteEvent

return {
    Receiver = {
        BufferedRemoteEventReceiver = BufferedRemoteEventReceiver,
        PlayerBufferedRemoteEventReceiver = PlayerBufferedRemoteEventReceiver,
    },
    Sender = {
        BufferedRemoteEventSender = BufferedRemoteEventSender,
        EnrollableRemoteEvent = EnrollableRemoteEvent,
    },
}