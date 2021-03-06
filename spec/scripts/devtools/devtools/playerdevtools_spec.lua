require "busted.runner"()

describe("PlayerDevTools", function()
    -- setup
    local match

    -- before_each test data
    local inst
    local player_dead, player_hopping, player_over_water, player_running, player_sinking, players

    -- before_each initialization
    local devtools, world
    local PlayerDevTools, playerdevtools

    local function EachPlayer(fn, except)
        except = except ~= nil and except or {}
        for _, player in pairs(players) do
            if not TableHasValue(except, player) then
                fn(player)
            end
        end
    end

    setup(function()
        -- match
        match = require "luassert.match"

        -- debug
        DebugSpyTerm()
        DebugSpyInit(spy)

        -- globals
        _G.kleifileexists = ReturnValueFn(false)

        _G.EQUIPSLOTS = {
            BODY = "body",
            HEAD = "head",
        }

        _G.TUNING = {
            MINERHAT_LIGHTTIME = 468,
            TORCH_DAMAGE = 34 * .5,
        }
    end)

    teardown(function()
        -- debug
        DebugSpyTerm()

        -- globals
        _G.ConsoleCommandPlayer = nil
        _G.ConsoleRemote = nil
        _G.EQUIPSLOTS = nil
        _G.GROUND = nil
        _G.SetDebugEntity = nil
        _G.TheNet = nil
        _G.TheSim = nil
        _G.kleifileexists = nil
    end)

    before_each(function()
        -- test data
        inst = MockPlayerInst("PlayerInst", nil, { "godmode", "idle" }, { "wereness" })
        player_dead = MockPlayerInst("PlayerDead", "KU_one", { "dead", "idle" })
        player_hopping = MockPlayerInst("PlayerHopping", "KU_two", { "hopping" })
        player_running = MockPlayerInst("PlayerRunning", "KU_four", { "running" })
        player_sinking = MockPlayerInst("PlayerSinking", "KU_five", { "sinking" })
        player_over_water = MockPlayerInst("PlayerOverWater", "KU_three", nil, nil, { 100, 0, 100 })

        players = {
            inst,
            player_dead,
            player_hopping,
            player_over_water,
            player_running,
            player_sinking,
        }

        -- globals (TheNet)
        _G.TheNet = MockTheNet({
            {
                userid = inst.userid,
                admin = true
            },
            {
                userid = "KU_one",
                admin = false
            },
            {
                userid = "KU_two",
                admin = false
            },
            {
                userid = "KU_three",
                admin = false
            },
            {
                userid = "KU_four",
                admin = false
            },
            {
                userid = "KU_five",
                admin = false
            },
        })

        -- globals
        _G.ConsoleCommandPlayer = spy.new(ReturnValueFn(inst))
        _G.ConsoleRemote = spy.new(Empty)
        _G.GROUND = { INVALID = 255 }
        _G.SetDebugEntity = spy.new(Empty)
        _G.TheSim = MockTheSim()

        -- initialization
        devtools = MockDevTools()
        world = MockWorldDevTools()

        PlayerDevTools = require "devtools/devtools/playerdevtools"
        playerdevtools = PlayerDevTools(inst, world, devtools)

        DebugSpyClear()
    end)

    insulate("initialization", function()
        before_each(function()
            -- general
            devtools = MockDevTools()

            -- initialization
            PlayerDevTools = require "devtools/devtools/playerdevtools"
        end)

        local function AssertDefaults(self)
            assert.is_equal(devtools, self.devtools)
            assert.is_equal("PlayerDevTools", self.name)

            -- general
            assert.is_nil(self.controller)
            assert.is_equal(inst, self.inst)
            assert.is_false(self.is_move_button_down)
            assert.is_equal(world.inst.ismastersim, self.ismastersim)
            assert.is_nil(self.speech)
            assert.is_nil(self.wereness_mode)
            assert.is_equal(world, self.world)

            -- god mode
            assert.is_equal(0, #self.god_mode_players)

            -- selection
            assert.is_equal(inst, self.selected_client)
            assert.is_nil(self.selected_server)

            -- submodules
            assert.is_not_nil(self.console)
            assert.is_not_nil(self.inventory)
            assert.is_not_nil(self.crafting)
            assert.is_not_nil(self.vision)
            assert.is_not_nil(self.map)

            -- other
            assert.is_equal(self, self.devtools.player)
        end

        describe("using the constructor", function()
            before_each(function()
                inst.HasTag:clear()
                inst.ListenForEvent:clear()

                playerdevtools = PlayerDevTools(inst, world, devtools)
            end)

            it("should have the default fields", function()
                AssertDefaults(playerdevtools)
            end)

            it("should call the instance HasTag()", function()
                assert.spy(inst.HasTag).was_called(1)
                assert.spy(inst.HasTag).was_called_with(match.is_ref(inst), "wereness")
            end)

            it("should call the instance ListenForEvent()", function()
                assert.spy(inst.ListenForEvent).was_called(1)
                assert.spy(inst.ListenForEvent).was_called_with(
                    match.is_ref(inst),
                    "weremodedirty",
                    match.is_function()
                )
            end)
        end)

        it("should add DevTools methods", function()
            local methods = {
                GetSelectedPlayer = "GetSelected",
                SelectPlayer = "Select",

                -- general
                "GetPlayer",
                "GetSpeech",
                "GetWerenessMode",
                "IsMoveButtonDown",
                --"SetIsMoveButtonDown",
                "IsAdmin",
                "IsSinking",
                "IsGhost",
                "IsIdle",
                "IsOverWater",
                "IsOwner",
                "IsPlatformJumping",
                "IsReal",
                "IsRunning",

                -- god mode
                "GetGodModePlayers",
                "IsGodMode",
                "ToggleGodMode",

                -- hud
                "GetHUD",
                "IsHUDChatInputScreenOpen",
                "IsHUDConsoleScreenOpen",
                "IsHUDWritableScreenActive",

                -- lightwatcher
                "IsInLight",
                "GetTimeInDark",
                "GetTimeInLight",
                "CanGrueAttack",

                -- movement prediction
                "IsMovementPrediction",
                "MovementPrediction",
                "ToggleMovementPrediction",

                -- player
                "GetHealthPercent",
                "GetHungerPercent",
                "GetSanityPercent",
                "GetMaxHealthPercent",
                "GetMoisturePercent",
                "GetTemperature",
                "GetWerenessPercent",

                -- selection
                "IsSelectedInSync",

                -- teleport
                "Teleport",
            }

            AssertAddedMethodsBefore(methods, devtools)
            playerdevtools = PlayerDevTools(inst, world, devtools)
            AssertAddedMethodsAfter(methods, playerdevtools, devtools)
        end)
    end)

    describe("general", function()
        describe("should have the", function()
            describe("getter", function()
                local getters = {
                    inst = "GetPlayer",
                    wereness_mode = "GetWerenessMode",
                    is_move_button_down = "IsMoveButtonDown",
                }

                for field, getter in pairs(getters) do
                    it(getter, function()
                        AssertGetter(playerdevtools, field, getter)
                    end)
                end
            end)

            describe("setter", function()
                it("SetIsMoveButtonDown", function()
                    AssertSetter(playerdevtools, "is_move_button_down", "SetIsMoveButtonDown")
                end)
            end)
        end)

        describe("IsAdmin", function()
            local GetClientTable

            before_each(function()
                GetClientTable = TheNet.GetClientTable
            end)

            describe("when the TheNet.GetClientTable() returns an empty table", function()
                before_each(function()
                    _G.TheNet = MockTheNet({})
                    GetClientTable = TheNet.GetClientTable
                end)

                it("should call the TheNet.GetClientTable()", function()
                    EachPlayer(function(player)
                        GetClientTable:clear()
                        playerdevtools:IsAdmin(player)
                        assert.spy(GetClientTable).was_called(1)
                    end)
                end)

                it("should return nil", function()
                    EachPlayer(function(player)
                        assert.is_nil(playerdevtools:IsAdmin(player))
                    end)
                end)
            end)

            describe("when the player is an admin", function()
                it("should call the TheNet.GetClientTable()", function()
                    assert.spy(GetClientTable).was_not_called()
                    playerdevtools:IsAdmin(inst)
                    assert.spy(GetClientTable).was_called(1)
                    assert.spy(GetClientTable).was_called_with(TheNet)
                end)

                it("should return true", function()
                    assert.is_true(playerdevtools:IsAdmin(inst))
                end)
            end)

            describe("when the player is not an admin", function()
                it("should call the TheNet.GetClientTable()", function()
                    EachPlayer(function(player)
                        GetClientTable:clear()
                        playerdevtools:IsAdmin(player)
                        assert.spy(GetClientTable).was_called(1)
                        assert.spy(GetClientTable).was_called_with(TheNet)
                    end, { inst })
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(playerdevtools:IsAdmin(player))
                    end, { inst })
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(function(player)
                        AssertChainNil(function()
                            assert.is_nil(playerdevtools:IsAdmin(player))
                        end, playerdevtools, "userid")
                    end)
                end)
            end)
        end)

        -- TODO: Split the PlayerDevTools:IsSinking() tests into smaller ones
        describe("IsSinking", function()
            local function AssertSinking(player)
                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()

                assert.is_true(
                    playerdevtools:IsSinking(player),
                    string.format("Player %s should be sinking", player:GetDisplayName())
                )

                assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                    match.is_ref(player.AnimState),
                    "sink"
                )

                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called_with(
                    match.is_ref(player.AnimState),
                    "plank_hop"
                )
            end

            local function AssertNotSinking(player)
                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()

                assert.is_false(
                    playerdevtools:IsSinking(player),
                    string.format("Player %s shouldn't be sinking", player:GetDisplayName())
                )

                assert.spy(player.AnimState.IsCurrentAnimation).was_called(2)
                assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                    match.is_ref(player.AnimState),
                    "sink"
                )

                assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                    match.is_ref(player.AnimState),
                    "plank_hop"
                )
            end

            local function AssertNilChain(player)
                player.AnimState.IsCurrentAnimation = nil
                assert.is_nil(playerdevtools:IsSinking(player))
                player.AnimState = nil
                assert.is_nil(playerdevtools:IsSinking(player))
                player = nil
                assert.is_nil(playerdevtools:IsSinking(player))
            end

            it("should return true when the player is sinking", function()
                AssertSinking(player_sinking)
            end)

            it("should return false when the player is not sinking", function()
                EachPlayer(AssertNotSinking, { player_sinking })
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(AssertNilChain)
                end)
            end)
        end)

        -- TODO: Split the PlayerDevTools:IsGhost() tests into smaller ones
        describe("IsGhost", function()
            local function AssertDead(player)
                assert.spy(player_dead.HasTag).was_not_called()

                assert.is_true(
                    playerdevtools:IsGhost(player),
                    string.format("Player %s should be dead", player:GetDisplayName())
                )

                assert.spy(player_dead.HasTag).was_called(1)
                assert.spy(player_dead.HasTag).was_called_with(
                    match.is_ref(player_dead),
                    "playerghost"
                )
            end

            local function AssertNotDead(player, calls)
                calls = calls ~= nil and calls or 0

                assert.spy(player.HasTag).was_called(calls)

                assert.is_false(
                    playerdevtools:IsGhost(player),
                    string.format("Player %s shouldn't be dead", player:GetDisplayName())
                )

                assert.spy(player.HasTag).was_called(calls + 1)
                assert.spy(player.HasTag).was_called_with(match.is_ref(player), "playerghost")
            end

            local function AssertNilChain(player)
                player.HasTag = nil
                assert.is_nil(playerdevtools:IsGhost(player))
                player = nil
                assert.is_nil(playerdevtools:IsGhost(player))
            end

            it("should return true when the player is dead", function()
                AssertDead(player_dead)
            end)

            it("should return false when the player is not dead", function()
                AssertNotDead(inst, 1)
                EachPlayer(AssertNotDead, { inst, player_dead })
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(AssertNilChain)
                end)
            end)
        end)

        -- TODO: Split the PlayerDevTools:IsIdle() tests into smaller ones
        describe("IsIdle", function()
            local function AssertIdleStateGraph(player)
                assert.spy(player.sg.HasStateTag).was_not_called()
                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()

                assert.is_true(
                    playerdevtools:IsIdle(player),
                    string.format("Player %s should be idle", player:GetDisplayName())
                )

                assert.spy(player.sg.HasStateTag).was_called(1)
                assert.spy(player.sg.HasStateTag).was_called_with(match.is_ref(player.sg), "idle")
                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()
            end

            local function AssertIdleAnimation(player)
                player.sg = nil

                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()

                assert.is_true(
                    playerdevtools:IsIdle(player),
                    string.format("Player %s should be idle", player:GetDisplayName())
                )

                assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                    match.is_ref(player.AnimState),
                    "idle_loop"
                )
            end

            local function AssertNotIdleStateGraph(player)
                assert.spy(player.sg.HasStateTag).was_not_called()
                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()

                assert.is_false(
                    playerdevtools:IsIdle(player),
                    string.format("Player %s shouldn't be idle", player:GetDisplayName())
                )

                assert.spy(player.sg.HasStateTag).was_called(1)
                assert.spy(player.sg.HasStateTag).was_called_with(match.is_ref(player.sg), "idle")
                assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                    match.is_ref(player.AnimState),
                    "idle_loop"
                )
            end

            local function AssertNotIdleAnimation(player)
                player.sg = nil

                assert.spy(player.AnimState.IsCurrentAnimation).was_not_called()

                assert.is_false(
                    playerdevtools:IsIdle(player),
                    string.format("Player %s shouldn't be idle", player:GetDisplayName())
                )

                assert.spy(player.AnimState.IsCurrentAnimation).was_called(1)
                assert.spy(player.AnimState.IsCurrentAnimation).was_called_with(
                    match.is_ref(player.AnimState),
                    "idle_loop"
                )
            end

            local function AssertNilChain(player)
                player.sg = nil
                player.AnimState.IsCurrentAnimation = nil
                assert.is_nil(playerdevtools:IsIdle(player))
                player.AnimState = nil
                assert.is_nil(playerdevtools:IsIdle(player))
            end

            describe("should return true when the player is idle", function()
                it("based on the state graph", function()
                    AssertIdleStateGraph(inst)
                    AssertIdleStateGraph(player_dead)
                    AssertIdleStateGraph(player_over_water)
                end)

                it("based on the animation", function()
                    AssertIdleAnimation(inst)
                    AssertIdleAnimation(player_dead)
                    AssertIdleAnimation(player_over_water)
                end)
            end)

            describe("should return false when the player is not idle", function()
                it("based on the state graph", function()
                    EachPlayer(AssertNotIdleStateGraph, { inst, player_dead, player_over_water })
                end)

                it("based on the animation", function()
                    EachPlayer(AssertNotIdleAnimation, { inst, player_dead, player_over_water })
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(AssertNilChain)
                end)
            end)
        end)

        -- TODO: Split the PlayerDevTools:IsOverWater() tests into smaller ones
        describe("IsOverWater", function()
            local function AssertOverWater(player)
                world = MockWorldDevTools()
                playerdevtools.world = world

                assert.spy(player.Transform.GetWorldPosition).was_not_called()
                assert.spy(world.inst.Map.IsVisualGroundAtPoint).was_not_called()
                assert.spy(world.inst.Map.GetTileAtPoint).was_not_called()
                assert.spy(player.GetCurrentPlatform).was_not_called()

                assert.is_true(
                    playerdevtools:IsOverWater(player),
                    string.format("Player %s should be over water", player:GetDisplayName())
                )

                assert.spy(player.Transform.GetWorldPosition).was_called(1)
                assert.spy(player.Transform.GetWorldPosition).was_called_with(
                    match.is_ref(player.Transform)
                )

                assert.spy(world.inst.Map.IsVisualGroundAtPoint).was_called(1)
                assert.spy(world.inst.Map.IsVisualGroundAtPoint).was_called_with(
                    match.is_ref(world.inst.Map),
                    player.Transform.GetWorldPosition()
                )

                assert.spy(world.inst.Map.GetTileAtPoint).was_called(1)
                assert.spy(world.inst.Map.GetTileAtPoint).was_called_with(
                    match.is_ref(world.inst.Map),
                    player.Transform.GetWorldPosition()
                )

                assert.spy(player.GetCurrentPlatform).was_called(1)
                assert.spy(player.GetCurrentPlatform).was_called_with(match.is_ref(player))
            end

            local function AssertNotOverWater(player)
                world = MockWorldDevTools()
                playerdevtools.world = world

                assert.spy(player.Transform.GetWorldPosition).was_not_called()
                assert.spy(world.inst.Map.IsVisualGroundAtPoint).was_not_called()
                assert.spy(world.inst.Map.GetTileAtPoint).was_not_called()
                assert.spy(player.GetCurrentPlatform).was_not_called()

                assert.is_false(
                    playerdevtools:IsOverWater(player),
                    string.format("Player %s shouldn't be over water", player:GetDisplayName())
                )

                assert.spy(player.Transform.GetWorldPosition).was_called(1)
                assert.spy(player.Transform.GetWorldPosition).was_called_with(
                    match.is_ref(player.Transform)
                )

                assert.spy(world.inst.Map.IsVisualGroundAtPoint).was_called(1)
                assert.spy(world.inst.Map.IsVisualGroundAtPoint).was_called_with(
                    match.is_ref(world.inst.Map),
                    player.Transform.GetWorldPosition()
                )

                assert.spy(world.inst.Map.GetTileAtPoint).was_not_called()
                assert.spy(player.GetCurrentPlatform).was_not_called()
            end

            local function AssertNilChain(player)
                player.Transform.GetWorldPosition = nil
                assert.is_nil(playerdevtools:IsOverWater(player))
                player.Transform = nil
                assert.is_nil(playerdevtools:IsOverWater(player))

                world = MockWorldDevTools(true)
                playerdevtools.world = world

                world.inst.Map.IsVisualGroundAtPoint = nil
                assert.is_nil(playerdevtools:IsOverWater(player))
                world.inst.Map = nil
                assert.is_nil(playerdevtools:IsOverWater(player))
                world.inst = nil
                assert.is_nil(playerdevtools:IsOverWater(player))
                world = nil
                assert.is_nil(playerdevtools:IsOverWater(player))
            end

            it("should return true when the player is over water", function()
                AssertOverWater(player_over_water)
            end)

            it("should return false when the player is not over water", function()
                EachPlayer(AssertNotOverWater, { player_over_water })
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    EachPlayer(AssertNilChain)
                end)
            end)
        end)

        describe("IsOwner", function()
            describe("when the player is an owner", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        playerdevtools.inst = player
                        assert.is_true(playerdevtools:IsOwner(player), player:GetDisplayName())
                    end)
                end)
            end)

            describe("when the player is not an owner", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_false(playerdevtools:IsOwner(player), player:GetDisplayName())
                    end, { inst })
                end)
            end)

            describe("when the PlayerDevTools.inst is missing", function()
                before_each(function()
                    playerdevtools.inst = nil
                end)

                it("should return nil", function()
                    EachPlayer(function(player)
                        assert.is_nil(playerdevtools:IsOwner(player))
                    end)
                end)
            end)
        end)

        describe("IsPlatformJumping", function()
            describe("when the player is jumping", function()
                it("should return true", function()
                    assert.is_true(playerdevtools:IsPlatformJumping(player_hopping))
                end)
            end)

            describe("when the player is not jumping", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_false(
                            playerdevtools:IsPlatformJumping(player),
                            player:GetDisplayName()
                        )
                    end, { player_hopping })
                end)
            end)

            describe("when the player HasTag is missing", function()
                before_each(function()
                    EachPlayer(function(player)
                        player.HasTag = nil
                    end)
                end)

                it("should return nil", function()
                    EachPlayer(function(player)
                        assert.is_nil(
                            playerdevtools:IsPlatformJumping(player),
                            player:GetDisplayName()
                        )
                    end)
                end)
            end)
        end)

        describe("IsReal", function()
            describe("when the player is real", function()
                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_true(playerdevtools:IsReal(player), player:GetDisplayName())
                    end)
                end)
            end)

            describe("when the player is not real", function()
                before_each(function()
                    EachPlayer(function(player)
                        player.userid = ""
                    end)
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(playerdevtools:IsReal(player), player:GetDisplayName())
                    end)
                end)
            end)

            describe("when the userid is missing", function()
                before_each(function()
                    EachPlayer(function(player)
                        player.userid = nil
                    end)
                end)

                it("should return false", function()
                    EachPlayer(function(player)
                        assert.is_false(playerdevtools:IsReal(player), player:GetDisplayName())
                    end)
                end)
            end)
        end)

        describe("IsRunning", function()
            describe("when the player is running", function()
                describe("and the state graph is available", function()
                    local HasStateTag, IsCurrentAnimation, sg

                    before_each(function()
                        sg = player_running.sg
                        HasStateTag = sg.HasStateTag
                        IsCurrentAnimation = player_running.AnimState.IsCurrentAnimation
                    end)

                    it("should call the state graph HasStateTag", function()
                        playerdevtools:IsRunning(player_running)
                        assert.spy(HasStateTag).was_called(1)
                        assert.spy(HasStateTag).was_called_with(match.is_ref(sg), "run")
                    end)

                    it("shouldn't call the animation state IsCurrentAnimation", function()
                        playerdevtools:IsRunning(player_running)
                        assert.spy(IsCurrentAnimation).was_not_called()
                    end)

                    it("should return true", function()
                        assert.is_true(playerdevtools:IsRunning(player_running))
                    end)
                end)

                describe("and the state graph is not available", function()
                    local AnimState, IsCurrentAnimation

                    before_each(function()
                        player_running.sg = nil
                        AnimState = player_running.AnimState
                        IsCurrentAnimation = AnimState.IsCurrentAnimation
                    end)

                    it("should call the animation state IsCurrentAnimation", function()
                        playerdevtools:IsRunning(player_running)
                        assert.spy(IsCurrentAnimation).was_called(2)
                        assert.spy(IsCurrentAnimation).was_called_with(
                            match.is_ref(AnimState),
                            "run_pre"
                        )

                        assert.spy(IsCurrentAnimation).was_called_with(
                            match.is_ref(AnimState),
                            "run_loop"
                        )
                    end)

                    it("should return true", function()
                        assert.is_true(playerdevtools:IsRunning(player_running))
                    end)
                end)
            end)

            describe("when the player is not running", function()
                describe("and the state graph is available", function()
                    local AnimState, HasStateTag, IsCurrentAnimation, sg

                    it("should call the state graph HasStateTag", function()
                        EachPlayer(function(player)
                            sg = player.sg
                            HasStateTag = sg.HasStateTag
                            HasStateTag:clear()

                            playerdevtools:IsRunning(player)
                            assert.spy(HasStateTag, player:GetDisplayName()).was_called(1)
                            assert.spy(HasStateTag).was_called_with(match.is_ref(sg), "run")
                        end, { player_running })
                    end)

                    it("should call the animation state IsCurrentAnimation", function()
                        EachPlayer(function(player)
                            AnimState = player.AnimState
                            IsCurrentAnimation = AnimState.IsCurrentAnimation
                            IsCurrentAnimation:clear()

                            playerdevtools:IsRunning(player)

                            assert.spy(IsCurrentAnimation, player:GetDisplayName()).was_called(
                                3
                            )

                            assert.spy(IsCurrentAnimation).was_called_with(
                                match.is_ref(AnimState),
                                "run_pre"
                            )

                            assert.spy(IsCurrentAnimation).was_called_with(
                                match.is_ref(AnimState),
                                "run_loop"
                            )

                            assert.spy(IsCurrentAnimation).was_called_with(
                                match.is_ref(AnimState),
                                "run_pst"
                            )
                        end, { player_running })
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(
                                playerdevtools:IsRunning(player),
                                player:GetDisplayName()
                            )
                        end, { player_running })
                    end)
                end)

                describe("and the state graph is not available", function()
                    local AnimState, IsCurrentAnimation

                    before_each(function()
                        player_running.sg = nil
                    end)

                    it("should call the animation state IsCurrentAnimation", function()
                        EachPlayer(function(player)
                            AnimState = player.AnimState
                            IsCurrentAnimation = AnimState.IsCurrentAnimation
                            IsCurrentAnimation:clear()

                            playerdevtools:IsRunning(player)

                            assert.spy(IsCurrentAnimation, player:GetDisplayName()).was_called(
                                3
                            )

                            assert.spy(IsCurrentAnimation).was_called_with(
                                match.is_ref(AnimState),
                                "run_pre"
                            )

                            assert.spy(IsCurrentAnimation).was_called_with(
                                match.is_ref(AnimState),
                                "run_loop"
                            )

                            assert.spy(IsCurrentAnimation).was_called_with(
                                match.is_ref(AnimState),
                                "run_pst"
                            )
                        end, { player_running })
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(
                                playerdevtools:IsRunning(player),
                                player:GetDisplayName()
                            )
                        end, { player_running })
                    end)
                end)
            end)
        end)
    end)

    describe("lightwatcher", function()
        describe("IsInLight", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(playerdevtools:IsInLight())
                    end, inst, "LightWatcher", "IsInLight")
                end)
            end)
        end)

        describe("GetTimeInDark", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(playerdevtools:GetTimeInDark())
                    end, inst, "LightWatcher", "GetTimeInDark")
                end)
            end)
        end)

        describe("GetTimeInLight", function()
            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(playerdevtools:GetTimeInLight())
                    end, inst, "LightWatcher", "GetTimeInLight")
                end)
            end)
        end)

        describe("CanGrueAttack", function()
            local HasEquippedMoggles, IsGhost, IsGodMode, IsInLight

            before_each(function()
                HasEquippedMoggles = spy.new(ReturnValueFn(true))
                IsGhost = spy.new(ReturnValueFn(true))
                IsInLight = spy.new(ReturnValueFn(true))
            end)

            describe("when the player is in god mode", function()
                before_each(function()
                    IsGodMode = spy.new(ReturnValueFn(true))
                    playerdevtools.god_mode_players = { inst }
                    playerdevtools.IsGodMode = IsGodMode
                end)

                it("shouldn't call other methods", function()
                    playerdevtools:CanGrueAttack()
                    assert.spy(IsInLight).was_not_called()
                    assert.spy(HasEquippedMoggles).was_not_called()
                    assert.spy(IsGhost).was_not_called()
                end)

                it("should return false", function()
                    assert.is_false(playerdevtools:CanGrueAttack())
                end)
            end)

            describe("when the player is not in god mode", function()
                before_each(function()
                    IsGodMode = spy.new(ReturnValueFn(false))
                    playerdevtools.god_mode_players = {}
                    playerdevtools.IsGodMode = IsGodMode
                end)

                it("should return true", function()
                    assert.is_true(playerdevtools:CanGrueAttack())
                end)

                describe("but in the light", function()
                    before_each(function()
                        before_each(function()
                            playerdevtools.IsInLight = IsInLight
                        end)

                        it("should return false", function()
                            assert.is_false(playerdevtools:CanGrueAttack())
                        end)
                    end)
                end)

                describe("but has Moggles equipped", function()
                    before_each(function()
                        before_each(function()
                            playerdevtools.HasEquippedMoggles = HasEquippedMoggles
                        end)

                        it("should return false", function()
                            assert.is_false(playerdevtools:CanGrueAttack())
                        end)
                    end)
                end)

                describe("but is a ghost", function()
                    before_each(function()
                        before_each(function()
                            playerdevtools.IsGhost = IsGhost
                        end)

                        it("should return false", function()
                            assert.is_false(playerdevtools:CanGrueAttack())
                        end)
                    end)
                end)
            end)
        end)
    end)

    describe("selection", function()
        describe("GetSelected", function()
            it("should call the ConsoleCommandPlayer", function()
                ConsoleCommandPlayer:clear()
                playerdevtools:GetSelected()
                assert.spy(ConsoleCommandPlayer).was_called(1)
                assert.spy(ConsoleCommandPlayer).was_called_with()
            end)

            it("should return the ConsoleCommandPlayer", function()
                assert.is_equal(ConsoleCommandPlayer(), playerdevtools:GetSelected())
            end)
        end)

        describe("Select", function()
            describe("in the local game", function()
                before_each(function()
                    playerdevtools.ismastersim = true
                end)

                it("should set the selected_client field only", function()
                    EachPlayer(function(player)
                        playerdevtools.selected_client = nil
                        playerdevtools.selected_server = nil
                        playerdevtools:Select(player)

                        assert.is_equal(
                            player,
                            playerdevtools.selected_client,
                            player:GetDisplayName()
                        )

                        assert.is_nil(playerdevtools.selected_server, player:GetDisplayName())
                    end)
                end)

                it("should debug string", function()
                    EachPlayer(function(player)
                        DebugSpyClear("DebugString")
                        playerdevtools:Select(player)
                        DebugSpyAssertWasCalled("DebugString", 1, {
                            "Selected",
                            player:GetDisplayName()
                        })
                    end)
                end)

                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_true(playerdevtools:Select(player), player:GetDisplayName())
                    end)
                end)
            end)

            describe("on dedicated server", function()
                before_each(function()
                    playerdevtools.ismastersim = false
                end)

                it("should set the selected_client field only", function()
                    EachPlayer(function(player)
                        playerdevtools.selected_client = nil
                        playerdevtools.selected_server = nil
                        playerdevtools:Select(player)

                        assert.is_equal(
                            player,
                            playerdevtools.selected_client,
                            player:GetDisplayName()
                        )

                        assert.is_equal(
                            player,
                            playerdevtools.selected_server,
                            player:GetDisplayName()
                        )
                    end)
                end)

                it("should debug 2 strings", function()
                    EachPlayer(function(player)
                        DebugSpyClear("DebugString")
                        playerdevtools:Select(player)

                        local name = player:GetDisplayName()
                        DebugSpyAssertWasCalled("DebugString", 2, {
                            "[client]",
                            "Selected",
                            name
                        })

                        DebugSpyAssertWasCalled("DebugString", 2, {
                            "[server]",
                            "Selected",
                            name
                        })
                    end)
                end)

                it("should return true", function()
                    EachPlayer(function(player)
                        assert.is_true(playerdevtools:Select(player), player:GetDisplayName())
                    end)
                end)
            end)
        end)

        describe("IsSelectedInSync", function()
            describe("in the local game", function()
                before_each(function()
                    playerdevtools.ismastersim = true
                end)

                describe("when the player is selected on the client only", function()
                    before_each(function()
                        playerdevtools.selected_client = inst
                        playerdevtools.selected_server = nil
                    end)

                    it("should return true", function()
                        assert.is_true(playerdevtools:IsSelectedInSync())
                    end)
                end)

                describe("when the player is selected on the server only", function()
                    before_each(function()
                        playerdevtools.selected_client = nil
                        playerdevtools.selected_server = inst
                    end)

                    it("should return false", function()
                        assert.is_false(playerdevtools:IsSelectedInSync())
                    end)
                end)

                describe("when the player is selected on both client and server", function()
                    before_each(function()
                        playerdevtools.selected_client = inst
                        playerdevtools.selected_server = inst
                    end)

                    it("should return true", function()
                        assert.is_true(playerdevtools:IsSelectedInSync())
                    end)
                end)
            end)

            describe("on dedicated server", function()
                before_each(function()
                    playerdevtools.ismastersim = false
                end)

                describe("when the player is selected on the client only", function()
                    before_each(function()
                        playerdevtools.selected_client = inst
                        playerdevtools.selected_server = nil
                    end)

                    it("should return true", function()
                        assert.is_false(playerdevtools:IsSelectedInSync())
                    end)
                end)

                describe("when the player is selected on the server only", function()
                    before_each(function()
                        playerdevtools.selected_client = nil
                        playerdevtools.selected_server = inst
                    end)

                    it("should return false", function()
                        assert.is_false(playerdevtools:IsSelectedInSync())
                    end)
                end)

                describe("when the player is selected on both client and server", function()
                    before_each(function()
                        playerdevtools.selected_client = inst
                        playerdevtools.selected_server = inst
                    end)

                    it("should return false", function()
                        assert.is_true(playerdevtools:IsSelectedInSync())
                    end)
                end)
            end)
        end)
    end)

    describe("god mode", function()
        describe("should have the getter", function()
            describe("getter", function()
                it("GetGodModePlayers", function()
                    AssertGetter(playerdevtools, "god_mode_players", "GetGodModePlayers")
                end)
            end)
        end)

        describe("IsGodMode", function()
            describe("when the owner is not an admin", function()
                before_each(function()
                    playerdevtools.inst = player_dead
                end)

                it("should return nil", function()
                    EachPlayer(function(player)
                        assert.is_nil(playerdevtools:IsGodMode(player), player:GetDisplayName())
                    end)
                end)
            end)

            describe("when the owner is an admin", function()
                before_each(function()
                    playerdevtools.inst = inst
                end)

                describe("and the player is not in god_mode_players", function()
                    before_each(function()
                        playerdevtools.god_mode_players = {}
                    end)

                    describe("but the health is invincible", function()
                        before_each(function()
                            EachPlayer(function(player)
                                player.components.health = {}
                                player.components.health.invincible = true
                            end)
                        end)

                        it("should return true", function()
                            EachPlayer(function(player)
                                assert.is_true(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )
                            end)
                        end)
                    end)

                    describe("but the health is not invincible", function()
                        before_each(function()
                            EachPlayer(function(player)
                                player.components.health = {}
                                player.components.health.invincible = false
                            end)
                        end)

                        it("should return false", function()
                            EachPlayer(function(player)
                                assert.is_false(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )
                            end)
                        end)
                    end)

                    describe("but the health components is missing", function()
                        it("should return false", function()
                            EachPlayer(function(player)
                                player.components.health.invincible = nil
                                assert.is_false(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )

                                player.components.health = nil
                                assert.is_false(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )

                                player.components = nil
                                assert.is_false(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )
                            end)
                        end)
                    end)
                end)

                describe("and the player is in god_mode_players", function()
                    before_each(function()
                        playerdevtools.god_mode_players = {}
                        EachPlayer(function(player)
                            table.insert(playerdevtools.god_mode_players, player.userid)
                        end)
                    end)

                    describe("but the health is invincible", function()
                        before_each(function()
                            EachPlayer(function(player)
                                player.components.health = {}
                                player.components.health.invincible = true
                            end)
                        end)

                        it("should return true", function()
                            EachPlayer(function(player)
                                assert.is_true(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )
                            end)
                        end)
                    end)

                    describe("but the health is not invincible", function()
                        before_each(function()
                            EachPlayer(function(player)
                                player.components.health = {}
                                player.components.health.invincible = false
                            end)
                        end)

                        it("should return false", function()
                            EachPlayer(function(player)
                                assert.is_false(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )
                            end)
                        end)
                    end)

                    describe("but the health components is missing", function()
                        it("should return true", function()
                            EachPlayer(function(player)
                                player.components.health.invincible = nil
                                assert.is_true(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )

                                player.components.health = nil
                                assert.is_true(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )

                                player.components = nil
                                assert.is_true(
                                    playerdevtools:IsGodMode(player),
                                    player:GetDisplayName()
                                )
                            end)
                        end)
                    end)
                end)
            end)
        end)

        describe("ToggleGodMode", function()
            describe("when the owner is not an admin", function()
                before_each(function()
                    playerdevtools.inst = player_dead
                end)

                it("should debug error", function()
                    EachPlayer(function(player)
                        DebugSpyClear("DebugErrorNotAdmin")
                        playerdevtools:ToggleGodMode(player)
                        DebugSpyAssertWasCalled("DebugErrorNotAdmin", 1, {
                            "PlayerDevTools:ToggleGodMode()"
                        })
                    end)
                end)

                it("should return nil", function()
                    EachPlayer(function(player)
                        assert.is_nil(playerdevtools:ToggleGodMode(player), player:GetDisplayName())
                    end)
                end)
            end)

            describe("when the owner is an admin", function()
                before_each(function()
                    playerdevtools.inst = inst
                end)

                describe("and the player is not in god mode", function()
                    before_each(function()
                        playerdevtools.god_mode_players = {}
                        playerdevtools.IsGodMode = ReturnValueFn(false)
                    end)

                    it("should add the player userid to the god_mode_players table", function()
                        EachPlayer(function(player)
                            assert.is_false(
                                TableHasValue(playerdevtools.god_mode_players, player.userid),
                                player:GetDisplayName()
                            )

                            playerdevtools:ToggleGodMode(player)

                            assert.is_true(
                                TableHasValue(playerdevtools.god_mode_players, player.userid),
                                player:GetDisplayName()
                            )
                        end)
                    end)

                    it("should send the corresponding remote console command", function()
                        EachPlayer(function()
                            -- TODO: Add the missing PlayerDevTools:ToggleGodMode() test
                        end)
                    end)

                    it("should debug selected player string", function()
                        EachPlayer(function(player)
                            DebugSpyClear("DebugSelectedPlayerString")
                            playerdevtools:ToggleGodMode(player)
                            DebugSpyAssertWasCalled("DebugSelectedPlayerString", 1, {
                                "God Mode is enabled"
                            })
                        end)
                    end)

                    it("should return true", function()
                        EachPlayer(function(player)
                            assert.is_true(
                                playerdevtools:ToggleGodMode(player),
                                player:GetDisplayName()
                            )
                        end)
                    end)
                end)

                describe("and the player is in god mode", function()
                    before_each(function()
                        playerdevtools.god_mode_players = {}
                        playerdevtools.IsGodMode = ReturnValueFn(true)

                        EachPlayer(function(player)
                            table.insert(playerdevtools.god_mode_players, player.userid)
                        end)
                    end)

                    it("should remove the player from the god_mode_players table", function()
                        EachPlayer(function(player)
                            assert.is_true(
                                TableHasValue(playerdevtools.god_mode_players, player.userid),
                                player:GetDisplayName()
                            )

                            playerdevtools:ToggleGodMode(player)

                            assert.is_false(
                                TableHasValue(playerdevtools.god_mode_players, player.userid),
                                player:GetDisplayName()
                            )
                        end)
                    end)

                    it("should send the corresponding remote console command", function()
                        EachPlayer(function()
                            -- TODO: Add the missing PlayerDevTools:ToggleGodMode() test
                        end)
                    end)

                    it("should debug selected player string", function()
                        EachPlayer(function(player)
                            DebugSpyClear("DebugSelectedPlayerString")
                            playerdevtools:ToggleGodMode(player)
                            DebugSpyAssertWasCalled("DebugSelectedPlayerString", 1, {
                                "God Mode is disabled"
                            })
                        end)
                    end)

                    it("should return false", function()
                        EachPlayer(function(player)
                            assert.is_false(
                                playerdevtools:ToggleGodMode(player),
                                player:GetDisplayName()
                            )
                        end)
                    end)
                end)
            end)
        end)
    end)

    describe("player bars", function()
        describe("getter", function()
            local function TestWhenThePlayerIsNotPassed(describe, it, before_each, fn_name)
                describe("when the player is not passed", function()
                    local GetSelected

                    before_each(function()
                        GetSelected = spy.new(Empty)
                        playerdevtools.GetSelected = GetSelected
                    end)

                    it("should call the GetSelected()", function()
                        assert.spy(GetSelected).was_not_called()
                        playerdevtools[fn_name](playerdevtools)
                        assert.spy(GetSelected).was_called(1)
                        assert.spy(GetSelected).was_called_with(match.is_ref(playerdevtools))
                    end)

                    it("should return nil", function()
                        assert.is_nil(playerdevtools:GetMoisturePercent())
                    end)
                end)
            end

            describe("GetHealthPercent", function()
                TestWhenThePlayerIsNotPassed(describe, it, before_each, "GetHealthPercent")

                describe("when the player is passed", function()
                    describe("and the Health replica component is available", function()
                        local GetPercent

                        before_each(function()
                            EachPlayer(function(player)
                                player.replica.health = { GetPercent = spy.new(ReturnValueFn(1)) }
                            end)
                        end)

                        it("should call the Health:GetPercent()", function()
                            EachPlayer(function(player)
                                GetPercent = player.replica.health.GetPercent
                                assert.spy(GetPercent).was_not_called()
                                playerdevtools:GetHealthPercent(player)
                                assert.spy(GetPercent).was_called(1)
                                assert.spy(GetPercent).was_called_with(
                                    match.is_ref(player.replica.health)
                                )
                            end)
                        end)

                        it("should return the health percent", function()
                            EachPlayer(function(player)
                                assert.is_equal(100, playerdevtools:GetHealthPercent(player))
                            end)
                        end)
                    end)

                    describe("when some chain fields are missing", function()
                        it("should return nil", function()
                            EachPlayer(function(player)
                                AssertChainNil(function()
                                    assert.is_nil(playerdevtools:GetHealthPercent(player))
                                end, player, "replica", "health")
                            end)
                        end)
                    end)
                end)
            end)

            describe("GetHungerPercent", function()
                TestWhenThePlayerIsNotPassed(describe, it, before_each, "GetHungerPercent")

                describe("when the player is passed", function()
                    describe("and the Hunger replica component is available", function()
                        local GetPercent

                        before_each(function()
                            EachPlayer(function(player)
                                player.replica.hunger = { GetPercent = spy.new(ReturnValueFn(1)) }
                            end)
                        end)

                        it("should call the Hunger:GetPercent()", function()
                            EachPlayer(function(player)
                                GetPercent = player.replica.hunger.GetPercent
                                assert.spy(GetPercent).was_not_called()
                                playerdevtools:GetHungerPercent(player)
                                assert.spy(GetPercent).was_called(1)
                                assert.spy(GetPercent).was_called_with(
                                    match.is_ref(player.replica.hunger)
                                )
                            end)
                        end)

                        it("should return the hunger percent", function()
                            EachPlayer(function(player)
                                assert.is_equal(100, playerdevtools:GetHungerPercent(player))
                            end)
                        end)
                    end)

                    describe("when some chain fields are missing", function()
                        it("should return nil", function()
                            EachPlayer(function(player)
                                AssertChainNil(function()
                                    assert.is_nil(playerdevtools:GetHungerPercent(player))
                                end, player, "replica", "hunger")
                            end)
                        end)
                    end)
                end)
            end)

            describe("GetSanityPercent", function()
                TestWhenThePlayerIsNotPassed(describe, it, before_each, "GetSanityPercent")

                describe("when the player is passed", function()
                    describe("and the Sanity replica component is available", function()
                        local GetPercent

                        before_each(function()
                            EachPlayer(function(player)
                                player.replica.sanity = { GetPercent = spy.new(ReturnValueFn(1)) }
                            end)
                        end)

                        it("should call the Sanity:GetPercent()", function()
                            EachPlayer(function(player)
                                GetPercent = player.replica.sanity.GetPercent
                                assert.spy(GetPercent).was_not_called()
                                playerdevtools:GetSanityPercent(player)
                                assert.spy(GetPercent).was_called(1)
                                assert.spy(GetPercent).was_called_with(
                                    match.is_ref(player.replica.sanity)
                                )
                            end)
                        end)

                        it("should return the sanity percent", function()
                            EachPlayer(function(player)
                                assert.is_equal(100, playerdevtools:GetSanityPercent(player))
                            end)
                        end)
                    end)

                    describe("when some chain fields are missing", function()
                        it("should return nil", function()
                            EachPlayer(function(player)
                                AssertChainNil(function()
                                    assert.is_nil(playerdevtools:GetSanityPercent(player))
                                end, player, "replica", "sanity")
                            end)
                        end)
                    end)
                end)
            end)

            describe("GetMaxHealthPercent", function()
                TestWhenThePlayerIsNotPassed(describe, it, before_each, "GetMaxHealthPercent")

                describe("when the player is passed", function()
                    describe("and the Health replica component is available", function()
                        local GetPenaltyPercent

                        before_each(function()
                            EachPlayer(function(player)
                                player.replica.health = {
                                    GetPenaltyPercent = spy.new(ReturnValueFn(.4)),
                                }
                            end)
                        end)

                        it("should call the Health:GetPenaltyPercent()", function()
                            EachPlayer(function(player)
                                GetPenaltyPercent = player.replica.health.GetPenaltyPercent
                                assert.spy(GetPenaltyPercent).was_not_called()
                                playerdevtools:GetMaxHealthPercent(player)
                                assert.spy(GetPenaltyPercent).was_called(1)
                                assert.spy(GetPenaltyPercent).was_called_with(
                                    match.is_ref(player.replica.health)
                                )
                            end)
                        end)

                        it("should return the maximum health percent", function()
                            EachPlayer(function(player)
                                assert.is_equal(60, playerdevtools:GetMaxHealthPercent(player))
                            end)
                        end)
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        EachPlayer(function(player)
                            AssertChainNil(function()
                                assert.is_nil(playerdevtools:GetMaxHealthPercent(player))
                            end, player, "replica", "health")
                        end)
                    end)
                end)
            end)

            describe("GetMoisturePercent", function()
                TestWhenThePlayerIsNotPassed(describe, it, before_each, "GetMoisturePercent")

                describe("when the player is passed", function()
                    local GetMoisture

                    before_each(function()
                        EachPlayer(function(player)
                            player.GetMoisture = spy.new(ReturnValueFn(0))
                        end)
                    end)

                    it("should call the player GetMoisture()", function()
                        EachPlayer(function(player)
                            GetMoisture = player.GetMoisture
                            assert.spy(GetMoisture).was_not_called()
                            playerdevtools:GetMoisturePercent(player)
                            assert.spy(GetMoisture).was_called(1)
                            assert.spy(GetMoisture).was_called_with(match.is_ref(player))
                        end)
                    end)

                    it("should return the moisture percent", function()
                        EachPlayer(function(player)
                            assert.is_equal(0, playerdevtools:GetMoisturePercent(player))
                        end)
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        EachPlayer(function(player)
                            AssertChainNil(function()
                                assert.is_nil(playerdevtools:GetMoisturePercent(player))
                            end, player, "GetMoisture")
                        end)
                    end)
                end)
            end)

            describe("GetTemperature", function()
                TestWhenThePlayerIsNotPassed(describe, it, before_each, "GetTemperature")

                describe("when the player is passed", function()
                    local GetTemperature

                    before_each(function()
                        EachPlayer(function(player)
                            player.GetTemperature = spy.new(ReturnValueFn(20))
                        end)
                    end)

                    it("should call the player GetTemperature()", function()
                        EachPlayer(function(player)
                            GetTemperature = player.GetTemperature
                            assert.spy(GetTemperature).was_not_called()
                            playerdevtools:GetTemperature(player)
                            assert.spy(GetTemperature).was_called(1)
                            assert.spy(GetTemperature).was_called_with(match.is_ref(player))
                        end)
                    end)

                    it("should return the temperature", function()
                        EachPlayer(function(player)
                            assert.is_equal(20, playerdevtools:GetTemperature(player))
                        end)
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        EachPlayer(function(player)
                            AssertChainNil(function()
                                assert.is_nil(playerdevtools:GetTemperature(player))
                            end, player, "GetTemperature")
                        end)
                    end)
                end)
            end)
        end)
    end)
end)
