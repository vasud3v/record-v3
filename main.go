package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/HeapOfChaos/goondvr/config"
	"github.com/HeapOfChaos/goondvr/entity"
	"github.com/HeapOfChaos/goondvr/manager"
	"github.com/HeapOfChaos/goondvr/router"
	"github.com/HeapOfChaos/goondvr/server"
	"github.com/urfave/cli/v2"
)

const logo = `
 ██████╗  ██████╗  ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██████╗
██╔════╝ ██╔═══██╗██╔═══██╗████╗  ██║██╔══██╗██║   ██║██╔══██╗
██║  ███╗██║   ██║██║   ██║██╔██╗ ██║██║  ██║██║   ██║██████╔╝
██║   ██║██║   ██║██║   ██║██║╚██╗██║██║  ██║╚██╗ ██╔╝██╔══██╗
╚██████╔╝╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝ ╚████╔╝ ██║  ██║
 ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝   ╚═══╝  ╚═╝  ╚═╝`

func main() {
	app := &cli.App{
		Name:    "goondvr",
		Version: "3.1.1",
		Usage:   "Record your favorite streams automatically. 😎🫵",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:    "username",
				Aliases: []string{"u"},
				Usage:   "The username of the channel to record",
				Value:   "",
			},
			&cli.StringFlag{
				Name:  "site",
				Usage: "Site to record from: chaturbate or stripchat",
				Value: "chaturbate",
			},
			&cli.StringFlag{
				Name:  "admin-username",
				Usage: "Username for web authentication (optional)",
				Value: "",
				EnvVars: []string{"ADMIN_USERNAME"},
			},
			&cli.StringFlag{
				Name:  "admin-password",
				Usage: "Password for web authentication (optional)",
				Value: "",
				EnvVars: []string{"ADMIN_PASSWORD"},
			},
			&cli.IntFlag{
				Name:  "framerate",
				Usage: "Desired framerate (FPS). Use 0 for auto (highest available)",
				Value: 0, // Auto-detect highest framerate
			},
			&cli.IntFlag{
				Name:  "resolution",
				Usage: "Desired resolution (e.g., 1080 for 1080p, 2160 for 4K). Use 0 for auto (highest available)",
				Value: 0, // Auto-detect highest resolution
			},
			&cli.StringFlag{
				Name:  "pattern",
				Usage: "Template for naming recorded videos",
				Value: "videos/{{if ne .Site \"chaturbate\"}}{{.Site}}/{{end}}{{.Username}}_{{.Year}}-{{.Month}}-{{.Day}}_{{.Hour}}-{{.Minute}}-{{.Second}}{{if .Sequence}}_{{.Sequence}}{{end}}",
			},
			&cli.IntFlag{
				Name:  "max-duration",
				Usage: "Split video into segments every N minutes ('0' to disable)",
				Value: 0,
			},
			&cli.IntFlag{
				Name:  "max-filesize",
				Usage: "Split video into segments every N MB ('0' to disable)",
				Value: 0,
			},
			&cli.StringFlag{
				Name:    "port",
				Aliases: []string{"p"},
				Usage:   "Port for the web interface and API",
				Value:   "8080",
			},
			&cli.StringFlag{
				Name:    "bind",
				Aliases: []string{"b"},
				Usage:   "Bind address for the web interface (use 0.0.0.0 for all interfaces)",
				Value:   "0.0.0.0",
				EnvVars: []string{"BIND_ADDRESS"},
			},
			&cli.IntFlag{
				Name:  "interval",
				Usage: "Check if the channel is online every N minutes",
				Value: 1,
			},
			&cli.StringFlag{
				Name:  "cookies",
				Usage: "Cookies to use in the request (format: key=value; key2=value2)",
				Value: "",
				EnvVars: []string{"CHATURBATE_COOKIES"},
			},
			&cli.StringFlag{
				Name:  "user-agent",
				Usage: "Custom User-Agent for the request",
				Value: "",
				EnvVars: []string{"USER_AGENT"},
			},
			&cli.StringFlag{
				Name:  "domain",
				Usage: "Chaturbate domain to use",
				Value: "https://chaturbate.com/",
			},
			&cli.StringFlag{
				Name:  "completed-dir",
				Usage: "Directory to move fully closed recordings into (default: <recording dir>/completed)",
				Value: "",
			},
			&cli.StringFlag{
				Name:  "finalize-mode",
				Usage: "Post-process closed recordings: none, remux, or transcode",
				Value: "remux", // Changed to remux by default
			},
			&cli.StringFlag{
				Name:  "ffmpeg-encoder",
				Usage: "FFmpeg video encoder for transcode mode (e.g. libx264, libx265, h264_nvenc)",
				Value: "libx264",
			},
			&cli.StringFlag{
				Name:  "ffmpeg-container",
				Usage: "FFmpeg output container for remux/transcode mode (mp4 or mkv)",
				Value: "mp4",
			},
			&cli.IntFlag{
				Name:  "ffmpeg-quality",
				Usage: "FFmpeg quality value (CRF for software encoders, CQ for many hardware encoders)",
				Value: 18, // Changed to 18 for near-perfect quality
			},
			&cli.StringFlag{
				Name:  "ffmpeg-preset",
				Usage: "FFmpeg preset for transcode mode",
				Value: "slow", // Changed to slow for better compression
			},
			&cli.BoolFlag{
				Name:  "debug",
				Usage: "Write full HTML response to a temp file when stream detection fails",
				Value: false,
			},
			&cli.StringFlag{
				Name:  "stripchat-pdkey",
				Usage: "Stripchat MOUFLON v2 decryption key (auto-extracted if omitted)",
				Value: "",
			},
			&cli.BoolFlag{
				Name:   "gofile-enabled",
				Usage:  "Enable automatic upload to GoFile",
				Value:  true, // Changed to true by default
				EnvVars: []string{"GOFILE_ENABLED"},
			},
			&cli.StringFlag{
				Name:   "gofile-api-token",
				Usage:  "GoFile API token for uploads",
				Value:  "",
				EnvVars: []string{"GOFILE_API_TOKEN"},
			},
			&cli.StringFlag{
				Name:   "gofile-folder-id",
				Usage:  "GoFile folder ID to upload to (optional)",
				Value:  "",
				EnvVars: []string{"GOFILE_FOLDER_ID"},
			},
			&cli.BoolFlag{
				Name:   "gofile-delete-after-upload",
				Usage:  "Delete local files after successful upload to GoFile",
				Value:  true, // Changed to true by default
				EnvVars: []string{"GOFILE_DELETE_AFTER_UPLOAD"},
			},
			&cli.BoolFlag{
				Name:   "supabase-enabled",
				Usage:  "Enable storing recording metadata in Supabase",
				Value:  true, // Changed to true by default
				EnvVars: []string{"SUPABASE_ENABLED"},
			},
			&cli.StringFlag{
				Name:   "supabase-url",
				Usage:  "Supabase project URL",
				Value:  "",
				EnvVars: []string{"SUPABASE_URL"},
			},
			&cli.StringFlag{
				Name:   "supabase-api-key",
				Usage:  "Supabase API key (anon or service role)",
				Value:  "",
				EnvVars: []string{"SUPABASE_API_KEY"},
			},
			&cli.StringFlag{
				Name:   "supabase-table-name",
				Usage:  "Supabase table name for recordings",
				Value:  "recordings",
				EnvVars: []string{"SUPABASE_TABLE_NAME"},
			},
		},
		Action: start,
	}
	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

