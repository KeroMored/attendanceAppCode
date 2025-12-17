# Offline Attendance System Implementation

## Overview

This implementation adds offline functionality to the attendance system, allowing users to record attendance even when there's no internet connection. The data is stored locally and automatically synced when connectivity is restored.

## New Files Created

### 1. `lib/meeting/online_or_offline.dart`

- **Purpose**: Selection page that allows users to choose between online or offline attendance recording
- **Features**:
  - Responsive design for all screen sizes
  - Two main buttons: "التسجيل أونلاين" and "التسجيل أوفلاين"
  - Clear visual indication of each mode's requirements
  - Information card explaining offline functionality

### 2. `lib/meeting/meeting_details_offline.dart`

- **Purpose**: Offline version of the meeting details page for recording attendance
- **Features**:
  - QR code scanning functionality (works offline)
  - Local data storage using SharedPreferences
  - Automatic sync when connectivity is restored
  - Periodic sync checks every 30 seconds
  - Visual indicators for pending sync count
  - Manual sync button
  - Offline search delegate (limited functionality)
  - Status indicator showing offline mode

### 3. `lib/helper/offline_manager.dart`

- **Purpose**: Utility class for managing offline data operations
- **Features**:
  - Save attendance records offline
  - Retrieve offline attendance data
  - Clear offline data after successful sync
  - Check connectivity status
  - Track sync timestamps
  - Get pending sync counts

## Modified Files

### 1. `lib/meeting/display_meetings.dart`

- **Changes**: Updated navigation to use `OnlineOrOffline` page instead of direct `MeetingDetails`
- **Impact**: All meeting selections now go through the mode selection page

## Key Features

### Offline Data Storage

- Uses SharedPreferences to store attendance records locally
- Data format: `offline_attendance_{meetingId}` containing array of student IDs
- Persistent storage that survives app restarts

### Automatic Synchronization

- Periodic connectivity checks every 30 seconds
- Automatic sync when connectivity is restored
- Visual feedback during sync operations
- Success/failure notifications

### User Experience

- Clear visual indicators for offline mode
- Pending sync count displayed in app bar
- Manual sync button when data is pending
- Responsive design for all screen sizes
- Arabic language support throughout

### Data Integrity

- Prevents duplicate attendance records
- Validates student class membership before sync
- Error handling for sync failures
- Maintains data consistency between offline and online modes

## Usage Flow

1. **Select Meeting**: User taps on a meeting from the meetings list
2. **Choose Mode**: OnlineOrOffline page appears with two options
3. **Online Mode**: Direct connection to MeetingDetails (existing functionality)
4. **Offline Mode**:
   - Opens MeetingDetailsOffline page
   - QR scanning saves data locally
   - Automatic sync attempts every 30 seconds
   - Manual sync available via button
   - Visual indicators show pending sync status

## Technical Implementation

### Data Structure
```json
{
  "offline_attendance_meetingId1": ["studentId1", "studentId2"],
  "offline_attendance_meetingId2": ["studentId3", "studentId4"],
  "last_sync_timestamp": 1640995200000
}
```

### Sync Process

1. Check connectivity using connectivity_plus package
2. Retrieve all offline attendance data
3. For each meeting:
   - Get student data and validate class membership
   - Update meeting attendance list
   - Update student counters and coins
4. Clear local data after successful sync
5. Update last sync timestamp

### Error Handling

- Network connectivity issues
- Invalid student data
- Appwrite service errors
- Local storage failures
- Sync conflicts

## Dependencies Used

- `shared_preferences`: Local data storage
- `connectivity_plus`: Network connectivity checking
- `mobile_scanner`: QR code scanning (works offline)
- Existing dependencies from the original project

## Benefits

1. **Reliability**: Works in areas with poor internet connectivity
2. **User Experience**: No frustration from connection failures
3. **Data Integrity**: Ensures no attendance records are lost
4. **Automatic Recovery**: Seamless sync when connectivity returns
5. **Visual Feedback**: Clear indicators of system status
6. **Flexibility**: Users can choose mode based on current conditions

## Future Enhancements

1. **Conflict Resolution**: Handle cases where the same student is marked present both online and offline
2. **Bulk Export**: Export offline data for manual processing
3. **Sync History**: Show detailed sync logs
4. **Smart Sync**: Prioritize recent data for sync
5. **Background Sync**: Continue sync even when app is backgrounded
