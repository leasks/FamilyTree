Feature: Starvation and Taxation Test

	Scenario: Food is needed every year
		Given John has no food resource
		When the game advances by 1 year
		Then John has starvation as an injury
		And his health decreases

	Scenario: Acquiring food removes starvation
		Given John has starvation as an injury
		And he has now found food as a resource
		When the game advances by 1 year
		Then John no longer has starvation

	Scenario: Food can be shared with your spouse
		Given John has 2 food resources
		And he is married to Jane
		And Jane has no food resources
		When the game advances by 1 year
		Then neither John nor Jane are starving
		And John now has 0 food resources

	Scenario: Food can be shared with children
		Given John has 4 food resourcea
		And he is married to Jane who has 0 food
		And he has 2 children who also have 0 food
		When the game advances by 1 year
		Then none of John, Jane or the children are starving
		And John now has 0 food resources

	Scenario: Children will be prioritised for food
		Given John has 2 food resourcea
		And he is married to Jane who has 0 food
		And he has 2 children who also have 0 food
		When the game advances by 1 year
		Then neither of the children are starving
		But John and Jane are starving
		And John now has 0 food resources
		
	Scenario: The youngest child will be prioritised for food
		Given John has 1 food resourcea
		And he is married to Jane who has 0 food
		And he has 2 children who also have 0 food
		When the game advances by 1 year
		Then the youngest child is not starving
		But John and Jane are starving
		And the eldest child is starving
		And John now has 0 food resources