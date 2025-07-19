local RoundManager = {}

local ConfigSpace = require(game.ServerScriptService.Configure_Space)
local Globals = require(game.ServerScriptService.Globals)
local HintManager = require(game.ServerScriptService.HintManager)
local GraphDrawer = require(game.ServerScriptService.GraphDrawer)
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local RoundSummary = Instance.new("RemoteEvent", Rep)
RoundSummary.Name  = "RoundSummary"
local HintUpdate = Rep:WaitForChild("HintUpdate")
local StartQuestion  = Instance.new("RemoteEvent", Rep)
local ShowCorrectAnswer = Rep:WaitForChild("ShowCorrectAnswer")
StartQuestion.Name   = "StartQuestion"



--Question order table sorts player responses in order of how quickly they answered
--First person to answer correctly is ranked #1, and so on
local responseOrder = {}
local roundScore = {}
local answersByPlayer = {}
local questionsAsked = 0
local activeRound = nil


function RoundManager.resetAnswersByPlayer()
	answersByPlayer = {}
end

function RoundManager.getPlayerAnswers(plr)
	return answersByPlayer[plr]
end

function RoundManager.setPlayerAnswers(plr, elapsed, correct)
	answersByPlayer[plr] = {elapsed = elapsed, correct = correct}
end


function RoundManager.setActiveQuestion(roundData)
	activeRound = roundData
end

function RoundManager.getActiveQuestion()
	return activeRound
end

function RoundManager.clearActiveQuestion()
	activeRound = nil
end


function RoundManager.resetResponseOrder()
	responseOrder = {}
end

function RoundManager.addToResponseOrder(plr, time)
	table.insert(responseOrder, {plr = plr, time = time})
end


function RoundManager.getResponseOrder()
	return responseOrder
end

function RoundManager.sortResponseOrder()
	table.sort(responseOrder, function(a,b) return a.time < b.time end)
end


function RoundManager.startQuestionForClients(def)
	for _, player in ipairs(Players:GetPlayers()) do
		HintUpdate:FireClient(player, HintManager.Get(player))
	end
	----------------------------
	StartQuestion:FireAllClients(nil, def.answerIds, Globals.ROUND_TIME, def.correctNumber)
end

function RoundManager.endQuestionForClients(def)
	ShowCorrectAnswer:FireAllClients(Globals.numberMap[RoundManager.getActiveQuestion().correctNumber])
	for _,plr in pairs(Players:GetPlayers()) do
		plr:SetAttribute("RoundPlayed", plr:GetAttribute("RoundPlayed") + 1)
	end
end


function RoundManager.shuffle(def)
	local shuffled = {}
	if not def.answerIds then
		print("Answer choices haven't been configured for this graph.")
	end
	for i, id in ipairs(def.answerIds) do
		table.insert(shuffled, {id = id, isCorrect = (i == def.correctNumber)})
	end

	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local answerIds = {}
	local correctNumber
	for i, entry in ipairs(shuffled) do
		answerIds[i] = entry.id
		if entry.isCorrect then
			correctNumber = i
		end
	end

	def.answerIds = answerIds
	def.correctNumber = correctNumber

	for _, player in ipairs(Players:GetPlayers()) do
		HintUpdate:FireClient(player, HintManager.Get(player))
	end
	----------------------------
	StartQuestion:FireAllClients(nil, answerIds, Globals.ROUND_TIME, correctNumber)
end

function RoundManager.rankPlayersByTime()
	RoundManager.sortResponseOrder()
	
	local playerCount = #Players:GetPlayers()
	for idx, entry in ipairs(responseOrder) do
		local p = entry.plr
		local rank = idx       
		local pts  = Globals.PER_QUESTION_POINTS[math.min(rank, #(Globals.PER_QUESTION_POINTS))]
		roundScore[p] = (roundScore[p] or 0) + pts
	end
end

function RoundManager.prepBeforeNextQuestion(def)
	--Ensure that the y-axis is the vertical axis for the next question. This will be overriden only if the question is a surface.
	GraphDrawer.Clear()
	ConfigSpace.swap_coordinate_axes("y")
	if def.Surface then
		ConfigSpace.configureSpaceHard()
		ConfigSpace.swap_coordinate_axes("z")
	else 
		ConfigSpace.configureSpaceEasy()
	end
	RoundManager.resetResponseOrder()
	RoundManager.resetAnswersByPlayer()
	questionsAsked += 1
end

function RoundManager.podiumList()
	local list = {}
	for plr, pts in pairs(roundScore) do
		table.insert(list, {plr = plr, pts = pts})
	end
	
	table.sort(list, function(a,b) return a.pts > b.pts end)

	local playerCount = #Players:GetPlayers()
	if list[1] and not Globals.use_minimum_points() then
		print("Awarding a win to " .. list[1].plr.Name)
		list[1].plr.leaderstats.Wins.Value += 1
	else
		print("No win awarded because there are less than " .. Globals.MIN_PLAYERS_FOR_FULL_SCORING .. " players.")
	end

	RoundSummary:FireAllClients(list)

	roundScore = {}
	questionsAsked = 0
end



return RoundManager
