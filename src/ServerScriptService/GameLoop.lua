-------------------------
-- SERVICE REFERENCES  --
-------------------------
local Rep = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-------------------------
-- MODULE REQUIRES     --
-------------------------
local Globals = require(game.ServerScriptService.Globals)
local GraphDrawer = require(script.Parent.GraphDrawer)
local HintManager = require(game.ServerScriptService.HintManager)
local ConfigSpace = require(game.ServerScriptService.Configure_Space)
local GraphManager = require(game.ServerScriptService.GraphManager)
local VoteManager = require(game.ServerScriptService.VoteManager)
local RoundManager = require(game.ServerScriptService.RoundManager)
local SpecialRoundManager = require(game.ServerScriptService.SpecialRoundManager)
local RoundLibrary = require(Rep.RoundLibrary)
local Preferences = require(game.ServerScriptService:WaitForChild("QuestionPreferenceService"))

-------------------------
-- REMOTE EVENTS       --
-------------------------
local AnswerFeedback = Rep:WaitForChild("AnswerFeedback")
local LeaderboardUpdate = Rep:WaitForChild("LeaderboardUpdate")
local StartNewRound = Rep:WaitForChild("StartNewRound")
local EndRound = Rep:WaitForChild("EndRound")
local SubmitAnswer = Rep:WaitForChild("SubmitAnswer")
local ShowCorrectAnswer = Rep:WaitForChild("ShowCorrectAnswer")

-------------------------
-- REMOTE UI EVENTS    --
-------------------------
local ShowInstructionText = Rep:WaitForChild("ShowInstructionText")
local HideInstructionText = Rep:WaitForChild("HideInstructionText")

-------------------------
-- GLOBAL VARIABLES    --
-------------------------
local before_first_round_time = Globals.before_first_round_time
local rounds_played = 0
local marble_rounds = 0

-------------------------
-- UTILITY STRUCTURES  --
-------------------------
local numberMap = Globals.numberMap

-------------------------
-- INITIALIZATION      --
-------------------------
RoundManager.resetAnswersByPlayer()

SubmitAnswer.OnServerEvent:Connect(function(plr, chosenNumber, elapsed)
	if not RoundManager.getActiveQuestion() then
		return
	end
	if RoundManager.getPlayerAnswers(plr) then
		return
	end

	local is_correct = (chosenNumber == RoundManager.getActiveQuestion().correctNumber)

	if is_correct then
		RoundManager.setPlayerAnswers(plr, elapsed, is_correct) --x
		RoundManager.addToResponseOrder(plr, elapsed)
		local pts = plr.leaderstats.Points
		pts.Value += RoundManager.getActiveQuestion().points
		plr.BestTime.Value = math.min(plr.BestTime.Value, elapsed)
		plr:SetAttribute("RoundCorrect", plr:GetAttribute("RoundCorrect") + 1)
	end

	AnswerFeedback:FireClient(plr, is_correct, chosenNumber)
	LeaderboardUpdate:FireAllClients(plr, is_correct, elapsed)
end)

-------------------------
-- ROUND FUNCTION      --
-------------------------

--[[
    Plays a single round of the game, with the given question definition. 
    
    @param def table -- Table containing data about the question. Fields include:
        - `func`: Function to be graphed
        - `points`: Number of points awarded
        - `surface': Boolean -- If true, the graph is a surface rather than a curve
        - etc.
]]
local function playRound(def)
	RoundManager.prepBeforeNextQuestion(def)
	GraphManager.DrawGraphByType(def)

	local roundData = {
		correctNumber = def.correctNumber,
		points = def.points,
	}
	RoundManager.setActiveQuestion(roundData)
	RoundManager.startQuestionForClients(def)
	task.wait(Globals.ROUND_TIME)
	RoundManager.endQuestionForClients(def)
	RoundManager.clearActiveQuestion()
end

-------------------------
-- MAIN GAME LOOP      --
-------------------------
wait(before_first_round_time)

while true do
	VoteManager.resetVotes()
	VoteManager.vote()
	local finalDifficulty = VoteManager.getWinningDifficulty()

	StartNewRound:FireAllClients()

	for i = 1, Globals.QUESTIONS_PER_ROUND do
		local def
		local entry = Preferences.Dequeue()

		if entry then
			def = RoundLibrary.GetFromCategory(entry.category)
			print("Using player-picked category:", entry.plr.Name, entry.category)
		else
			def = RoundLibrary.GetRoundByDifficulty(finalDifficulty)
		end

		local roll = math.random()
		local pOfSpecial = Globals.pOfSpecial
		local playSpecialRound = not entry and roll < pOfSpecial

		if playSpecialRound then
			local specials = {
				function()
					SpecialRoundManager.playMarbleGuessRound()
				end,
				function()
					SpecialRoundManager.playAreaGuessRound(finalDifficulty)
				end,
				function()
					SpecialRoundManager.playAreaGuessRound(finalDifficulty)
				end,
			}
			local index = math.random(1, #specials)
			specials[index]()
		else
			playRound(def, finalDifficulty)
		end

		RoundManager.rankPlayersByTime()
		GraphDrawer.Clear()
		task.wait(Globals.BETWEEN_TIME)
	end

	EndRound:FireAllClients()
	ConfigSpace.configureSpaceEasy()
	RoundManager.podiumList()
	task.wait(Globals.podium_time)
end
