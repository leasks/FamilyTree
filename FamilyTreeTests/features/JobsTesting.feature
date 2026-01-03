Feature: Jobs Testing

	Scenario: Job distribution on event
		Given the Norman Conquest event introduces approximately 1000 Normans to the game
		And the roles of Spearman, Archer and Cavalry are evenly distributed
		And everyone to be added is over the minimum age of these jobs
		When the event is triggered
		Then there will be characters with Spearman, Archer and Cavalry jobs created
		And no-one with a job of Games Developer is created

	Scenario: Jobs are given to right ages and genders
		Given the Norman Conquest event introduces approximately 1000 Normans to the game
		And the roles of Spearman, Archer and Cavalry are evenly distributed
		And Spearman is a role performed only by men over the age of 25
		When the event is triggered
		Then there will be no female spearmen
		And no spearmen under the age of 25

	Scenario: Reaching the age to get a job
		Given Fred is 23 years old
		And he has no job
		And to become an Iron Smith you must be at least 25 years old
		And this is the only available job
		When Fred turns 24
		Then he will remain without a job

	Scenario: Getting a job when old enough
		Given Fred is now 24
		And he still has no job
		When Fred turns 25
		Then he has become an Iron Smith

	Scenario: Jobs and affiliations
		Given Jeff is a Roman
		And a Warrior job is only for Celts
		When he seeks a job
		Then he does not become a Warrior

	Scenario: Job requires skills
		Given to become an Iron Smith you need to learn metal working skills
		And John does not have any metal working skills
		When he seeks a job
		Then he does not become an Iron Smith

	Scenario: Learning skills over time
		Given John is an Iron Smith Apprentice
		And working 5 years as Iron Smith Apprentice equips you with metal working skills
		When John has been an Iron Smith for 3 years
		Then he still does not have metal working skills

	Scenario: Skill mastery after sufficient time
		Given John is an Iron Smith Apprentice
		And working 5 years as Iron Smith Apprentice equips you with metal working skills
		When John has been an Iron Smith for 5 years
		Then he now has metal working skills

	Scenario: Getting qualified job after learning skills
		Given to become an Iron Smith you need to learn metal working skills
		And working 5 years as Iron Smith Apprentice equips you with metal working skills
		And John is working as an Iron Smith Apprentice
		And he has been doing that job for 5 years
		When he seeks a job
		Then he does become an Iron Smith

	Scenario: Job gives affiliation
		Given Harry is Celtic
		And the job of Auxilia is reserved for non-Romans
		But gives the affiliation of Roman
		When Harry becomes an Auxilia
		Then he is additionally affiliated with Roman

	Scenario: Job blocks certain affiliations
		Given John is Roman
		When he looks for a job
		Then he cannot become an Auxilia

	Scenario: Job requires pure affiliation
		Given Harry is Celtic
		And he is an Auxilia so has gained Roman affiliation
		And Legionary is a job for pure Romans only
		When Harry tries to become a Legionary
		Then he is rejected and has to remain an Auxilia

	Scenario: Job limits per affiliation
		Given there can be only one tribal leader
		And it is the only job defined
		And someone already has the job
		When a character tries to find a job
		Then they do not get the job

	Scenario: Job available for new affiliation
		Given a new affiliation is added to the game
		And there is a new person with that affiliation
		When they try to find a job
		Then they can become the tribal leader

	Scenario: Job succession on death
		Given the original tribe's leader dies
		When the second person in that tribe tries to find a job
		Then they become the tribal leader

	Scenario: Family job inheritance
		Given Bert is a tribal leader
		And he has a son, George
		When Bert dies
		Then George becomes tribal leader

	Scenario: Job succession without descendants
		Given George is the tribal leader
		But he has no descendants
		When he dies
		Then the tribal leader is someone else from the tribe

	Scenario: Following parent's profession
		Given Arnie is a Blacksmith
		And he has a son, Fred
		And it is 100% likely that children will follow their parent's footsteps
		When Fred looks for a job
		Then he will follow the same profession type as his father
