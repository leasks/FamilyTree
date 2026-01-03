Feature: Character Death

	Scenario: Game ends when no descendants
		Given I have no descendants
		When I die
		Then the game is over

	Scenario: Game continues when at least one descendant
		Given I have at least one descendant
		When I die
		Then the game is not over

	Scenario: Inheritance to eldest son
		Given John is married with children
		And John has 100 coins
		And inheritance is to the eldest son
		When John dies
		Then his son inherits all the coins
		And his wife inherits nothing

	Scenario: Fair inheritance to spouse
		Given John is married with children
		And John has 100 coins
		And inheritance is fair
		When John dies
		Then his wife inherits all the coins
		And his children inherit nothing

	Scenario: Inheritance when spouse has died
		Given John has 2 children, 1 girl and 1 boy
		And his wife has died
		And John has 100 coins
		And inheritance is only to the eldest boy
		When John dies
		Then his son inherits all his coins

	Scenario: Inheritance to eldest son among multiple boys
		Given John has 2 children, both boys
		And John has 100 coins
		And inheritance is only to the eldest boy
		When John dies
		Then his eldest son inherits all his coins

	Scenario: Fair inheritance among all children
		Given John has 3 children
		And John has 120 coins
		And inheritance is fair
		When John dies
		Then each child inherits 40 coins
