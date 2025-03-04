# Patrol and Logistics System

## Description

This system is designed for managing patrols and logistics tasks in a gaming environment. It includes functions for initializing patrols, managing posts, handling logistics, and interacting with players.

## Installation

1. Copy the files into your project folder.
2. Ensure that all necessary dependencies are installed.
3. Start the server and check that the system works correctly.

## Functions

### Core Functions

- **Patrolling**: Players can initiate patrols, receive tasks, and complete them.
- **Station Duty**: Players can select a post and remain on duty for a specified duration.
- **Logistics**: Players can perform tasks related to transporting materials and receive rewards for their efforts.

### Network Events

The system uses the following network events:

- `RE.Duty.Patrol_Next`: Sends the next patrol point to the player.
- `RE.Duty.Patrol_Arrived`: Handles the player's arrival at a point.
- `RE.Duty.Patrol_End`: Ends the patrol or post.
- `RE.Duty.Station_Select`: Allows the player to select a post.
- `RE.Duty.Fail`: Handles task failure.

### Commands

Players can use text commands to interact with the system:

- `/patrol`: Start patrolling.
- `/patrol_fail`: Cancel the current task.

## Configuration

The system configuration is set in the `DUTIES_CONFIG` file, where you can adjust parameters such as:

- The number of patrol points.
- Rewards for task completion.
- Waiting time at the post.

# License

This system is distributed under the MIT License. You are free to use, modify, and distribute it without restrictions, provided that attribution is given to the author.
