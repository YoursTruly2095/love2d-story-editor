# love2d-story-editor
An editor for creating branching stories in love2d

Create stories with a branching tree structure, with options the player can select to
move to different nodes in the story. Each node can have multiple texts, which are 
selected based on the player's status. Which options are available is also controllable
by player status, and selecting an option can cause player status to be updated.

Player status variables are keys (arbitrary strings) associated with integer values. 
Alternate node text and options can check for a player status being ==, < or > a 
specific number. In the case of node text, the last text where the player status 
meets all requirements will be displayed. In the case of options, all options where 
the player status meets the option requirements will be displayed.

Selecting an option has results, which change as many player status variables as 
required. Opterators for changing player status are =, ++, --, += and -=.

Requirements for alternate text and options, and results for options, are specified as 
strings with individual elements separated by ; characters.

Stories can be saved to file and loaded from file. It is envisioned that stories written
in the editor could be loaded into a love2d based game.

The editor has a play mode that allows the stories to be played. During play mode, you 
can freely edit the player status to simulate other events happening in a actual game.

The editor shows a basic graphical map of the story tree.

Uses a hacked up version of https://github.com/HTV04/suit-compact, with a lot of changes 
for multiline editing and cut / paste. I know I should improve my git-fu so that I could
pull that code from a different repo. Readme and license for suit included.

Uses a copy of https://github.com/gvx/Smallfolk, unmodified. This is supposed to be 
deprecated but I like the human readability of the files generated. Readme and license
for Smallfolk is included.
