# Levels

> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.

Levels are drawn as text, one character per tile. You can sketch a level in any text editor or on grid paper.

| Character | Meaning |
| --- | --- |
| # | Wall |
| . | Open floor |
| , | Narrow doorway |
| ~ | Flooded floor |
| S | Safe room floor |
| 1 2 3 | Starting locations (level 1 only) |
| P | Arrival point from the stairs above |
| N | Companion |
| > | Stairs down |
| m | Monster (rat on dry floor, leech in water) |
| G | Large monster |
| i | Item spawn (random item) |

## Level 1: The Intake

Timer: 30 minutes. Starting locations: The Break Room, The Lost Property Office, The Boiler Lounge.

```
##################################
#SSSSS#......,......#~~~~~~~~~~~~#
#S1NSS#..i...#..m...#~~~m~~~~i~~~#
#SSSSS,......#......,~~~~~~~~~~~~#
#SSSSS#......#..i...#~~~~~m~~~~>~#
#SSSSS#..m...#......#~~i~~~~~~~~~#
###,#######,####,#######,#########
#......#.........#.........#SSSSS#
#..i...#....m....,......m..,S2NSS#
#......,.........#.........#SSSSS#
#...m..#....i....#....i....#######
#......#.........#..........m....#
####,######,###########,##########
#SSSSS#~~~#......,...............#
#S3NSS,~m~,..i...#....G......>...#
#SSSSS#~~~#......#...........i...#
#SSSSS#~i~#..m...#...............#
##################################
```

## Level 2: The Sorting Floor

Timer: 40 minutes.

```
##############################
#SSSS#......,.......#~~~~~~~~#
#SPPS,..m...#...m...,~~m~~~i~#
#SSSS#......#.......#~~~~~~~~#
###,####,#######,######,######
#.......#...........#........#
#..m....,.....G.....,...m....#
#...i...#...........#....i...#
####,#######,###########,#####
#~~~~~~~#........#...........#
#~m~~i~~,...m....,.....>.....#
#~~~~~~~#........#...........#
##############################
```

## Level 3: The Concourse

Timer: 60 minutes.

```
########################
#SSSSSSSSSS#...........#
#SSSSSSSSSS,....m......#
#SSSPSSPSSS#.......i...#
#SSSSSSSSSS#...........#
#SSSSSSSSSS,......m....#
#SSSSSSSSSS#...........#
####,###################
#..........,...........#
#...m...i..#.....G.....#
#..........#...........#
########################
```

## Set pieces

For each place you have in mind:

| Field | What to write |
| --- | --- |
| Name | What the show calls it |
| Level | Which level it is on, or "any" |
| Look | What the place looks like |
| The twist | The rule that makes this place different |
| Creatures | What lives there |
| Boss or goal | What ends it |
| Reward | What a crawler gets for finishing |

## Your level ideas
