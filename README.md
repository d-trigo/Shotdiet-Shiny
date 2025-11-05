# Shotdiets with Shiny

<img width="2401" height="400" alt="image" src="https://github.com/user-attachments/assets/8c207f1d-4456-48bd-9cc2-aec53c5762ca" />

[Click here to view this application](https://danieltrigo-shotdiet-shiny.share.connect.posit.cloud/)

This project is inspired by the Shotcreator website which is now unfortunately defunct due to API restrictions. I wanted to replicate what Shotcreator had, including leaderboards based on shot type along with shot maps for individual players, while also placing emphasis on being able to easily visualize a player's "shot diet". To accomplish this, I utilized solutions such as SQL in order to review large play-by-play datasets and transform them into meaningful representations of player shooting performance. 

## Why are shot diets important to understand?

Field goal efficiency (FG%) isn't the only part of understanding a player's shooting ability. Certain types of shots, naturally, present with greater difficulty while offering higher reward. Some examples:

- **Drives**, where players are able to make a field goal via running or "driving" through the paint in order to make a lay-up or floater, can indicate how well a player can muscle through NBA-level athleticism and still create their own shot. It also typically provides more scoring opportunities via inducing other players to perform a scoring foul on them as they drive if they're unable to successfully guard their shot.
- **Fadeaways**, where players jump back and make a high arcing shot, are effectively unguardable even against tall NBA defenders.
- **Pullups**, where players shoot an unassisted field goal off the dribble, is another indicator of a player being able to create their own shot even with a mechanically difficult shot type when compared to regular catch-and-shoot threes.

To put it simply: If a player averages higher efficiency on those difficult shot types, it's a solid indicator that they can flourish outside of easier catch-and-shoot opportunities and, in turn, can provide meaningful contributions to or even *lead* a team's offense.


## How do we get this data?
Play-by-play (PBP) data is the bedrock for this application. I use ESPN PBP data provided via hoopR that is then connected to a DuckDB instance. SQL is then utilized via indexing through individual plays and observing the shot type along with using Regex to extract the player's name to avoid the load time of crawling for individual player IDs through the ESPN API.

## What do the % columns mean?
- **Shot type proportion** represents which percentage of a player's total field goal attempts for the season was of a specific shot type, such as a fadeaway or jumper.
- **Shot type efficiency** represents which percentage of that player's shot type attempts were converted into made field goals (in other words, the FG% for that shot type).

## What will be added in the future?
I have already added a simple leaderboard for umbrella shot types. I next plan to add data surrounding shot area efficiency such as at the rim or in the mid-range. I also plan to add time-series graphs showcasing how players have evolved in shot diets and efficiency over the course of the career. 
