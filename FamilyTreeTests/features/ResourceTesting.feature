Feature: Resource Testing

	Scenario: Job requires resource
		Given becoming a warrior requires a sword
		And John does not have a sword
		When he looks for a job
		Then he has to remain unemployed

	Scenario: Getting job with required resource
		Given John has now obtained a sword
		When he looks for a job
		Then he can become a warrior

	Scenario: Job produces resources
		Given Dave is an Iron Smith
		And Iron Smiths produce 10 swords a year
		When the year ticks over
		Then Dave now possesses 10 swords

	Scenario: Trading resources
		Given Dave wants to sell a sword
		And Bert wants to buy a sword
		When trading happens
		Then they are matched for the trade

	Scenario: Cannot afford to buy resource
		Given buying a sword costs 5 coins
		And John has 4 coins
		When he tries to buy a sword
		Then he is not able to buy one

	Scenario: Can afford to buy resource
		Given John now has 5 coins
		When he tries to buy a sword
		Then he is able to buy one
		And he no longer has any coins

	Scenario: Non-inherited resources
		Given wheat is a non-inherited resource
		And Daphne has wheat
		And she also has a child
		When Daphne dies
		Then the child has not inherited the wheat

	Scenario: Inherited resources
		Given coin is an inherited resource
		And Barry has coins
		And also a child
		When Barry dies
		Then the child inherits the coins

	Scenario: Inherited resource put up for sale
		Given Dave is a warrior
		And has a sword
		And has a daughter who is a farm hand
		And has no wife or other descendants
		When Dave dies
		Then his daughter inherits the sword
		And she puts it up for sale as it is not needed for her job

	Scenario: Inherited resource kept for upskilling
		Given Alex is a chariot rider
		And has a chariot
		And has a son who is a warrior
		And has no wife or other descendants
		When Alex dies
		Then his son inherits the chariot
		And keeps it as he can upskill himself
		And becomes a chariot rider

	Scenario: Want resource for job upgrade
		Given Joe is a farm hand
		And to become a farmer requires land and Animal Husbandry skill
		When he has the Animal Husbandry skill
		Then land is added to his wanted resource list

	Scenario: Upskill when resource acquired
		Given Joe is a farm hand
		And to become a farmer requires land and Animal Husbandry skill
		And Joe has the Animal Husbandry skill
		When Joe acquires land
		Then he upskills and becomes a farmer
		And he no longer wants land

	Scenario: Resource produces and expires
		Given being a labourer produces labour as a resource
		And labour as a resource is only valid for one year
		And Harry is a labourer this year
		When the year ticks over
		Then he has produced labour as a resource

	Scenario: Resource expires after time
		Given Harry is now no longer employed
		And he hasn't traded his labour resource
		When the year next ticks over
		Then he no longer has labour in his resources

	Scenario: Non-expiring resources accumulate
		Given being an ironsmith produces 2 swords
		And swords do not expire
		And Harry is now an ironsmith
		When the year ticks over twice
		Then he has produced 4 swords
		And they don't get removed

	Scenario: Resources with lifespan expire
		Given swords now expire after 2 years
		And Harry has created swords over 3 years
		When the third year completes
		Then Harry now has 4 swords as some expired

	Scenario: Needing resources to produce
		Given being a Blacksmith requires labour
		And when you have that the Blacksmith produces a sword and a coin
		And John is a Blacksmith who currently has 1 coin
		And Billy is a Labourer who has 1 labour
		And the exchange rate is 1 coin for 1 labour
		When John goes to do his job
		Then he wants 1 Labour
		And he trades with Billy for 1 coin
		And he produces 1 sword
		And Billy has 1 coin and 1 new labour

	Scenario: Producing with multiple resource inputs
		Given to a farmer can produce 2 food and 1 coin
		But Food requires 1 labour to create
		And Max is a farmer
		When the game turn ticks around
		Then Max creates 1 food by buying 1 labour from Billy

	Scenario: Producing more with additional labourers
		Given Bert is also a labourer
		And Max has inherited 2 more coins
		When he joins the game and the turn ticks over
		Then Max can now make 2 food
		And Bert and Billy get the coins
