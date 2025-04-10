Feature: Affiliations
  To ensure proper handling of affiliations in the game.

  Scenario: Marriage between people of different affiliations
    Given Joanna is a Celt
    And Fred is a Roman
    And Dave is a Norman
    And Celts do not like Normans
    And Celts have no opinion on Romans
    When Joanna is looking to marry
    Then she can marry Fred
    But she won't marry Dave
