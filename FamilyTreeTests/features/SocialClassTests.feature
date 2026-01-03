Feature: Social Class Tests

	Scenario: Job requires social class
		Given being a local administrator requires you to be part of the local elite class
		And Chris is not part of the local elite
		When he tries to get a job
		Then he is not able to become a local administrator

	Scenario: Gaining social class enables job
		Given Chris has become part of the local elite
		When he tries to get a job
		Then he is allowed to be a local administrator

	Scenario: Job without social class requirement
		Given being a farm hand requires no social class
		And Jane is part of the Peregrini only
		When she tries to get a job
		Then she can become a farm hand

	Scenario: Social mobility through wealth
		Given Barry is currently a Roman citizen
		When he acquires a lot of wealth
		Then his social class changes to Decuriones

	Scenario: Social class through marriage
		Given Anna is currently a Peregrini
		When she marries Barry
		Then her social class changes to Decuriones
		And she gains Roman citizenship

	Scenario: Losing social class through poverty
		Given Barry is not very prudent with his money
		When he loses it all
		Then both he and Anna drop back down to Roman citizens

	Scenario: Marriage within social class
		Given Dave is part of the upper class
		And Jane is part of the lower class
		And marriage is kept within class
		When Dave looks to marry
		Then he does not marry Jane

	Scenario: Marriage across social classes
		Given Jane is now part of the upper classes
		When Dave looks to marry
		Then he does marry Jane
