package uploader

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

// GoFileUploader handles uploading files to GoFile.io
type GoFileUploader struct {
	APIToken string
	FolderID string
	client   *http.Client
}

// GoFileServerResponse represents the response from getting the best server
type GoFileServerResponse struct {
	Status string `json:"status"`
	Data   struct {
		Server string `json:"server"`
	} `json:"data"`
}

// GoFileUploadResponse represents the response from uploading a file
type GoFileUploadResponse struct {
	Status string `json:"status"`
	Data   struct {
		DownloadPage string `json:"downloadPage"`
		Code         string `json:"code"`
		ParentFolder string `json:"parentFolder"`
		FileID       string `json:"fileId"`
		FileName     string `json:"fileName"`
		MD5          string `json:"md5"`
	} `json:"data"`
}

// NewGoFileUploader creates a new GoFile uploader instance
func NewGoFileUploader(apiToken, folderID string) *GoFileUploader {
	return &GoFileUploader{
		APIToken: apiToken,
		FolderID: folderID,
		client: &http.Client{
			Timeout: 30 * time.Minute, // Long timeout for large file uploads
		},
	}
}

// GetBestServer retrieves the best server to upload to
func (g *GoFileUploader) GetBestServer() (string, error) {
	resp, err := g.client.Get("https://api.gofile.io/servers")
	if err != nil {
		return "", fmt.Errorf("failed to get server: %w", err)
	}
	defer resp.Body.Close()

	var serverResp GoFileServerResponse
	if err := json.NewDecoder(resp.Body).Decode(&serverResp); err != nil {
		return "", fmt.Errorf("failed to decode server response: %w", err)
	}

	if serverResp.Status != "ok" {
		return "", fmt.Errorf("server response status: %s", serverResp.Status)
	}

	return serverResp.Data.Server, nil
}

// UploadFile uploads a file to GoFile
func (g *GoFileUploader) UploadFile(filePath string) (*GoFileUploadResponse, error) {
	// Get the best server
	server, err := g.GetBestServer()
	if err != nil {
		return nil, fmt.Errorf("failed to get best server: %w", err)
	}

	// Open the file
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	// Get file info
	fileInfo, err := file.Stat()
	if err != nil {
		return nil, fmt.Errorf("failed to get file info: %w", err)
	}

	// Create multipart form
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// Add file
	part, err := writer.CreateFormFile("file", filepath.Base(filePath))
	if err != nil {
		return nil, fmt.Errorf("failed to create form file: %w", err)
	}

	if _, err := io.Copy(part, file); err != nil {
		return nil, fmt.Errorf("failed to copy file: %w", err)
	}

	// Add folder ID if provided
	if g.FolderID != "" {
		if err := writer.WriteField("folderId", g.FolderID); err != nil {
			return nil, fmt.Errorf("failed to write folder field: %w", err)
		}
	}

	if err := writer.Close(); err != nil {
		return nil, fmt.Errorf("failed to close writer: %w", err)
	}

	// Create request
	uploadURL := fmt.Sprintf("https://%s.gofile.io/contents/uploadfile", server)
	req, err := http.NewRequest("POST", uploadURL, body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", writer.FormDataContentType())
	if g.APIToken != "" {
		req.Header.Set("Authorization", "Bearer "+g.APIToken)
	}

	// Log upload start
	fmt.Printf("Uploading %s (%.2f MB) to GoFile...\n", filepath.Base(filePath), float64(fileInfo.Size())/1024/1024)

	// Send request
	resp, err := g.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to upload file: %w", err)
	}
	defer resp.Body.Close()

	// Parse response
	var uploadResp GoFileUploadResponse
	if err := json.NewDecoder(resp.Body).Decode(&uploadResp); err != nil {
		return nil, fmt.Errorf("failed to decode upload response: %w", err)
	}

	if uploadResp.Status != "ok" {
		return nil, fmt.Errorf("upload response status: %s", uploadResp.Status)
	}

	return &uploadResp, nil
}

// UploadAndDelete uploads a file and deletes it locally on success
func (g *GoFileUploader) UploadAndDelete(filePath string) error {
	resp, err := g.UploadFile(filePath)
	if err != nil {
		return fmt.Errorf("upload failed: %w", err)
	}

	fmt.Printf("✓ Uploaded successfully: %s\n", resp.Data.DownloadPage)
	fmt.Printf("  File ID: %s\n", resp.Data.FileID)

	// Delete local file after successful upload
	if err := os.Remove(filePath); err != nil {
		return fmt.Errorf("failed to delete local file: %w", err)
	}

	fmt.Printf("✓ Deleted local file: %s\n", filePath)
	return nil
}
