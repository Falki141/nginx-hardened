package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	// Check if nginx responds to HTTP requests
	if !checkNginxHTTP() {
		fmt.Fprintln(os.Stderr, "Healthcheck failed: nginx not responding to HTTP requests")
		os.Exit(1)
	}

	fmt.Println("Healthcheck successful: nginx is running and reachable")
	os.Exit(0)
}

// checkNginxHTTP checks if nginx responds to HTTP requests
func checkNginxHTTP() bool {
	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	resp, err := client.Get(fmt.Sprintf("http://127.0.0.1:%s/_health", os.Getenv("NGINX_PORT")))
	if err != nil {
		fmt.Fprintf(os.Stderr, "HTTP check error: %v\n", err)
		return false
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		fmt.Fprintf(os.Stderr, "HTTP check failed: status code %d\n", resp.StatusCode)
		return false
	}

	return true
}
