# 🎬 GoondVR Quality Settings Guide

## ✅ Current Configuration

Your GoondVR is configured for **MAXIMUM QUALITY**:

### **Recording Settings:**
- **Resolution**: Set to `0` or `2160` for auto/4K
- **Framerate**: Set to `0` or `60` for auto/60fps
- **Mode**: Automatically detects highest available quality

### **Processing Settings (Already Configured ✅):**
- **Finalization Mode**: Remux (fast, no quality loss)
- **Container**: MP4
- **Encoder**: libx264 (universal compatibility)
- **Quality (CRF)**: 18 (near-perfect quality)
- **Preset**: slow (best compression)

### **Upload & Storage (Already Configured ✅):**
- **GoFile Upload**: Enabled ✅
- **Delete After Upload**: Enabled ✅
- **Supabase**: Enabled ✅ (stores download links)

---

## 🔧 How to Set Channels to Highest Quality

### **Option 1: Via Web UI (Recommended)**

1. Go to: http://54.210.37.19:8080
2. Login with:
   - Username: `admin`
   - Password: `Basudevkr@123`

3. **For Each Existing Channel:**
   - Click on the channel
   - Click "Edit" or settings icon
   - Change **Resolution** to: `0` (auto - gets highest available)
   - Change **Framerate** to: `0` (auto - gets highest available)
   - Click "Save"

4. **For New Channels:**
   - Click "Add Channel"
   - Enter username
   - Select site (Chaturbate/Stripchat)
   - Set **Resolution**: `0` (for auto) or `2160` (for 4K)
   - Set **Framerate**: `0` (for auto) or `60` (for 60fps)
   - Click "Add"

---

## 📊 Resolution & Framerate Options

### **Resolution Values:**
- `0` = **Auto** (gets highest available - RECOMMENDED ✅)
- `2160` = 4K (3840x2160)
- `1440` = 2K (2560x1440)
- `1080` = Full HD (1920x1080)
- `720` = HD (1280x720)
- `480` = SD (854x480)

### **Framerate Values:**
- `0` = **Auto** (gets highest available - RECOMMENDED ✅)
- `60` = 60 fps (smooth)
- `30` = 30 fps (standard)
- `25` = 25 fps
- `24` = 24 fps (cinematic)

---

## 🎯 Recommended Settings for Maximum Quality

### **Best Practice:**
```
Resolution: 0 (auto)
Framerate: 0 (auto)
```

This will:
- ✅ Automatically detect and record at highest available quality
- ✅ Get 4K 60fps if the stream supports it
- ✅ Fall back to 1080p 60fps if 4K not available
- ✅ Fall back to lower quality if higher not available

### **Alternative (Explicit 4K 60fps):**
```
Resolution: 2160 (4K)
Framerate: 60
```

This will:
- ✅ Always try to get 4K 60fps
- ⚠️ May fail if stream doesn't support 4K
- ⚠️ Will fall back to next available quality

---

## 🔄 Complete Workflow (What Happens)

1. **Channel Goes Online**
   - GoondVR detects stream is live
   - Starts recording at highest available quality (up to 4K 60fps)

2. **Recording**
   - Records raw stream data
   - Saves to `/usr/src/app/videos/` directory

3. **Channel Goes Offline**
   - Recording stops
   - Finalization process begins

4. **Finalization (Automatic)**
   - Remuxes to MP4 format
   - Uses CRF 18 (near-perfect quality)
   - Uses "slow" preset (best compression)

5. **Upload to GoFile (Automatic)**
   - Uploads finished MP4 to GoFile
   - Gets download link

6. **Save to Supabase (Automatic)**
   - Stores recording metadata
   - Stores GoFile download link
   - Stores recording details (date, time, duration, etc.)

7. **Delete Local File (Automatic)**
   - Removes MP4 from EC2 storage
   - Frees up disk space

---

## 💾 Storage Considerations

### **With 4K 60fps Recording:**
- **Bitrate**: ~20-50 Mbps
- **Storage**: ~9-22 GB per hour
- **30 GB disk**: Can hold ~1-3 hours of 4K recording

### **Recommendations:**
- ✅ Keep "Delete After Upload" enabled
- ✅ Monitor disk space: `df -h`
- ✅ GoFile stores unlimited (free tier)
- ✅ Supabase stores links (not videos)

---

## 🔍 How to Verify Settings

### **Check Current Channels:**
```bash
ssh -i "aws-key.pem" ubuntu@54.210.37.19 "docker exec goondvr cat /usr/src/app/conf/channels.json"
```

Look for:
```json
{
  "username": "channelname",
  "resolution": 0,    // 0 = auto (highest)
  "framerate": 0      // 0 = auto (highest)
}
```

### **Check Settings:**
```bash
ssh -i "aws-key.pem" ubuntu@54.210.37.19 "docker exec goondvr cat /usr/src/app/conf/settings.json"
```

Look for:
```json
{
  "recording_finalization_quality": "18",  // Near-perfect
  "gofile_delete_after_upload": true,      // Auto-delete
  "supabase_enabled": true                 // Save links
}
```

---

## 📝 Current Channels

You have 3 channels configured:
1. **jasonsweets** (Chaturbate) - Currently: 1080p 60fps
2. **aya__hitakayama** (Chaturbate) - Currently: 1080p 60fps
3. **danyandannarearden** (Chaturbate) - Currently: 1080p 60fps

**To upgrade to auto/4K:**
- Edit each channel in the web UI
- Change resolution to `0`
- Change framerate to `0`

---

## 🆘 Troubleshooting

### **Recording Quality Lower Than Expected:**
- Check if stream actually broadcasts in 4K
- Most Chaturbate streams are 1080p max
- Use `0` for auto-detection

### **Large Files Filling Disk:**
- Verify "Delete After Upload" is enabled
- Check GoFile uploads are working
- Monitor: `df -h`

### **Upload Failures:**
- Check GoFile API token is valid
- Check internet connectivity
- View logs: `docker compose logs -f`

---

## ✅ Summary

Your system is configured for:
- ✅ **Highest quality recording** (up to 4K 60fps if available)
- ✅ **Near-perfect encoding** (CRF 18)
- ✅ **Automatic upload** to GoFile
- ✅ **Link storage** in Supabase
- ✅ **Automatic cleanup** (delete after upload)

**Just update your channels to use `resolution: 0` and `framerate: 0` in the web UI!**

---

## 🌐 Access Your System

**Web UI:** http://54.210.37.19:8080
**Username:** admin
**Password:** Basudevkr@123

**SSH:** 
```bash
ssh -i "C:\Users\hp\Downloads\New folder (2)\aws-key.pem" ubuntu@54.210.37.19
```

---

**🎉 You're all set for maximum quality recordings!**
