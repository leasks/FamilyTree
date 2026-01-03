Feature: Tree Building

	Scenario: Having first child
		Given John and Jane are married
		When they have their first son
		Then an extra trunk is added to the tree
		And it contains the son

	Scenario: Having second child
		Given John and Jane are married
		And they already have at least one child
		When they have their next child
		Then an extra branch is added to the tree
		And it contains the next child

	Scenario: Child has a child
		Given John and Jane are married
		And they have a daughter who is also married
		When their daughter has a child
		Then an extra trunk is added to the tree
		And it is marked with the child's birthdate and name

	Scenario: Getting married
		Given John meets Jane
		When they get married
		Then Jane is added to the tree
		And marked with the marriage date on the tree

	Scenario: On death
		Given John has a family tree
		When he dies
		Then his death date is set on the tree

	Scenario: Child without married parents
		Given Jeff's mother wants a child
		But she hasn't married Jeff's dad yet
		When Jeff's mother tries to have a child
		Then no child is born

	Scenario: Child inherits both parents' affiliation
		Given Jeff's father is Celtic
		And his mother is Celtic
		And they are married
		When Jeff is born
		Then he is Celtic

	Scenario: Child inherits father's affiliation in patriarchy
		Given Jeff's father is Roman
		And his mother is Celtic
		And the patriarchy is in charge
		When Jeff is born
		Then he is Roman
		But not Celtic

	Scenario: Generating people with gender ratios
		Given an invasion force of Romans is 100% men
		When the invasion happens
		Then no women should be created

	Scenario: Tree depth calculation
		Given Bert is the origin of the tree
		And Sally and Jane are his direct descendants
		And Sally has 2 children and 1 grandchild
		And Jane has none
		When calculating the depth of the family tree
		Then the answer is 4

	Scenario: Tree width calculation
		Given Bert is the origin of the tree
		And Sally and Jane are his direct descendants
		When calculating the width of the family tree
		Then the answer is 2
