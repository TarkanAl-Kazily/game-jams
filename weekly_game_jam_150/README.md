# Weekly Game Jam Week 150

May 22nd through May 28th (6 days!)

Jam link: [https://itch.io/jam/weekly-game-jam-150](https://itch.io/jam/weekly-game-jam-150)

# My Goals

- Practice "fail fast" and rapid prototyping based development
- Practice a robust workflow for accomplishing projects large and small:
   - Identify specific project goals for success and completion
   - Develop a plan to accomplish them on time and in budget
   - Achieve tasks in plan and iterate
- Publish the project
   - Start building an online profile/portfolio
   - Release a playable game - the key deliverable
   - Share with my network/social media
   - Document my thoughts and notes along the way, including a post mortem

# Game Jam Theme: "You're the enemy"

Lots of ways to take this, such as:

- Procrastination is the obstacle of accomplishing your goals
- Needing to accept your flaws to progress
- Being hero's main villan like in [Dungeon Keeper](https://en.wikipedia.org/wiki/Dungeon_Keeper)
- Just being evil
- Your progression through the level sets up obstacles for the "next player", which is you

I'm interested in roguelike games, and good at playing simple, turn based games.
As this is my first stab into game development, I don't know exactly my
development strengths, but do plan to bring a layer oriented perspective to
software development.

A mechanic that I am interested in working with is the "Cappy" mechanic
from [Super Mario Odyssey](https://en.wikipedia.org/wiki/Super_Mario_Odyssey)
in which Mario can capture enemies to navigate levels. In this way,
Mario "is" the enemy, at least for a time. How would this work in a roguelike?

# MVP mechanics:

Roguelike comes with a lot of baggage, which I won't deal with. To establish
a playable game in the 6 days, I'm highlighting these major elements:

1. The player, who can move and take actions.
2. The map, in which the player navigates. 
3. Enemies, which stop the player's progress. Key to this game mechanic is that
the player must become the enemy to proceed.
4. Progression towards a goal. The standard roguelike progression is through
floors, culminating in a macguffin.

# Concluding thoughts

1. Pico-8 Development

Pico-8 is really fun to use, despite all of its constraints. I believe that it
is because of these constraints (a minimal instruction set, basic sprites, accessible music editor).
Thinking about how to address these constraints is a fun problem, but I admit I distracted myself
too much with them. In the duration of this game jam, and with my development experience
I never ran into any of the constraints.

2. Fail-fast and prototyping

I think my first level does well to prototype some mechanics, but it doesn't do well
prototyping how the mechanics could evolve, or how the player could enjoy the game.
It is enough to get good feedback on the specific elements present (slime, doors,
switches), which if I was taking this forward I would test more extensively with
alternate ideas (change how player's navigate in different forms, use the additional
action button).

My initial goal was to have a level prototype done by Saturday night (2 days of work),
but did not have this completed until Sunday. I found the most difficult part was
the level design, as I still did not have clarity on the game or puzzles I would
want the player to face. I was more engaged with the software and systems to
support the game.

3. Project workflow

I started strong, and Friday was a good day spent brainstorming ideas related to the
jam theme, setting up broad tasks, and making a basic timeline. I enjoyed this process,
and think it could be improved by practice and by putting it in a form that I am
able to easily revisit. Using a pad of legal paper is easy to write ideas down,
but accessing and revisiting is difficult.

My plan consisted of the MVP mechanics above. I think this way of structuring
my plan didn't work out well as my ideas and design evolved. In particular, these
are not equal chunks of work, and tasks like "Progression towards a goal" is really
the entire game. As such, if approaching a creative project like this from the beginning
again I wouldn't want a task like that. It's too nebulous and vague.

Finally, I acheived, and did some iteration, but found that iterating on game
design principles was very difficult, due to motivation. I recognize this is a
common problem in creative projects, and is a true test of being able to
accomplish a challenging project. I found that I was able to do minor iteration
to fix small problems with background systems, such as in the mob system
(by converting enemy management from individual tasks to a single task), but
realized that the map system would not be sufficient to allow easy development
of levels or puzzles.

4. Publishing

I am going to publish the first level to the game jam (I have already
uploaded to itch.io) as a prototype. This document and repository stores
my thoughts and notes on the project, and is conveniently in a place where I
can refer back to it during later game projects.
