Feature: Rates Tests

	Scenario: Age based rates
		Given Jane was born on 12/03/1978
		And there are age ranges with different rates
		When the game year is 2000
		Then the rate for Jane should match the first age range rate

	Scenario: Age based rates change over time
		Given Jane was born on 12/03/1978
		And there are age ranges with different rates
		When the game year is 2006
		Then the rate for Jane should match the second age range rate

	Scenario: No rate applies when outside age ranges
		Given Jane was born on 12/03/1978
		And there are age ranges with different rates
		When the game year is 2023
		Then the rate for Jane should be 0

	Scenario: Rates are loaded from configuration
		When the configuration is loaded
		Then at least one rate is available
