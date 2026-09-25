# Image Upload Constraints - CivicPulse

## Summary

**Maximum File Size:** 5MB  
**Allowed Formats:** JPEG, JPG, PNG, WEBP  
**Enforcement:** Backend + Frontend  

---

## Backend Constraints

### Configuration File
**Location:** `/backend/config/cloudinary.js`

### Size Limit
```javascript
limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
}
```

### Allowed MIME Types
```javascript
const allowedTypes = [
    "image/jpeg",
    "image/jpg", 
    "image/png",
    "image/webp"
];
```

### Error Handling
**Location:** `/backend/routes/issueRoutes.js`

```javascript
const handleMulterError = (err, req, res, next) => {
    if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(400).json({
            message: "File too large. Maximum size is 5MB."
        });
    }
    if (err.message) {
        return res.status(400).json({
            message: err.message
        });
    }
    next();
};
```

---

## Frontend Validation

### Civic Issue Reporting
**Location:** `/frontend/src/pages/ReportIssue.jsx`

```javascript
const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
        if (file.size > 5 * 1024 * 1024) {
            setError('Image must be less than 5MB');
            return;
        }
        // Process file...
    }
};
```

**UI Message:**
```
PNG, JPG up to 5MB
```

### Department Issue Resolution
**Location:** `/frontend/src/pages/DepartmentIssueDetails.jsx`

```javascript
const handleEvidenceChange = (e) => {
    const file = e.target.files[0];
    if (file) {
        if (file.size > 5 * 1024 * 1024) {
            alert('File size must be less than 5MB');
            return;
        }
        if (!file.type.startsWith('image/')) {
            alert('Only image files are allowed');
            return;
        }
        // Process file...
    }
};
```

---

## Where Images are Uploaded

### 1. Civic Issue Reporting (Citizen)
- **Endpoint:** `POST /api/issues`
- **Field Name:** `image` (optional)
- **Purpose:** Evidence photo of the civic issue
- **Storage:** Cloudinary folder `civicpulse/issues`

### 2. Issue Resolution (Department)
- **Endpoint:** `PATCH /api/issues/:issueId/resolve`
- **Field Name:** `evidence` (required for resolution)
- **Purpose:** Photo proof that issue was resolved
- **Storage:** Cloudinary folder `civicpulse/issues`

---

## Constraint Enforcement Summary

| Check | Backend | Frontend | Error Message |
|-------|---------|----------|---------------|
| **File Size ≤ 5MB** | ✅ Multer | ✅ JavaScript | "File too large. Maximum size is 5MB" / "Image must be less than 5MB" |
| **Image MIME Type** | ✅ Multer | ✅ JavaScript | "Invalid file type. Only images are allowed" |
| **Allowed Formats** | ✅ JPEG, JPG, PNG, WEBP | ✅ Visual guide | "Only JPEG, PNG, and WEBP images are allowed" |

---

## Security Features

✅ **File Type Validation:** Only image MIME types accepted  
✅ **Size Limit:** Prevents large file uploads (DoS protection)  
✅ **Server-side Validation:** Backend validates regardless of frontend  
✅ **Cloudinary Storage:** Files stored securely in cloud (not on server disk)  
✅ **Memory Storage:** Multer uses memory buffer (no temp files on disk)  

---

## User Experience

### Success Flow
1. User selects image file
2. Frontend validates size < 5MB
3. Frontend validates file is an image
4. File preview shown
5. User submits form
6. Backend validates again
7. Image uploaded to Cloudinary
8. Cloudinary URL saved in database

### Error Flow (File Too Large)
1. User selects image > 5MB
2. **Frontend catches immediately:**
   - Shows error: "Image must be less than 5MB"
   - File is rejected before upload
3. User must select smaller file

### Error Flow (Wrong Format)
1. User selects non-image file (e.g., PDF)
2. **Frontend catches:**
   - Shows error: "Only image files are allowed"
3. User must select image file

### Fallback (Backend Validation)
If frontend validation is bypassed:
- **Backend validates:**
  - Returns 400 Bad Request
  - Error message: "File too large. Maximum size is 5MB."
- User sees error and must retry with smaller file

---

## Recommended Improvements (Future)

### Current Limitations
- No image dimension validation (width/height)
- No automatic image compression
- No progress bar for large uploads
- No client-side image preview optimization

### Possible Enhancements
1. **Image Compression:**
   - Use browser-based compression before upload
   - Reduce file size without quality loss
   - Libraries: `browser-image-compression`, `compressorjs`

2. **Dimension Limits:**
   - Validate max width/height (e.g., 4096x4096)
   - Prevent extremely large images

3. **Upload Progress:**
   - Show progress bar during upload
   - Better UX for slower connections

