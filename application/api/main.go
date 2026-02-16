// This is a simple HTTP API for retrieving and managing
// world city time information stored in the container. 
// It provides endpoints to:
//   - Fetch the current local time for a specific city (/time/{city})
//   - Fetch the current local time for all predefined cities (/time)
//   - Add a new city and its time zone to the in‑memory list (/time/cities)
//   - Remove an existing city from the list (/time/cities/{city})
//
// The server uses the chi router with logging and panic‑recovery middleware,
// stores city/time‑zone mappings in memory, and formats all time responses
// in JSON. It listens on port 8080 and handles time zone data using Go’s 
// built‑in time package and tzdata.
//
// This is a demo application and the code/functionality was not the primary
// focus of this project.

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	_ "time/tzdata"
)

// CityTime represents the time in a particular city
type CityTime struct {
	City      string `json:"city"`
	LocalTime string `json:"local_time"`
}

// City represents a city with its time zone
type City struct {
	Name     string `json:"name"`
	TimeZone string `json:"time_zone"`
}

// Mapping of city names to their respective time zones
var cities = map[string]string{
	"New_York":      "America/New_York",
	"London":        "Europe/London",
	"Tokyo":         "Asia/Tokyo",
	"Sydney":        "Australia/Sydney",
	"Mumbai":        "Asia/Kolkata",
	"San_Francisco": "America/Los_Angeles",
	"Paris":         "Europe/Paris",
	"Dubai":         "Asia/Dubai",
}

// Get the current time for a specific city
func getTimeByCity(w http.ResponseWriter, r *http.Request) {
	city := chi.URLParam(r, "city")

	timeZone, exists := cities[city]
	if !exists {
		http.Error(w, "City not found", http.StatusNotFound)
		return
	}

	loc, err := time.LoadLocation(timeZone)
	if err != nil {
		http.Error(w, "Could not load location", http.StatusInternalServerError)
		return
	}

	localTime := time.Now().In(loc).Format(time.RFC3339)
	cityTime := CityTime{
		City:      city,
		LocalTime: localTime,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(cityTime); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// Get the current time for all cities
func getAllCityTimes(w http.ResponseWriter, r *http.Request) {
	var cityTimes []CityTime

	for city, timeZone := range cities {
		loc, err := time.LoadLocation(timeZone)
		if err != nil {
			http.Error(w, "Could not load location", http.StatusInternalServerError)
			return
		}

		localTime := time.Now().In(loc).Format(time.RFC3339)
		cityTimes = append(cityTimes, CityTime{
			City:      city,
			LocalTime: localTime,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(cityTimes); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// Add a new city to the map
func addCity(w http.ResponseWriter, r *http.Request) {
	var newCity City
	if err := json.NewDecoder(r.Body).Decode(&newCity); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	if _, exists := cities[newCity.Name]; exists {
		http.Error(w, "City already exists", http.StatusConflict)
		return
	}

	if _, err := time.LoadLocation(newCity.TimeZone); err != nil {
		http.Error(w, "Invalid time zone", http.StatusBadRequest)
		return
	}

	cities[newCity.Name] = newCity.TimeZone
	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "City added successfully")
}

// Remove a city from the map
func removeCity(w http.ResponseWriter, r *http.Request) {
	city := chi.URLParam(r, "city")

	if _, exists := cities[city]; !exists {
		http.Error(w, "City not found", http.StatusNotFound)
		return
	}

	delete(cities, city)
	w.WriteHeader(http.StatusNoContent)
}

func main() {
	r := chi.NewRouter()

	// Use some chi for logging and recovering from panics
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	// Define routes/endpoints
	r.Get("/time/{city}", getTimeByCity)
	r.Get("/time", getAllCityTimes)
	r.Post("/time/cities", addCity)
	r.Delete("/time/cities/{city}", removeCity)

	server := &http.Server{
		Addr:         ":8080",
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  15 * time.Second,
		Handler:      r,
	}

	fmt.Println("Starting server...")
	fmt.Println("Server is listening on port 8080...")
	log.Fatal(server.ListenAndServe())
}
