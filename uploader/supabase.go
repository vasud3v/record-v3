package uploader

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// SupabaseClient handles interactions with Supabase
type SupabaseClient struct {
	URL       string
	APIKey    string
	TableName string
	client    *http.Client
}

// RecordingMetadata represents a recording entry in Supabase
type RecordingMetadata struct {
	ID              string    `json:"id,omitempty"`
	Username        string    `json:"username"`
	Site            string    `json:"site"`
	GoFileURL       string    `json:"gofile_url"`
	GoFileCode      string    `json:"gofile_code"`
	GoFileFileID    string    `json:"gofile_file_id"`
	FileName        string    `json:"file_name"`
	FileSize        int64     `json:"file_size"`
	Duration        float64   `json:"duration"`
	Resolution      int       `json:"resolution"`
	Framerate       int       `json:"framerate"`
	RecordedAt      time.Time `json:"recorded_at"`
	UploadedAt      time.Time `json:"uploaded_at"`
	MD5             string    `json:"md5,omitempty"`
	RoomTitle       string    `json:"room_title,omitempty"`
	Gender          string    `json:"gender,omitempty"`
	NumViewers      int       `json:"num_viewers,omitempty"`
}

// NewSupabaseClient creates a new Supabase client
func NewSupabaseClient(url, apiKey, tableName string) *SupabaseClient {
	return &SupabaseClient{
		URL:       url,
		APIKey:    apiKey,
		TableName: tableName,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// InsertRecording inserts a recording metadata into Supabase
func (s *SupabaseClient) InsertRecording(metadata *RecordingMetadata) error {
	// Set upload timestamp
	metadata.UploadedAt = time.Now()

	// Prepare request body
	body, err := json.Marshal(metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	// Create request
	url := fmt.Sprintf("%s/rest/v1/%s", s.URL, s.TableName)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", s.APIKey)
	req.Header.Set("Authorization", "Bearer "+s.APIKey)
	req.Header.Set("Prefer", "return=representation")

	// Send request
	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Check response
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		var errResp map[string]interface{}
		json.NewDecoder(resp.Body).Decode(&errResp)
		return fmt.Errorf("supabase error (status %d): %v", resp.StatusCode, errResp)
	}

	return nil
}

// GetRecordingsByUsername retrieves all recordings for a specific username
func (s *SupabaseClient) GetRecordingsByUsername(username string) ([]RecordingMetadata, error) {
	url := fmt.Sprintf("%s/rest/v1/%s?username=eq.%s&order=recorded_at.desc", s.URL, s.TableName, username)
	
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", s.APIKey)
	req.Header.Set("Authorization", "Bearer "+s.APIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("supabase error (status %d)", resp.StatusCode)
	}

	var recordings []RecordingMetadata
	if err := json.NewDecoder(resp.Body).Decode(&recordings); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return recordings, nil
}

// GetAllRecordings retrieves all recordings
func (s *SupabaseClient) GetAllRecordings(limit int) ([]RecordingMetadata, error) {
	url := fmt.Sprintf("%s/rest/v1/%s?order=recorded_at.desc&limit=%d", s.URL, s.TableName, limit)
	
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", s.APIKey)
	req.Header.Set("Authorization", "Bearer "+s.APIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("supabase error (status %d)", resp.StatusCode)
	}

	var recordings []RecordingMetadata
	if err := json.NewDecoder(resp.Body).Decode(&recordings); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return recordings, nil
}

// DeleteRecording deletes a recording by ID
func (s *SupabaseClient) DeleteRecording(id string) error {
	url := fmt.Sprintf("%s/rest/v1/%s?id=eq.%s", s.URL, s.TableName, id)
	
	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", s.APIKey)
	req.Header.Set("Authorization", "Bearer "+s.APIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("supabase error (status %d)", resp.StatusCode)
	}

	return nil
}
