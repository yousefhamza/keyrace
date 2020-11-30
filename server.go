package main

import (
	"fmt"
	"net/http"
	"sort"
	"strconv"
)

var scoreboards map[string]map[string]int

// ByCount implements sort.Interface for []player based on
// the score field.
type byCount []player

type player struct {
	name  string
	score int
}

// Len is part of sort.Interface.
func (s byCount) Len() int {
	return len(s)
}

// Swap is part of sort.Interface.
func (s byCount) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

// Less is part of sort.Interface.
func (s byCount) Less(i, j int) bool {
	return s[i].score > s[j].score
}

func count(w http.ResponseWriter, req *http.Request) {
	fmt.Println(req.URL.String())

	count, err := strconv.Atoi(req.URL.Query()["count"][0])
	if err != nil {
		fmt.Fprintf(w, "Errror parsing count")
		return
	}

	keys, ok := req.URL.Query()["name"]
	if !ok || len(keys[0]) < 1 {
		return
	}
	name := keys[0]

	keys, ok = req.URL.Query()["team"]
	if !ok || len(keys[0]) < 1 {
		return
	}
	team := keys[0]

	if _, ok := scoreboards[team]; !ok {
		scoreboards[team] = make(map[string]int)
	}

	scoreboard, ok := scoreboards[team]
	if ok {
		fmt.Fprintf(w, "updated count for %s from %d to %d\n", name, scoreboard[name], count)
		scoreboard[name] = count
	}
}

func index(w http.ResponseWriter, req *http.Request) {
	fmt.Println(req.URL.String())

	team := req.URL.Query()["team"][0]
	scoreboard := scoreboards[team]

	// Create an array of the players and sort them.
	// Long term this is not ideal since we are iterating over every member of the
	// team every single time. If we change the main scoreboards variable to be
	//		var scoreboards = map[string][]player
	// then have an array of players versus the existing map. The existing map allows
	// us to find the player and update the score easily since the name of the player is the key in the map.
	// If we change the map to an array, then we need to iterate over the items in the array when
	// we want to update the count. So in a trade-off we do the iterating here. Should
	// speed of getting the leaderboard matter in the future this would need to be
	// revisited and refactored.
	var players = []player{}
	for name, score := range scoreboard {
		players = append(players, player{name: name, score: score})
	}
	sort.Sort(byCount(players))

	for _, player := range players {
		fmt.Fprintf(w, "%-20s%d\n", player.name, player.score)
	}
}

func main() {
	scoreboards = make(map[string]map[string]int)

	http.HandleFunc("/count", count)
	http.HandleFunc("/", index)

	http.ListenAndServe(":80", nil)
}
