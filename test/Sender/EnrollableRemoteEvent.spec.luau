--Tests EnrollableRemoteEvent.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnrollableRemoteEvent = require(ReplicatedStorage.NexusBufferedReplication.Sender.EnrollableRemoteEvent)

return function()
    describe("An EnrollableRemoteEvent", function()
        local MockPlayer1, MockPlayer2 = {UserId = 1} :: any, {UserId = 2} :: any
        local TestEnrollableRemoteEvent = nil
        local MockRemoteEvent = nil
        beforeEach(function()
            MockRemoteEvent = {
                Events = {},
                FireClient = function(self, Player, Data)
                    table.insert(self.Events, {
                        Function = "FireClient",
                        Player = Player,
                        Data = Data,
                    })
                end,
                FireAllClients = function(self, Data)
                    table.insert(self.Events, {
                        Function = "FireAllClients",
                        Data = Data,
                    })
                end,
            } :: any

            EnrollableRemoteEvent.Players = {
                GetPlayers = function() return {MockPlayer1, MockPlayer2} end,
                PlayerAdded = Instance.new("BindableEvent").Event,
                PlayerRemoving = Instance.new("BindableEvent").Event,
            } :: any
            TestEnrollableRemoteEvent = EnrollableRemoteEvent.new(MockRemoteEvent)
        end)

        afterEach(function()
            EnrollableRemoteEvent.Players = game:GetService("Players")
            TestEnrollableRemoteEvent:Destroy()
        end)

        it("should send data to all clients.", function()
            TestEnrollableRemoteEvent:EnrollPlayer(MockPlayer1)
            TestEnrollableRemoteEvent:EnrollPlayer(MockPlayer2)
            TestEnrollableRemoteEvent:FireAllClients("TestData")
            expect(#MockRemoteEvent.Events).to.equal(1)
            expect(MockRemoteEvent.Events[1].Function).to.equal("FireAllClients")
            expect(MockRemoteEvent.Events[1].Data).to.equal("TestData")
        end)

        it("should send data to enrolled clients.", function()
            TestEnrollableRemoteEvent.TotalPlayers = 3
            TestEnrollableRemoteEvent:EnrollPlayer(MockPlayer1)
            TestEnrollableRemoteEvent:EnrollPlayer(MockPlayer2)
            TestEnrollableRemoteEvent:FireAllClients("TestData")
            expect(#MockRemoteEvent.Events).to.equal(2)
            expect(MockRemoteEvent.Events[1].Function).to.equal("FireClient")
            expect(MockRemoteEvent.Events[1].Player).to.equal(MockPlayer1)
            expect(MockRemoteEvent.Events[1].Data).to.equal("TestData")
            expect(MockRemoteEvent.Events[2].Function).to.equal("FireClient")
            expect(MockRemoteEvent.Events[2].Player).to.equal(MockPlayer2)
            expect(MockRemoteEvent.Events[2].Data).to.equal("TestData")
        end)
    end)
end