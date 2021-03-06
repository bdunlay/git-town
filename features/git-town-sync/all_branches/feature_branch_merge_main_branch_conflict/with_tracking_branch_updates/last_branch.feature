Feature: git-town sync --all: handling merge conflicts between feature branch and main branch

  Background:
    Given I have feature branches named "feature-1" and "feature-2"
    And the following commits exist in my repository
      | BRANCH    | LOCATION         | MESSAGE                 | FILE NAME            | FILE CONTENT             |
      | main      | remote           | main commit             | conflicting_file     | main content             |
      | feature-1 | local and remote | feature-1 commit        | feature1_file        | feature-1 content        |
      | feature-2 | local            | feature-2 local commit  | conflicting_file     | feature-2 local content  |
      |           | remote           | feature-2 remote commit | feature2_remote_file | feature-2 remote content |
    And I am on the "main" branch
    And I have an uncommitted file
    When I run `git-town sync --all`


  Scenario: result
    Then it runs the commands
      | BRANCH    | COMMAND                              |
      | main      | git fetch --prune                    |
      |           | git add -A                           |
      |           | git stash                            |
      |           | git rebase origin/main               |
      |           | git checkout feature-1               |
      | feature-1 | git merge --no-edit origin/feature-1 |
      |           | git merge --no-edit main             |
      |           | git push                             |
      |           | git checkout feature-2               |
      | feature-2 | git merge --no-edit origin/feature-2 |
      |           | git merge --no-edit main             |
    And I get the error
      """
      To abort, run "git-town sync --abort".
      To continue after you have resolved the conflicts, run "git-town sync --continue".
      To skip the sync of the 'feature-2' branch, run "git-town sync --skip".
      """
    And I end up on the "feature-2" branch
    And my uncommitted file is stashed
    And my repo has a merge in progress


  Scenario: aborting
    When I run `git-town sync --abort`
    Then it runs the commands
      | BRANCH    | COMMAND                                              |
      | feature-2 | git merge --abort                                    |
      |           | git reset --hard <%= sha 'feature-2 local commit' %> |
      |           | git checkout feature-1                               |
      | feature-1 | git checkout main                                    |
      | main      | git stash pop                                        |
    And I end up on the "main" branch
    And I again have my uncommitted file
    And I have the following commits
      | BRANCH    | LOCATION         | MESSAGE                            | FILE NAME            |
      | main      | local and remote | main commit                        | conflicting_file     |
      | feature-1 | local and remote | feature-1 commit                   | feature1_file        |
      |           |                  | main commit                        | conflicting_file     |
      |           |                  | Merge branch 'main' into feature-1 |                      |
      | feature-2 | local            | feature-2 local commit             | conflicting_file     |
      |           | remote           | feature-2 remote commit            | feature2_remote_file |


  Scenario: skipping
    When I run `git-town sync --skip`
    Then it runs the commands
      | BRANCH    | COMMAND                                              |
      | feature-2 | git merge --abort                                    |
      |           | git reset --hard <%= sha 'feature-2 local commit' %> |
      |           | git checkout main                                    |
      | main      | git push --tags                                      |
      |           | git stash pop                                        |
    And I end up on the "main" branch
    And I again have my uncommitted file
    And I have the following commits
      | BRANCH    | LOCATION         | MESSAGE                            | FILE NAME            |
      | main      | local and remote | main commit                        | conflicting_file     |
      | feature-1 | local and remote | feature-1 commit                   | feature1_file        |
      |           |                  | main commit                        | conflicting_file     |
      |           |                  | Merge branch 'main' into feature-1 |                      |
      | feature-2 | local            | feature-2 local commit             | conflicting_file     |
      |           | remote           | feature-2 remote commit            | feature2_remote_file |


  Scenario: continuing without resolving the conflicts
    When I run `git-town sync --continue`
    Then it runs no commands
    And I get the error "You must resolve the conflicts before continuing"
    And I am still on the "feature-2" branch
    And my uncommitted file is stashed
    And my repo still has a merge in progress


  Scenario: continuing after resolving the conflicts
    Given I resolve the conflict in "conflicting_file"
    And I run `git-town sync --continue`
    Then it runs the commands
      | BRANCH    | COMMAND              |
      | feature-2 | git commit --no-edit |
      |           | git push             |
      |           | git checkout main    |
      | main      | git push --tags      |
      |           | git stash pop        |
    And I end up on the "main" branch
    And I again have my uncommitted file
    And I have the following commits
      | BRANCH    | LOCATION         | MESSAGE                                                        | FILE NAME            |
      | main      | local and remote | main commit                                                    | conflicting_file     |
      | feature-1 | local and remote | feature-1 commit                                               | feature1_file        |
      |           |                  | main commit                                                    | conflicting_file     |
      |           |                  | Merge branch 'main' into feature-1                             |                      |
      | feature-2 | local and remote | feature-2 local commit                                         | conflicting_file     |
      |           |                  | feature-2 remote commit                                        | feature2_remote_file |
      |           |                  | Merge remote-tracking branch 'origin/feature-2' into feature-2 |                      |
      |           |                  | main commit                                                    | conflicting_file     |
      |           |                  | Merge branch 'main' into feature-2                             |                      |


  Scenario: continuing after resolving the conflicts and committing
    Given I resolve the conflict in "conflicting_file"
    And I run `git commit --no-edit; git-town sync --continue`
    Then it runs the commands
      | BRANCH    | COMMAND           |
      | feature-2 | git push          |
      |           | git checkout main |
      | main      | git push --tags   |
      |           | git stash pop     |
    And I end up on the "main" branch
    And I again have my uncommitted file
    And I have the following commits
      | BRANCH    | LOCATION         | MESSAGE                                                        | FILE NAME            |
      | main      | local and remote | main commit                                                    | conflicting_file     |
      | feature-1 | local and remote | feature-1 commit                                               | feature1_file        |
      |           |                  | main commit                                                    | conflicting_file     |
      |           |                  | Merge branch 'main' into feature-1                             |                      |
      | feature-2 | local and remote | feature-2 local commit                                         | conflicting_file     |
      |           |                  | feature-2 remote commit                                        | feature2_remote_file |
      |           |                  | Merge remote-tracking branch 'origin/feature-2' into feature-2 |                      |
      |           |                  | main commit                                                    | conflicting_file     |
      |           |                  | Merge branch 'main' into feature-2                             |                      |