func start(c *cli.Context) error {
	fmt.Println(logo)

	var err error
	server.Config, err = config.New(c)
	if err != nil {
		return fmt.Errorf("new config: %w", err)
	}
	if err := manager.LoadSettings(); err != nil {
		return fmt.Errorf("load settings: %w", err)
	}
	server.Manager, err = manager.New()
	if err != nil {
		return fmt.Errorf("new manager: %w", err)
	}

	// Handle SIGINT / SIGTERM so in-progress recordings are cleanly closed and
	// seek-indexed before the process exits.
	go func() {
		sigCh := make(chan os.Signal, 1)
		signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
		<-sigCh
		fmt.Println("Shutting down, waiting for recordings to close and finalize...")
		server.Manager.Shutdown()
		os.Exit(0)
	}()

	// init web interface if username is not provided
	if server.Config.Username == "" {
		port := c.String("port")
		bind := c.String("bind")
		addr := bind + ":" + port
		
		fmt.Printf("👋 Web UI starting on %s\n", addr)
		if bind == "0.0.0.0" || bind == "" {
			fmt.Printf("   Local: http://localhost:%s\n", port)
			fmt.Printf("   Network: http://0.0.0.0:%s\n\n\n", port)
		} else {
			fmt.Printf("   Access: http://%s\n\n\n", addr)
		}

		if err := server.Manager.LoadConfig(); err != nil {
			return fmt.Errorf("load config: %w", err)
		}

		return router.SetupRouter().Run(addr)
	}

	// else create a channel with the provided username
	if err := server.Manager.CreateChannel(&entity.ChannelConfig{
		IsPaused:    false,
		Username:    c.String("username"),
		Site:        server.Config.Site,
		Framerate:   c.Int("framerate"),
		Resolution:  c.Int("resolution"),
		Pattern:     c.String("pattern"),
		MaxDuration: c.Int("max-duration"),
		MaxFilesize: c.Int("max-filesize"),
	}, false); err != nil {
		return fmt.Errorf("create channel: %w", err)
	}

	// block forever
	select {}
}
