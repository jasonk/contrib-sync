# contrib-sync.sh #

Don't you wish that your contributor graph on GitHub could reflect all
the code you write at work, but it doesn't because most of your
"daytime" code lives in a GitHub Enterprise instance (or GitLab, or
Bitbucket or on a shared filesystem or somewhere else).

Me too, so I wrote this `contrib-sync.sh` script to fix that.  This
script finds all your commits in all the repos you tell it to look at
and then it creates a corresponding commit in a private "sync repo".
When you push those commits to GitHub your contributor graph gets
updated to reflect those commits as well.

### Important Security Notes ###

No code from the source repos will be put into the sync repo.  All the
commits created in the sync repo by this script are empty.  The only
information that is actually added to the sync repo for each of the
synced commits is it's date/time and the commit hash.  The date/time
is necessary to get the contribution to count on the appropriate day,
and the commit hash is used as the commit message to prevent commits
from being duplicated if you run the script more than once.

### Usage ###

* Create a new repo on GitHub.com (you probably want it to be private)
* Clone that repo to your workstation
* Copy the `contrib-sync.sh` script from here into your new repo
* Edit the CONFIGURATION OPTIONS as required
* Add the paths to your repos or repo-directories to the list in REPOS
* Run this script
* When it's done, push your commit back to GitHub
* Check your profile to see your new contributor graph
