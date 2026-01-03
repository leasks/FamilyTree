Feature: Injury Testing

	Scenario: Health depletion from poor health
		Given John's Health is currently at 100%
		And having poor health at his age has a mortality of 10%
		When John has poor health
		Then his overall Health drops by up to 10%

	Scenario: Death from poor health when health is low
		Given John's Health is currently at 0.1%
		And having poor health at his age has a mortality of 90%
		When John has poor health
		Then his overall Health is very very likely to now be 0%
		And he is dead

	Scenario: Fatal injury from battle
		Given Dave's Health is currently 100%
		And being killed in battle has a 100% mortality rate
		When Dave is killed in battle
		Then his health drops to 0%
		And he is dead

	Scenario: Getting treated for injuries
		Given Fred has a war wound that is untreated
		And its mortality is 5%
		And his current health is 75%
		When he gets treated
		Then he no longer has a war wound
		And his health remains at 75%

	Scenario: Treatment requires specific location
		Given Fred has a war wound that is untreated
		And he is in a location without a hospital
		And the treatment for war wounds is to go to hospital
		When he looks for treatment
		Then it will not be treated
