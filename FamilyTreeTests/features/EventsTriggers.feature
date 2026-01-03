Feature: Event Triggers

	Scenario: Events are activated
		Given the Black Death is a defined event
		When the year is between 1346 and 1353
		Then bubonic plague is part of the active injury list

	Scenario: Events are deactivated
		Given the Black Death is a defined event
		When the year is after 1353
		Then bubonic plague is not on the active injury list

	Scenario: Removal of NPCs
		Given the collapse of the Roman Empire is a defined event
		When the year is 410AD
		Then all Roman military units are removed from the NPC list
		And all Roman leadership units are removed from the NPC list

	Scenario: Generation of battle events
		Given the tribes of Iceni and Atrebates exist
		And they are located in Caistor St Edmund and Canterbury respectively
		When an inter-tribe battle is generated and triggered for Iceni
		Then Iceni military units have moved to Canterbury
		But their labourers stay where they are

	Scenario: Military units return after battle
		Given the tribes of Iceni and Atrebates are at war started by the Iceni
		When the battle is over
		Then the Iceni military units return to Caistor

	Scenario: Event injuries impact specific jobs and locations
		Given there are people with military jobs and trade jobs in two locations
		And the "killed in battle" injury exists
		And it will be activated by a war event to only affect people in the military
		And it will only impact people in one location
		When the war event happens
		Then only people with military jobs in the one location will have been impacted by the injury

	Scenario: War spreads to multiple locations
		Given the war event is already happening
		When it spreads to a second location
		Then military people in both the first and second location can be injured

	Scenario: War ends in one location
		Given the war is active
		When it stops in location 1
		Then only people in location 2 will be injured

	Scenario: Conversion events
		Given Boudica's revolt happens in AD60-61
		And will result in the formation of the Romano British affiliation
		When it is AD 62
		Then the Iceni, Trinovante and all South East and East Anglia tribes are also affiliated as Romano British