4. **Multiple Images:**
   - Allow multiple evidence photos
   - Useful for complex civic issues

5. **Image Optimization:**
   - Cloudinary transformations
   - Auto-format conversion
   - Lazy loading on frontend

---

## Testing Upload Constraints

### Test Case 1: Valid Image (< 5MB)
```bash
# Create test image (1MB)
convert -size 800x600 xc:blue test_valid.jpg

# Upload via API
curl -X POST http://localhost:4000/api/issues \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@test_valid.jpg" \
  -F "title=Test Issue" \
  -F "description=Test" \
  -F "category=INFRASTRUCTURE" \
  -F "location=Test Location"

# Expected: 201 Created
```

### Test Case 2: File Too Large (> 5MB)
```bash
# Create large image (10MB)
convert -size 3000x3000 xc:red test_large.jpg

# Upload via API
curl -X POST http://localhost:4000/api/issues \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@test_large.jpg" \
  -F "title=Test Issue" \
  -F "description=Test" \
  -F "category=INFRASTRUCTURE" \
  -F "location=Test Location"

# Expected: 400 Bad Request
# Message: "File too large. Maximum size is 5MB."
```

### Test Case 3: Invalid File Type
```bash
# Upload PDF file
curl -X POST http://localhost:4000/api/issues \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@document.pdf" \
  -F "title=Test Issue" \
  -F "description=Test" \
  -F "category=INFRASTRUCTURE" \
  -F "location=Test Location"

# Expected: 400 Bad Request
# Message: "Invalid file type. Only images are allowed."
```

---

## Browser Compatibility

### File Size Check (JavaScript)
✅ **All Modern Browsers:**
- Chrome, Firefox, Safari, Edge
- `file.size` property supported

### File Type Check (MIME)
✅ **All Modern Browsers:**
- `file.type` property supported
- Returns MIME type (e.g., "image/jpeg")

### File Upload (FormData)
✅ **All Modern Browsers:**
- `FormData` API supported
- `fetch()` with multipart/form-data

---

## Cloudinary Settings

### Upload Configuration
```javascript
cloudinary.uploader.upload_stream({
    folder: "civicpulse/issues",
    resource_type: "image",
    public_id: filename
})
```

### Storage Structure
```
civicpulse/
  └── issues/
      ├── issue_6789abc_1234567890123.jpg
      ├── issue_6789abc_1234567890124.jpg
      └── evidence_6789def_1234567890125.jpg
```

### Cloudinary Limits (Plan-dependent)
- Free Plan: 25 GB storage, 25 GB bandwidth/month
- Paid Plans: Higher limits available

---

## Summary Table

| Constraint | Value | Enforced By |
|------------|-------|-------------|
| **Max File Size** | 5MB | Backend (Multer) + Frontend (JS) |
| **Min File Size** | None (but must be valid image) | - |
| **Max Width** | Not limited | - |
| **Max Height** | Not limited | - |
| **Allowed Formats** | JPEG, JPG, PNG, WEBP | Backend (Multer) |
| **Blocked Formats** | GIF, BMP, TIFF, SVG, PDF, etc. | Backend (Multer) |
| **Max Files per Upload** | 1 | Multer: `upload.single()` |
| **Storage Backend** | Cloudinary | - |
| **Temp Storage** | Memory (Buffer) | Multer: `memoryStorage()` |

---

## FAQ

### Q: Why 5MB limit?
**A:** Balance between:
- Image quality (high-res photos need space)
- Upload speed (mobile networks)
- Server bandwidth (cost control)
- Cloudinary limits (free tier)

### Q: Can users upload larger images?
**A:** No, hard limit at 5MB. Users must:
- Resize image before upload
- Use image compression tools
- Take photos at lower resolution

### Q: What happens if image > 5MB?
**A:** 
1. Frontend rejects immediately (if validation works)
2. If bypassed, backend returns 400 Bad Request
3. User sees error message
4. Must select smaller file

### Q: Are GIF animations allowed?
**A:** No, GIF format is blocked. Only JPEG, JPG, PNG, WEBP.

### Q: Can users upload videos?
**A:** No, only image files accepted.

### Q: Is there a minimum size?
**A:** No explicit minimum, but file must be a valid image (at least a few KB).

---

## Conclusion

✅ **5MB maximum file size** enforced on both frontend and backend  
✅ **Image formats only:** JPEG, JPG, PNG, WEBP  
✅ **Secure validation** prevents malicious uploads  
✅ **Good user experience** with immediate feedback  
✅ **Cloud storage** via Cloudinary  

The constraints are reasonable for a civic engagement platform and provide good balance between quality and performance.

---

**END OF IMAGE UPLOAD CONSTRAINTS DOCUMENTATION**
