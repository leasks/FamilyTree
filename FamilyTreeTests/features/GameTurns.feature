Feature: Game Turns

	Scenario: Game clock moves on
		Given the Game clock is set to January 1910
		When the game turn ends
		Then the Game clock moves to January 1911

	Scenario: Very old character dies
		Given Albert is 120 years old
		And the current life expectancy is 80
		When the game turn ends
		Then Albert is very very likely to have died

	Scenario: Young character survives
		Given Danielle is 8 years old
		And she has no injuries
		And the current life expectancy is 80
		When the game turn ends
		Then she is very very likely to still be alive

	Scenario: Character has a child
		Given Joanna is 21 years old
		And she is trying for a child
		And the current fertility rate for 21 year olds is 100%
		When the game turn ends
		Then she will have a child

	Scenario: NPCs are seeded with necessary wealth for jobs
		Given to be a warrior you need a sword
		When NPCs are created that are warriors
		Then they all have swords in their resource list

	Scenario: NPCs are seeded with necessary skills for jobs
		Given to be a farmer you need the skill of animal husbandry
		When NPCs are created that are farmers
		Then they all have animal husbandry as a skill

	Scenario: NPCs are seeded with necessary wealth for social class
		Given to be a local administrator you need to be at the Decuriones social class
		When NPCs are created that are local administrators
		Then they all have enough wealth to set their social class to Decuriones

	Scenario: Config is loaded
		When the configuration is loaded
		Then affiliations are loaded
		And rates are loaded
		And locations are loaded
		And social classes are loaded
		And events are loaded
		And injuries are loaded
		And jobs are loaded
		And names are loaded
		And resources are loaded
