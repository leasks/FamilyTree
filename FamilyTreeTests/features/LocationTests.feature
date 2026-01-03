Feature: Location Tests

	Scenario: Person moves to new location
		Given Fred is currently in London
		When he moves to Manchester
		Then his location will be Manchester
		And not London

	Scenario: Person moves with family
		Given Fred is currently in London
		And he is married and has 2 children
		And he will be moving with his family
		When he moves to Manchester
		Then his location will be Manchester
		And so will his wife
		And also his children

	Scenario: Person moves without family
		Given Fred is currently in London
		And he is married and has 2 children
		And he will not be moving with his family
		When he moves to Manchester
		Then his location will be Manchester
		But his wife's location will be London
		And also his children will be in London

	Scenario: Child not in same location stays put
		Given Fred is currently in London
		And he is married and has 2 children
		And he will be moving with his family
		But his daughter lives in Liverpool
		When he moves to Manchester
		Then his location will be Manchester
		And his wife's location will be Manchester
		And his son will be in Manchester
		But his daughter will remain in Liverpool

	Scenario: Event adds NPCs to specific location
		Given the Battle of Hastings happens in Hastings
		And will introduce 1000 Normans into the game
		When the year becomes 1066
		Then 1000 Normans are added and their location is set to Hastings

	Scenario: Event adds location-specific injuries
		Given the Great Fire of London happens in London
		And will add "killed in great fire" to the injury list with 100% mortality
		When the year becomes 1666
		Then the people whose cause of death is "killed in great fire" are all located in London
		And no-one outside of London will have that cause of death

	Scenario: Event relocates people by age
		Given WW2 Evacuation is an event where people under the age of 16 in London are evacuated to Wales
		When the year becomes 1940
		Then everyone under the age of 16's location from London should be changed to Wales
		But people under the age of 16 elsewhere remain where they are

	Scenario: Event injuries affect multiple locations
		Given the Blitz is an event impacting London, Manchester and Liverpool
		And it introduces an injury of "killed in air raid" with 100% mortality
		When the year becomes 1941
		Then people whose cause of death is "killed in air raid" are only located in London, Manchester and Liverpool
		And no-one located in Wales has this cause of death

	Scenario: New location before founding date
		Given Liverpool is a place located in the county of Lancashire
		And is in the North West Region
		And is founded in 1207
		When the year is 1206
		Then Liverpool does not exist as an available location

	Scenario: New location after founding
		Given Liverpool is a place located in the county of Lancashire
		And is in the North West Region
		And is founded in 1207
		When the year is 1207
		Then people already in Lancashire/North West will relocate to Liverpool
		And it will exist as a location

	Scenario: Town is abandoned
		Given the town of Disasterville will be razed to the ground in 1515
		And it is located in Middlesex
		When the year is 1515
		Then Disasterville is no longer part of the available locations
		And its inhabitants have relocated to other parts of the county

	Scenario: Hostile takeover of location
		Given it is AD42
		And Canterbury is controlled by the Cantiaci
		And the Romans don't like the Cantiaci
		And when Romans conquer a location they subjugate the ruling tribe
		When the Romans start to take over
		Then the killed in battle injury can occur in Canterbury

	Scenario: Peaceful takeover of location
		Given it is now AD44
		When the Romans have fully taken over Canterbury
		Then Canterbury is controlled by Romans
		And the Cantiaci are converted to Romano British
		And they no longer dislike the Romans
		And the killed in battle injury no longer exists

	Scenario: Friendly takeover has no battle
		Given it is AD45
		And Silchester is controlled by the Atrebates
		And the Romans like the Atrebates
		When the Romans start to take over
		Then it's not hostile and killed in battle injury is not added

	Scenario: New town has no infrastructure
		Given NewTown has just been founded
		When looking at the list of built infrastructure
		Then there are no public buildings
